+++
title = "Introducing Continuum: A Pragmatic Solution to High-Cardinality Time Series Analysis"
summary = "A Java library that efficiently handles both traditional time series and high-cardinality time-key-value data using RocksDB."
tags = ["programming", "java", "data"]
+++

I'm excited to share a project I've been working on that solves a problem many engineers at growing startups face: massive amounts of streaming data to analyze, but the "right" solutions are prohibitively expensive. So I built something different.

<br>

## The Problem: Video Streaming at Scale

I work at a video streaming company (CDN accelerator) that delivers HLS chunks to viewers across the globe. Every single chunk we deliver gives us an opportunity to measure Quality of Experience (QoE) on the server side. This is incredibly valuable data:
- buffer events
- bitrate
- time-to-first-frame
- watch time 

All segmented by `network`, `device`, `location`, etc, etc, etc. 

But it comes with a challenge: volume.

<br>

We need to answer two fundamentally different types of questions:

<br>

1. **Traditional time-series queries**: What's our average bitrate across all users in the last hour? How many buffer events are occurring in North America right now?

<br>

2. **Session-level analysis**: What is *this specific user's* experience during *their particular viewing session*? Are they experiencing buffering? What's their bitrate progression over time?

<br>


The second type of query is what I call "time-key-value" data - high cardinality time series where each unique session ID creates its own timeline of metrics. This was the thing no existing solution solved well.

<br>

## The Expensive Solution We Can't Afford

Yes, I know Flink can handle this. Kafka and Spark can definitely solve this problem. But here's the thing: we're a startup at an early stage. Setting up and maintaining a distributed stream processing infrastructure would be massive overkill. We need something that works *now*, that one person can manage, and that won't eat all of our money.

<br>

## Enter Continuum

I've created Continuum as a JVM library that handles both traditional time series and time-key-value data efficiently. The core insight is simple: use the right tool for the job, and don't reinvent what already works.

<br>

**Check it out:**
- [Documentation](https://continuum.zackbartel.com/)
- [GitHub Repository](https://github.com/zackb/continuum)
- [The Pitch Deck](https://continuum.zackbartel.com/img/Continuum.pdf) (yes, I made a quirky presentation to pitch this internally)

<br>

```   
// open continuum
Continuum continuum = continuum().open()

// create an atom (measurement)
Atom atom = continuum.atom()
                .name('temp')
                .particles(city:'lax', state:'ca', country:'us')
                .value(99.5)
                .build()

continuum.write(atom)
```

```
// scan continuum and get a slice of the atoms
Slice slice =
    continuum.slice(
        scan('temp')                            // temperature series
            .function(Function.AVG)             // average temperature
            .particles(country: 'us')           // where country = us
            .group('state', 'city')             // group by state, city
            .end(Interval.valueOf('10d'))       // last 10 days of atoms
            .interval(Interval.valueOf('1d'))   // in 1 day intervals
            .build())

Values values = slice.values()                  // {min,max,count,sum,value}
List groups = slice.slices()                    // {ca:values,lax:values}

continuum.close()
```

### The Foundation: RocksDB

I want to emphasize how incredible RocksDB is. Seriously. It's a log-structured-merge (LSM) tree database that uses memory-mapped files and handles massive write throughput beautifully. Facebook built it via forking LevelDB, and it's battle-tested at enormous scale. Rather than building my own storage engine, I leverage RocksDB (LevelDB and BerkeleyDB as alternatives).

This is a pattern I wish more engineers embraced: **reuse existing technology**. RocksDB has already solved the hard problems of durable, high-performance key-value storage. I just needed right abstraction on top of it and find the correct key design for both of these use cases.

<br>

## Two Schema Designs for Two Different Problems

Continuum employs two specialized approaches:

<br>

### 1. Time Series Data
For traditional metrics with a small number of unique series but massive data volume (think millions to trillions of data points):
- Infinite storage using retention policies and downsampling
- Inspired by RRDTool, Whisper
- Perfect for: Performance metrics, CPU measurements, temperature readings over time

<br>

### 2. Time-Key-Value Data
For high cardinality scenarios with a large number of unique keys but smaller amounts of data per key:
- Aggregate events into buckets by unique identifiers (session ID, user ID)
- Age out over time with TTL policies
- Perfect for: Real-time analytics events grouped by session or user

This second pattern is the real innovation here. It's what lets us analyze individual user sessions without building a massive distributed system.

<br>

## The Architecture

<br>

Continuum is designed to be pragmatic and scalable:

<br>

**Data Tiers:**
- **Fast data**: Hot, open sets of newest data for real-time queries
- **Slow data**: Rolling window of data archived to cold storage (S3, Hadoop, NAS)

**Scaling Options:**
- Add disks vertically
- Cold online backup (backup/restore)
- Hot online backup (read-only replication)
- Application-level sharding by key or time
- Clustering with master-master replication

**Features:**
- REST interface for easy integration
- Streaming backup/restore
- Streaming replication (master/slave and master/master)
- Time-to-live (TTL) policies
- Downsampling for efficient disk usage

## Getting Started

The library is available via Maven:

```xml
<dependency>
    <groupId>continuum</groupId>
    <artifactId>core</artifactId>
    <version>0.+</version>
</dependency>
```

Or build from source:
```bash
make
# or
./gradlew install
```

## Why This Matters

Not every problem needs Kafka. Not every startup needs Flink on day one. Sometimes the best solution is the one you can ship this week, maintain yourself, and that solves 95% of your needs at 5% of the cost.

<br>

Continuum represents a philosophy: **leverage proven technologies, build focused abstractions, and solve the problem you actually have** - not the problem you might have if you were Netflix.

<br>

If you're dealing with high-cardinality time series data and don't want to stand up a distributed stream processing cluster, give Continuum a look. 

<br>

And if you're curious about the pitch that convinced my company to let me do it, check out [the presentation](https://continuum.zackbartel.com/img/Continuum.pdf) - I promise it's... unique.

<br>

---

*Continuum is open source and available on [GitHub](https://github.com/zackb/continuum). Contributions welcome!*
