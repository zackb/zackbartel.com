+++
title = "C++ is Great (again)!"
summary = "The king of programming languages has reclaimed its throne."
tags = ["programming", "c++"]
+++

### [C](https://en.wikipedia.org/wiki/C_(programming_language)) is my favorite programming language.

<br>

It always has been and probably always will be. It allowed me to build cool stuff at a young age, create iOS and Mac software (via Objective-C), contribute to the Linux kernel, and work on embedded systems on airplanes.

<br>

When I first learned C++ in college, it was great. It was like having a super-charged version of C. Classes, inheritance, and polymorphism, it felt modern and powerful.

<br>

I last used C++ heavily around 2010. At that time the [Template Metapocalypse](https://learncodethehardway.com/blog/31-c-plus-plus-is-an-absolute-blast#the-c-template-metapocalypse) was in full swing. That experience made me not like programming.

<br>

I was tired of dealing with the complexities. The syntax was verbose, error messages unusable, build systems a nightmare, and the community divided over best practices. I moved on to other languages: Go, Java/Scala, Swift, Python, Javascript, but I would often miss the power of C++.

<br>

Whenever I had to use JNI or some other [FFI](https://en.wikipedia.org/wiki/Foreign_function_interface) (Foreign Function Interface), I felt weak. I don't want to have to wait for some third-party library to bind to my favorite language. I want to write high-performance code directly. But at that time I just didn't feel like C++ was a reasonable choice.

<br>

C++11 was on the horizon, promising to fix many of the issues, but the complexity of the language had already scared off many developers.

<br>

I took a long break from C++.

<br>

### Necessity is the mother of invention.

<br>

Fast forward to 2024, and I found myself needing to write some high-performance code for a project that couldn't tolerate garbage collection pauses. Python was too slow, Go's GC was unpredictable, and Rust's learning curve felt steep (and frankly I don't like it - `Arc<Mutex<DeezNutz>>`).

<br>

I reluctantly opened up a C++ project, expecting the same old frustrations. What I found instead was a revelation.

<br>

### Modern C++ is a different language.

<br>

The C++ I discovered was not the C++ I had left behind. C++11, C++14, C++17, and C++20 had fundamentally transformed the language. The improvements weren't just incremental, they were transformative.

<br>

**Auto type deduction** means I'm no longer writing `std::vector<std::string>::iterator` everywhere. Now it's just `auto`. The compiler figures it out, and my code is cleaner and more maintainable. It feels like I'm writing Python, but with all the performance of C++.

<br>

**Lambda functions** changed everything about how I write callbacks and functional-style code. Before, I'd create a functor class or a separate function. Now I can write inline lambda expressions that capture variables from the surrounding scope. Threading code went from painful to pleasant.

<br>

Speaking of which, **the standard threading library** finally arrived. No more `pthread` or platform-specific APIs. `std::thread`, `std::mutex`, `std::atomic`—it's all there, cross-platform, and actually usable. I can write concurrent code that works on Windows, Linux, and Mac without conditional compilation everywhere.

<br>

But the feature that truly won me back was **smart pointers**. `std::unique_ptr` and `std::shared_ptr` eliminated most of my memory management headaches. No more agonizing over when to call `delete`. No more memory leaks from forgotten cleanup in error paths. [RAII](https://en.wikipedia.org/wiki/Resource_acquisition_is_initialization) (Resource Acquisition Is Initialization) finally felt natural and automatic. I know there's a lot of RAII hate out there, but for me it's very natural and makes sense. If it doesn't for you, that's okay too.

<br>

```cpp
// old way - error prone
Widget* w = new Widget();
// ... do stuff ...
delete w; // Did I remember? What if there was an exception?
// new way - automatic cleanup
auto w = std::make_unique<Widget>();
// ... do stuff ...
// automatically cleaned up, exception safe
```

<br>

### The ecosystem caught up too.

<br>

It's not just the language. The tooling improved dramatically. CMake became tolerable. Package managers like Conan and vcpkg emerged. Compiler error messages, while still pretty bad, are lightyears better than the template error novels of 2010.

<br>

[LSPs](https://microsoft.github.io/language-server-protocol/) made code completion and navigation great. [Clang format](https://github.com/zackb/dots/blob/main/.clang-format) standardized code style. Sanitizers made debugging memory issues trivial. The whole development experience modernized. All of these things made editting code in [nvim](https://github.com/zackb/dots/tree/main/.config/nvim) a joy.

<br>

### AI assistants are a secret weapon.

<br>

Here's something unsurprising: AI coding assistants have made C++ significantly more approachable. Those cryptic template errors that used to send me down rabbit holes for hours? I paste them into Claude or ChatGPT and get a clear explanation and fix in seconds.

<br>

Writing boilerplate for move constructors, copy assignment operators (did i forget the third `&`?), or template specializations? The AI generates it correctly while I focus on the actual logic. Debugging subtle lifetime issues with references and pointers? The AI spots the problem I've been staring at for twenty minutes.

<br>

C++ has always had a steep learning curve with tons of gotchas: the rule of three, the rule of five, argument-dependent lookup, template SFINAE, undefined behavior landmines. AI assistants act like an expert pair programmer who knows all these pitfalls and helps you avoid them. They catch my mistakes before they cause the old headaches.

<br>

It's ironic: C++ became easier to write precisely when we got AI tools trained on decades of C++ code, patterns, and best practices. The accumulated wisdom of the C++ community is now available on-demand, making the language's complexity manageable in a way it never was before.

<br>

They still can't do the hard code, I recently wrote a [Wayland](https://github.com/zackb/hyprwat/tree/main/src/wayland)  + [EGL backend](https://github.com/zackb/hyprwat/tree/main/src/renderer) for [Dear ImGui](https://github.com/ocornut/imgui) and the AI was totally useless, but they handle the tedious stuff that used to make C++ a chore.

<br>

### C++ is great again.

<br>

I'm writing C++ daily now, and I'm enjoying it. I never, ever would have thought I'd say that again. I am having fun, and getting excited about [programming things I couldn't do in other languages](https://github.com/zackb/code/blob/master/cpp/mimic/src/main.cpp).

<br>

The language gives me the control and performance I need without the tedious manual memory management and verbose boilerplate that drove me away. It's the super language and probably always will be.

<br>

Modern C++ found the sweet spot: it kept the zero-cost abstractions and raw power, but added the ergonomics that developers expect in 2024. It's not perfect of course, the language is still complex, and there's legacy baggage, but it's legitimately great.

<br>

If you walked away from C++ years ago, give it another look. You might be surprised at what you find.

<br>

If you wish you could learn C++ and harness its power without the frustrations, now is the time, fire up [Antigravity](https://antigravity.google/) and get going.

<br>

The king has reclaimed its throne.
