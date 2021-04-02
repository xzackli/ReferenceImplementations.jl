```@meta
CurrentModule = Slow
```

# Slow

Documentation for [Slow](https://github.com/xzackli/Slow.jl). This package attempts to address a tension between understandability and efficiency in scientific computing.

* The naive implementation of a scientific calculation in Julia is usually good enough. However, a factor of ``\sim 2-100`` in performance can be obtained by thinking about how modern computers work. For example -- reducing allocations by keeping buffers around, making calculations cache-friendly, and grouping similar calculations with SIMD.
* The naive implementation and the optimized numerical version can look very different. The optimized version is usually the one that people call from outside the package, but the naive implementation will resemble the equations in the paper.
* It's useful to keep around the naive implementation. If you're developing some extension to the code, being able to start with a paste of the naive but correct implementation can be very handy. It's also informative for new contributors to packages.
* It can be nice to write unit tests which compare the naive and fast implementations.

This package exports [`@slowdef`](@ref) to define a slower, naive implementation of a function, and call it with [`@slow`](@ref). Here's an example, where we implement a slow version of a function, and a fast version. 

```julia
using Slow

# fake naive implementation
@slowdef function f(x)
    sleep(1)  
    return sin(x)
end

# fake fast implementation
f(x) = sin(x)

@time @slow f(1.0)
@time f(1.0)
```

The function definition `func(args...) = ...` prefaced by [`@slowdef`](@ref) is replaced with `func(::Slow.SlowImplementation, args...) = ...`. This is a shortcut for a common Julia multimethod pattern, where different implementations dispatch on the first argument. I think the magic number here is two (fast and slow) -- if you have three implementations, you should probably just define your own multimethod type.

This macro can help with development too -- one common pattern of writing code is to (first) make it correct and (then) make it fast. By keeping separate fast and [`@slow`](@ref) implementations, one can more easily resist premature optimization and micro-optimizations.


```@index
```

```@autodocs
Modules = [Slow]
```
