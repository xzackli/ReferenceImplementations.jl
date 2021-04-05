```@meta
CurrentModule = Slow
```

# Slow

Documentation for [Slow](https://github.com/xzackli/Slow.jl). 

This package exports [`@slowdef`](@ref) to define a slower, naive implementation of a function, and 
change it (even when it's buried in some other function) using the [`@slow`](@ref) macro. It does 
this by performing a Cassette pass on every top-level function call in the expression provided to the macro.
Here's an example, where we implement a slow version of a function, and a fast version. 

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

The function definition `func(args...)` prefaced by [`@slowdef`](@ref) is replaced with signature `func(::Slow.SlowImplementation, args...)`. Nested use of `func` can now 
be toggled between the slow and fast implementations.

```julia
h(x) = f(x)^2 + cos(x)^2

@time @slow h(1.0)
@time h(1.0)
```
```
1.002132 seconds (18 allocations: 464 bytes)
0.000000 seconds
```
Note that the allocations here arise from the use of `@time`, not [`@slow`](@ref) which only operates before compilation.

## Single Function Selection

By default, [`@slow`](@ref) slows every function involved in the expression which has a slow implementation in the caller's module. 
It can sometimes be desirable to slow down a specific function. This is achieved by providing a function before the expression to
be evaluated by [`@slow`](@ref).

```julia
julia> @slowdef function s(x)
           println("slow s") 
           return sin(x)
       end
       s(x) = sin(x)
       
       @slowdef function c(x)
           println("slow c") 
           return cos(x)
       end
       c(x) = cos(x)

       h(x) = s(x)^2 + c(x)^2

julia> @slow s h(0.5)
slow s
1.0

julia> @slow c h(0.5)
slow c
1.0

julia> @slow h(0.5)
slow s
slow c
1.0
```



# API

```@index
```

```@autodocs
Modules = [Slow]
```
