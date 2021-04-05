# Slow.jl

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://xzackli.github.io/Slow.jl/stable) -->
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://xzackli.github.io/Slow.jl/dev)
[![Build Status](https://github.com/xzackli/Slow.jl/workflows/CI/badge.svg)](https://github.com/xzackli/Slow.jl/actions)
[![codecov](https://codecov.io/gh/xzackli/Slow.jl/branch/main/graph/badge.svg?token=rM1AU0MQ38)](https://codecov.io/gh/xzackli/Slow.jl)

This package exports `@slowdef` and `@slow` macros to help you write fast scientific code. The `@slow` macro applies a [Cassette](https://github.com/JuliaLabs/Cassette.jl) pass to each 
top-level function in the input expression, recursively replacing nested functions that have alternative implementations provided by `@slowdef`.
A single function can be replaced via `@slow f (expression)`. 

For instructions, please consult the [documentation](https://xzackli.github.io/Slow.jl/dev).


# Examples

Calling `@slow` on an expression calls every function with a slow implementation
in the nested sequence of calls for that expression.

```julia
using Slow
@slowdef mysin(x) = begin println("slow mysin"); return sin(x) end
mysin(x) = begin println("fast mysin"); return sin(x) end

# call the slow version
@slow mysin(0.)  # prints "slow mysin"
mysin(0.)        # prints "fast mysin"
```

This works for slow functions that are nested inside other functions in the expression.

```julia
@slowdef f(x) = begin println("slow f"); return s(x)^2 end
f(x) = begin println("fast f"); return s(x)^2 end

# call the slow version
@slow f(0.)  # prints "slow f", "slow mysin"
f(0.)        # prints "fast f", "fast mysin"
```

You can target individual functions for slowing by passing a function after slow.

```julia
@slow s f(0.)  # prints "fast f", "slow mysin"
@slow f f(0.)  # prints "slow f", "fast mysin"
```

## Why?

I often write two versions of a function,

* **V1: Naive implementation.** Since Julia is so expressive, this implementation is usually short and resembles the published equations or pseudocode.
* **V2: Optimized implementation.** This version is written for a computer, i.e. ⊂ { exploits symmetries, reuses allocated memory, hits the cache in a friendly way, reorders calculations for SIMD, divides the work with threads, precomputes parts, caches intermediate expressions, ... }.

V1 is easier to understand and extend. V2 is the implementation exported in your package and it's often much faster, but complicated and verbose. Julia sometimes allows you to use abstractions such that V1 ≈ V2, but this is not always possible. Slow.jl lets you keep both.
