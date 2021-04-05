# ReferenceImplementations.jl

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://xzackli.github.io/ReferenceImplementations.jl/stable) -->
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://xzackli.github.io/ReferenceImplementations.jl/dev)
[![Build Status](https://github.com/xzackli/ReferenceImplementations.jl/workflows/CI/badge.svg)](https://github.com/xzackli/ReferenceImplementations.jl/actions)
[![codecov](https://codecov.io/gh/xzackli/ReferenceImplementations.jl/branch/main/graph/badge.svg?token=rM1AU0MQ38)](https://codecov.io/gh/xzackli/ReferenceImplementations.jl)

This package exports `@refimpl` macro to help you write fast scientific code. The `@refimpl` macro applies a [Cassette](https://github.com/JuliaLabs/Cassette.jl) pass to each 
top-level function in the input expression, recursively replacing nested methods that have alternative implementations defined by prefacing a method definition with `@refimpl`.
A single function can be replaced via `@refimpl f (expression)`. 

For instructions, please consult the [documentation](https://xzackli.github.io/ReferenceImplementations.jl/dev).


## Examples

Calling `@refimpl` on an expression calls every method with a reference implementation
in the nested sequence of calls for that expression.

```julia
using ReferenceImplementations
@refimpl_def mysin(x) = begin println("ref mysin"); return sin(x) end
mysin(x) = begin println("mysin"); return sin(x) end

# call the reference implementation
@refimpl mysin(0.)  # prints "ref mysin"
mysin(0.)        # prints "mysin"
```

This works for `@refimpl` functions that are nested inside other functions in the expression.

```julia
@refimpl f(x) = begin println("ref f"); return mysin(x)^2 end
f(x) = begin println("f"); return mysin(x)^2 end

# call the reference implementation
@refimpl f(0.)  # prints "ref f", "ref mysin"
f(0.)        # prints "f", "mysin"
```

You can target individual functions to be replaced with their reference implementation by passing that function after `@refimpl`.

```julia
@refimpl mysin f(0.)  # prints "fast f", "ref mysin"
@refimpl f f(0.)  # prints "ref f", "fast mysin"
```

Using `@refimpl` does incur some compilation cost, but subsequent calls should be fast.

## Why?

I often write two versions of a function,

* **V1: Naive implementation.** Since Julia is so expressive, this implementation is usually short and resembles the published equations or pseudocode.
* **V2: Optimized implementation.** This version is written for a computer, i.e. ⊂ { exploits symmetries, reuses allocated memory, hits the cache in a friendly way, reorders calculations for SIMD, divides the work with threads, precomputes parts, caches intermediate expressions, ... }.

V1 is easier to understand and extend. V2 is the implementation exported in your package and it's often much faster, but complicated and verbose. Julia sometimes allows you to use abstractions such that V1 ≈ V2, but this is not always possible. ReferenceImplementations.jl lets you keep both.

## How?

`@refimpl_def` injects a first argument into the method signature, doing the transform
```julia
func(args...; kwargs...)  ⇨  func(::ReferenceImplementations.RefImpl, args...; kwargs...)
``` 
with the same type signatures (preserving `where` and `::T`, for example). The `@refimpl` macro then applies a Cassette pass for each top-level function call in an expression which replaces `func(args...; kwargs...)` with `func(::ReferenceImplementations.RefImpl, args...; kwargs...)` if that method exists.
