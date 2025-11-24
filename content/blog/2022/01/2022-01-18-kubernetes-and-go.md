+++
title = "Kubernetes loves Go"
summary = "Building a custom Kubernetes controller in Go."
tags = ["programming", "go", "kubernetes"]
+++

I've been working with Kubernetes and Go for years now. There's something deeply satisfying about this combination. Kubernetes gives you this incredibly powerful orchestration platform, and Go provides the perfect language to extend it. The two were made for each other, and nowhere is this more apparent than when you need a custom controller to solve a particularly gnarly scaling problem.

<br>

## One Pod Per User

Our system had an unusual but deliberate architecture: one pod per user. Each user would "reserve" a pod for their exclusive use during a session. Think of it like a personalized sandbox environment, isolated, secure, and fully theirs.

There were a lot of challenges. These pods weren't instant. Startup time was significant enough that we couldn't just spin them up on-demand. Users expect immediate access, so we needed a pool of pre-warmed pods sitting ready to go.

<br>

## Why Standard Scaling Wasn't Enough

My first attempt was using Kubernetes' Horizontal Pod Autoscaler with custom metrics from Prometheus. After all, that's what it's for, right? But as time went on it became clear that HPA wasn't sophisticated enough for what we needed.

Our scaling logic had to account for:

1. **Time-based patterns**: We needed different pool sizes at 2 PM versus 2 AM. User demand followed predictable daily rhythms.

2. **Velocity and acceleration**: A steady increase in reservations required different handling than a sudden spike. If someone tweeted a link to our service and we got a flood of new users, we needed to scale *fast*.

3. **Smart pool management**: The pool couldn't just be "any X pods." We needed to track which pods were reserved, which were ready, and which were warming up.

Standard metrics-based scaling gave us crude reactive behavior. We needed something predictive and loaded with business logic.

<br>

## The Custom Controller

This is where Go and Kubernetes really shine together. I decided to build a custom controller (technically an operator, since it manages a custom resource) using the excellent `controller-runtime` library.

None of this is the actual code, but here's a simplified version.

<br>

### The Custom Resource Definition

I wanted it to be cute, so I defined a CRD to represent our pod pool:

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: podpools.scaling.example.com
spec:
  group: scaling.example.com
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                minPoolSize:
                  type: integer
                  minimum: 0
                maxPoolSize:
                  type: integer
                  minimum: 1
                targetReadyPods:
                  type: integer
                  minimum: 0
                scaleUpVelocityThreshold:
                  type: number
                scaleUpAccelerationThreshold:
                  type: number
                timeBasedScaling:
                  type: array
                  items:
                    type: object
                    properties:
                      hourStart:
                        type: integer
                      hourEnd:
                        type: integer
                      targetPoolSize:
                        type: integer
                podTemplate:
                  type: object
                  x-kubernetes-preserve-unknown-fields: true
            status:
              type: object
              properties:
                readyPods:
                  type: integer
                reservedPods:
                  type: integer
                warmingPods:
                  type: integer
                currentVelocity:
                  type: number
                currentAcceleration:
                  type: number
                lastScaleTime:
                  type: string
                  format: date-time
  scope: Namespaced
  names:
    plural: podpools
    singular: podpool
    kind: PodPool
    shortNames:
    - pp
