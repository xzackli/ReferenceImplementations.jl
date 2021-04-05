# SlowMacro.jl

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://xzackli.github.io/SlowMacro.jl/stable) -->
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://xzackli.github.io/SlowMacro.jl/dev)
[![Build Status](https://github.com/xzackli/SlowMacro.jl/workflows/CI/badge.svg)](https://github.com/xzackli/SlowMacro.jl/actions)
[![codecov](https://codecov.io/gh/xzackli/SlowMacro.jl/branch/main/graph/badge.svg?token=rM1AU0MQ38)](https://codecov.io/gh/xzackli/SlowMacro.jl)

This package exports `@slowdef` and `@slow` macros to help you write fast scientific code. The `@slow` macro applies a Cassette pass to each 
top-level function in the input expression, recursively replacing nested functions that have alternative implementations provided by `@slowdef`.
A single function can be replaced via `@slow f (expression)`. 

For instructions, please consult the [documentation](https://xzackli.github.io/SlowMacro.jl/dev).

```julia
using SlowMacro

# fake naive implementation
@slowdef function f(x)
    sleep(1)  
    return sin(x)
end

# fake fast implementation
function f(x)
    return sin(x)
end

@time @slow f(1.0)
@time f(1.0)
```

## Why?

I often write two versions of a function,

* **V1: Naive implementation.** Since Julia is so expressive, this implementation is usually short and resembles the published equations or pseudocode.
* **V2: Optimized implementation.** This version is written for a computer, i.e. ⊂ { exploits symmetries, reuses allocated memory, hits the cache in a friendly way, reorders calculations for SIMD, divides the work with threads, precomputes parts, caches intermediate expressions, ... }.

V1 is easier to understand and extend. V2 is the implementation exported in your package and it's often much faster, but complicated and verbose. Julia sometimes allows you to use abstractions such that V1 ≈ V2, but this is not always possible. SlowMacro.jl lets you keep both.
