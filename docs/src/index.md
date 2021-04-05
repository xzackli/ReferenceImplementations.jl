```@meta
CurrentModule = ReferenceImplementations
DocTestSetup = :(using ReferenceImplementations)
```

# ReferenceImplementations.jl

Documentation for [ReferenceImplementations.jl](https://github.com/xzackli/ReferenceImplementations.jl).

This package exports [`@refimpl`](@ref) to define a reference implementation of a function, and
call it (even when it's buried in some other function) using the [`@refimpl`](@ref) macro. It does
this by performing a Cassette pass on every top-level function call in the expression provided to the macro.

## Why?

I often write two versions of a function,

* **V1: Naive implementation.** Since Julia is so expressive, this implementation is usually short and resembles the published equations or pseudocode.
* **V2: Optimized implementation.** This version is written for a computer, i.e. ⊂ { exploits symmetries, reuses allocated memory, hits the cache in a friendly way, reorders calculations for SIMD, divides the work with threads, precomputes parts, caches intermediate expressions, ... }.

V1 is a reference implementation that is correct, easy to understand, and easy to extend. V2 is the implementation exported in your package and it's often much faster, but complicated and verbose. Julia sometimes allows you to use abstractions such that V1 ≈ V2, but this is not always possible. ReferenceImplementations.jl lets you keep both, and toggle them even when they're deeply nested.


## Usage
Here's an example, where we implement a reference implementation of a function, and a fast version.

```jldoctest example1
using ReferenceImplementations

# fake naive implementation
@refimpl function f(x)
    println("ref f")
    return sin(x)
end

# fake fast implementation
function f(x)
    println("f")
    return sin(x)
end

f(0.0)

# output

f
0.0
```
Running `f(0.0)` just uses the definition we gave for it. However, `@refimpl f(0.0)` will go to the reference implementation.

```jldoctest example1
@refimpl f(0.0)

# output

ref f
0.0
```

The function definition `func(args...)`, when prefaced by [`@refimpl`](@ref), instead defines a function with signature `func(::ReferenceImplementations.RefImpl, args...)`. Use of `func` can now
be be substituted with the reference implementation, even when the calls are nested in other functions.

```julia-repl example1
julia> h(x) = f(x)^2 + cos(x)^2
h (generic function with 1 method)

julia> h(1.0)
f
1.0

julia> @refimpl h(1.0)
ref f
0.0
```


## Single Function Selection

By default, [`@refimpl`](@ref) replaces every call in the expression which has a defined reference implementation.
It can sometimes be desirable to use the reference implementation of a specific function. This is achieved by providing a function before the expression to
be evaluated by `@refimpl (func) (expr)`.

```jldoctest
julia> @refimpl s(x) = begin println("ref s"); return sin(x) end
       s(x) = sin(x)
       @refimpl c(x) = begin println("ref c"); return cos(x) end
       c(x) = cos(x)
       h(x) = s(x)^2 + c(x)^2;

julia> @refimpl s h(0.5)
ref s
1.0

julia> @refimpl c h(0.5)
ref c
1.0

julia> @refimpl h(0.5)
ref s
ref c
1.0
```


# API

```@index
```

```@autodocs
Modules = [ReferenceImplementations]
```