```

This CRD let us declare a `PodPool` resource with all the knobs I needed: time-based scaling windows, velocity thresholds, and the pod template to use.

<br>

### The Controller Logic

The controller's reconciliation loop is the brain of the operation. Here's the core logic I implemented in Go:

```go
func (r *PodPoolReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {

    // find the PodPool
    podPool := &scalingv1.PodPool{}
    if err := r.Get(ctx, req.NamespacedName, podPool); err != nil {
        return ctrl.Result{}, client.IgnoreNotFound(err)
    }

    // list all pods managed by this pool
    pods := &corev1.PodList{}
    if err := r.List(ctx, pods, 
        client.InNamespace(req.Namespace),
        client.MatchingLabels{"pool": podPool.Name}); err != nil {
        return ctrl.Result{}, err
    }

    // pods by state
    ready, reserved, warming := r.categorizePods(pods.Items)

    // calculate reservation velocity and acceleration
    velocity, acceleration := r.calculateMetrics(podPool, len(reserved))

    // determine target pool size based on time of day
    targetSize := r.getTimeBasedTarget(podPool)

    // check for spike conditions
    if velocity > podPool.Spec.ScaleUpVelocityThreshold || 
       acceleration > podPool.Spec.ScaleUpAccelerationThreshold {
        targetSize = r.calculateSpikeTarget(targetSize, velocity, acceleration)
    }

    // scale the pool
    currentTotal := len(ready) + len(warming)
    if currentTotal < targetSize {
        r.scaleUp(ctx, podPool, targetSize-currentTotal)
    } else if currentTotal > targetSize && len(ready) > podPool.Spec.TargetReadyPods {
        r.scaleDown(ctx, podPool, ready[podPool.Spec.TargetReadyPods:])
    }

    // update state
    podPool.Status.ReadyPods = len(ready)
    podPool.Status.ReservedPods = len(reserved)
    podPool.Status.WarmingPods = len(warming)
    podPool.Status.CurrentVelocity = velocity
    podPool.Status.CurrentAcceleration = acceleration

    return ctrl.Result{RequeueAfter: 10 * time.Second}, r.Status().Update(ctx, podPool)
}
```

The beauty of this approach is that everything is declarative. I could define different scaling behaviors for different environments just by creating different `PodPool` resources.

<br>

### Measuring Velocity and Acceleration

The most interesting part was tracking reservation velocity and acceleration. I kept a sliding window of reservation timestamps in the controller's memory (later moved to the PodPool status for persistence):

```go
func (r *PodPoolReconciler) calculateMetrics(podPool *scalingv1.PodPool, currentReserved int) (float64, float64) {
    now := time.Now()

    // reservation history from status or cache
    history := r.getReservationHistory(podPool)

    // add current count
    history = append(history, ReservationDataPoint{
        Timestamp: now,
        Count: currentReserved,
    })

    // keep only last 5 minutes
    cutoff := now.Add(-5 * time.Minute)
    history = filterAfter(history, cutoff)

    // calculate velocity (reservations per minute)
    velocity := 0.0
    if len(history) >= 2 {
        deltaCount := history[len(history)-1].Count - history[0].Count
        deltaTime := history[len(history)-1].Timestamp.Sub(history[0].Timestamp).Minutes()
        velocity = float64(deltaCount) / deltaTime
    }

    // calculate acceleration (change in velocity)
    acceleration := 0.0
    if len(history) >= 3 {
        midpoint := len(history) / 2
        recentVelocity := calculateVelocityBetween(history[midpoint:])
        olderVelocity := calculateVelocityBetween(history[:midpoint])
        acceleration = recentVelocity - olderVelocity
    }

    return velocity, acceleration
}
```

This gave us real-time awareness of not just *how many* reservations were happening, but *how fast* the rate was changing. When acceleration spiked, we knew something unusual was happening and could preemptively scale.

<br>

## The Results

The controller worked beautifully. During normal hours, the pool would smoothly adjust based on our time-based configuration. During the night, we'd have just enough pods to handle occasional use. During peak hours, the pool would be pre-scaled.

But the real magic happened during spikes. When (hypothetically) some CEO accidentally tweeted a direct link to our service, the controller would detect the acceleration in reservations and immediately start scaling up. The pool would stay ahead of demand.

<br>

## Why I Love This Stack

This project exemplified everything I love about Kubernetes and Go together. Kubernetes provides this amazing extension mechanism through CRDs and controllers. It doesn't try to solve every problem. Instead, it gives you the tools to solve your own problems in a native, first-class way.

Go makes building these controllers almost effortless. The `controller-runtime` library handles all the boilerplate of watching resources, managing work queues, and handling retries. The type safety catches bugs at compile time. The standard library has everything you need. And the resulting binary is a single executable that's trivial to containerize and deploy. This is why I love Go.

<br>

I could have built a separate service that called the Kubernetes API to manage pods, but making it a proper operator meant it integrated seamlessly with the rest of our Kubernetes infrastructure. We could use `kubectl` to inspect pool status, GitOps to manage pool configurations, and RBAC to control access.

<br>

If you're working with Kubernetes and facing a scaling problem that doesn't fit the standard tools, don't be afraid to build a custom controller. With Go and `controller-runtime`, it's easier than you might think, and the results can be truly powerful.
