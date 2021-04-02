```@meta
CurrentModule = Slow
```

# Slow

Documentation for [Slow](https://github.com/xzackli/Slow.jl). This package attempts to address a tension between understandability and efficiency in scientific computing. A naive Julia implementation of a calculation is often very readable, and resembles published equations or pseudocode. However, an optimized implementation that uses knowledge of how modern CPUs work can be much faster -- but it's usually more verbose. 

This package exports [`@slowdef`](@ref) to define a slower, naive implementation of a function, and call it with [`@slow`](@ref). Here's an example, where we implement a slow version of a function, and a fast version. 

```julia
using Slow

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

The function definition `func(args...)` prefaced by [`@slowdef`](@ref) is replaced with signature `func(::Slow.SlowImplementation, args...)`. This is a shortcut for a common Julia multimethod pattern, where different implementations dispatch on the first argument. I think the magic number here is two (fast and slow) -- if you have three or more implementations, you should probably just define your own multimethod type. This macro can help with development too -- one common pattern of writing code is to first make it correct, and then make it fast. By keeping separate fast and [`@slow`](@ref) implementations, one can more easily resist premature optimization and micro-optimizations.

If you're using the slow version in a complicated expression, you should use the macro [`@slow`](@ref) like a function and wrap the function call in parentheses, i.e.

```julia
@slow(f(1.0)) + 1.0
```


# API

```@index
```

```@autodocs
Modules = [Slow]
```
