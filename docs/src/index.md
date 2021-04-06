```@meta
CurrentModule = ReferenceImplementations
DocTestSetup = :(using ReferenceImplementations)
```

# ReferenceImplementations.jl

Documentation for [ReferenceImplementations.jl](https://github.com/xzackli/ReferenceImplementations.jl).


A typical workflow in science involves writing a function twice,

* **V1: Reference implementation.** Since Julia is so expressive, this implementation is usually short and resembles the published equations or pseudocode.
* **V2: Optimized implementation.** This version is written for computers, i.e. ⊂ { exploits symmetries, reuses allocated memory, hits the cache in a friendly way, reorders calculations for SIMD, divides the work with threads, precomputes parts, caches intermediate expressions, ... }.

V1 is easier to understand and extend. V2 is the implementation exported in your package and it's often much faster, but complicated and verbose. Julia sometimes allows you to use abstractions such that V1 ≈ V2, but this is not always possible. This package lets you define both implementations and select which one is run, even when the function is nested inside other function calls.

The `@refimpl` macro applies a [Cassette](https://github.com/JuliaLabs/Cassette.jl) pass to each 
top-level function in the input expression, recursively replacing nested methods that have a reference implementations. Those reference implementations are defined by prefacing a method definition with `@refimpl`.
A single function can be replaced via `@refimpl (func) (expression)`. 

## Examples

Calling `@refimpl` on an expression calls every method with a reference implementation
in the nested sequence of calls for that expression.

```julia
using ReferenceImplementations
@refimpl mysin(x) = begin println("ref mysin"); return sin(x) end
mysin(x) = begin println("mysin"); return sin(x) end

# call the reference implementation
@refimpl mysin(0.)  # prints "ref mysin"
mysin(0.)           # prints "mysin"
```

This works for `@refimpl` functions that are nested inside other functions in the expression.

```julia
@refimpl f(x) = begin println("ref f"); return mysin(x)^2 end
f(x) = begin println("f"); return mysin(x)^2 end

# call the reference implementation
@refimpl f(0.)  # prints "ref f", "ref mysin"
f(0.)           # prints "f", "mysin"
```

By default, [`@refimpl`](@ref) replaces every call in the expression which has a defined reference implementation.
It can sometimes be desirable to use the reference implementation of a specific function. This is achieved by providing a function before the expression to
be evaluated by `@refimpl (func) (expr)`.

```julia
@refimpl mysin f(0.)  # prints "f", "ref mysin"
@refimpl f f(0.)      # prints "ref f", "mysin"
```

Using `@refimpl` does incur some compilation cost, but subsequent calls should be fast. 

## Testing 

It can be useful to use the macro in your unit tests, where one assumes that the reference implementation is correct and then develops a highly-optimized version.

```julia
@test func(a, b) == @refimpl func(a, b)
```

Note that a macro's input is the entire expression after it. You should call the macro like a function in order to limit its effect.

```julia
@refimpl f(x) = 1x
f(x) = 2x

print( @refimpl(f(1)), ", ", f(1) )  # prints 1, 2 
```

## How?

If the `@refimpl` macro is applied to a method definition, it injects a first argument of type `ReferenceImplementations.RefImpl` into the signature. This performs the transform
```julia
func(args...; kwargs...)  ⇨  func(::ReferenceImplementations.RefImpl, args...; kwargs...)
``` 
with the type signatures preserved (so `where` and `::T` match, for example). When you apply the `@refimpl` macro to an expression that isn't a function definition, it applies a Cassette pass for each top-level function call in an expression, which replaces `func(args...; kwargs...)` with `func(::ReferenceImplementations.RefImpl, args...; kwargs...)` if that method exists. 

This also means that you can manually call the reference implementation without the macro, using
```julia
using ReferenceImplementations: RefImpl
func(RefImpl(), args...; kwargs...)
```



# API

```@index
```

```@autodocs
Modules = [ReferenceImplementations]
```
