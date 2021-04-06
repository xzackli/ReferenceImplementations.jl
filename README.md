# ReferenceImplementations.jl

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://xzackli.github.io/ReferenceImplementations.jl/stable) -->
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://xzackli.github.io/ReferenceImplementations.jl/dev)
[![Build Status](https://github.com/xzackli/ReferenceImplementations.jl/workflows/CI/badge.svg)](https://github.com/xzackli/ReferenceImplementations.jl/actions)
[![codecov](https://codecov.io/gh/xzackli/ReferenceImplementations.jl/branch/main/graph/badge.svg?token=rM1AU0MQ38)](https://codecov.io/gh/xzackli/ReferenceImplementations.jl)

This package exports the `@refimpl` macro to help you write fast scientific code. It lets you define two implementations of the same method, by prefacing the reference implementation's definition with `@refimpl`. The non-reference implementation is called by default, but the reference implementation can be invoked in an expression using the same macro `@refimpl`, even if the method call is deeply nested.

For more instructions, please consult the [documentation](https://xzackli.github.io/ReferenceImplementations.jl/dev).

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
