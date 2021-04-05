```@meta
CurrentModule = ReferenceImplementations
DocTestSetup = :(using ReferenceImplementations)
```

# ReferenceImplementations.jl

Documentation for [ReferenceImplementations.jl](https://github.com/xzackli/ReferenceImplementations.jl). 

This package exports [`@slowdef`](@ref) to define a slower, naive implementation of a function, and 
change it (even when it's buried in some other function) using the [`@slow`](@ref) macro. It does 
this by performing a Cassette pass on every top-level function call in the expression provided to the macro.

## Why?

I often write two versions of a function,

* **V1: Naive implementation.** Since Julia is so expressive, this implementation is usually short and resembles the published equations or pseudocode.
* **V2: Optimized implementation.** This version is written for a computer, i.e. ⊂ { exploits symmetries, reuses allocated memory, hits the cache in a friendly way, reorders calculations for SIMD, divides the work with threads, precomputes parts, caches intermediate expressions, ... }.

V1 is easier to understand and extend. V2 is the implementation exported in your package and it's often much faster, but complicated and verbose. Julia sometimes allows you to use abstractions such that V1 ≈ V2, but this is not always possible. ReferenceImplementations.jl lets you keep both, and toggle them even when they're deeply nested.


## Usage
Here's an example, where we implement a slow version of a function, and a fast version. 

```jldoctest example1
using ReferenceImplementations

# fake naive implementation
@slowdef function f(x)
    println("slow f")
    return sin(x)
end

# fake fast implementation
function f(x)
    println("fast f")
    return sin(x)
end

f(0.0)

# output

fast f
0.0
```
Running `f(0.0)` just uses the definition we gave for it. However, `@slow f(0.0)` will go to the `@slowdef` version.

```jldoctest example1
@slow f(0.0)

# output

slow f
0.0
```

The function definition `func(args...)`, when prefaced by [`@slowdef`](@ref), instead defines a function with signature `func(::ReferenceImplementations.RefImpl, args...)`. Use of `func` can now 
be toggled between the slow and fast implementations, for arbitrary nesting.

```julia-repl example1
julia> h(x) = f(x)^2 + cos(x)^2
h (generic function with 1 method)

julia> h(1.0)
fast f
1.0

julia> @slow h(1.0)
slow f
0.0
```


## Single Function Selection

By default, [`@slow`](@ref) slows every function involved in the expression which has a slow implementation in the caller's module. 
It can sometimes be desirable to slow down a specific function. This is achieved by providing a function before the expression to
be evaluated by `@slow func (expr)`.

```jldoctest
julia> @slowdef s(x) = begin println("slow s"); return sin(x) end
       s(x) = sin(x)
       @slowdef c(x) = begin println("slow c"); return cos(x) end
       c(x) = cos(x)
       h(x) = s(x)^2 + c(x)^2;

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
Modules = [ReferenceImplementations]
```
