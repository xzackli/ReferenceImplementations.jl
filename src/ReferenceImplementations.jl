module ReferenceImplementations

export @refimpl

using MacroTools
using MacroTools: postwalk
using Cassette
using Test

struct RefImpl end
struct RefImplAll end  # used to dispatch when invoking all reference implementations
Cassette.@context RefImplCtx

# used as ReferenceImplementations.overdub, etc. in macros to shorten the expressions a bit
const overdub = Cassette.overdub
const recurse = Cassette.recurse

# generate a standard RefImplCtx context (no hooks!)
refimplctx(valT) = Cassette.disablehooks(RefImplCtx(metadata=valT))

# define a reference implementation
function refimpl_def(func)
    funcdef = splitdef(func)
    funcargs = copy(funcdef[:args])
    pushfirst!(funcdef[:args], :(::ReferenceImplementations.RefImpl))

    funcname = funcdef[:name]
    newfuncdef = MacroTools.combinedef(funcdef)

    if length(funcdef[:kwargs]) > 0  # we have kwargs
        overdub_block = quote
            ReferenceImplementations.overdub(ctx::ReferenceImplementations.RefImplCtx{Val{T}}, kwf::Core.kwftype(typeof($funcname)),
                kwargs::Any, func::typeof($funcname), $(funcargs...)) where {T <: ReferenceImplementations.RefImplAll} =
                    ReferenceImplementations.recurse(ctx, kwf, kwargs, func, ReferenceImplementations.RefImpl(), $(funcargs...))
            ReferenceImplementations.overdub(ctx::ReferenceImplementations.RefImplCtx{Val{T}}, kwf::Core.kwftype(typeof($funcname)),
                kwargs::Any, func::T, $(funcargs...)) where {T <: typeof($funcname)} =
                    ReferenceImplementations.recurse(ctx, kwf, kwargs, func, ReferenceImplementations.RefImpl(), $(funcargs...))
        end
    else  # just args
        overdub_block = quote
            ReferenceImplementations.overdub(ctx::ReferenceImplementations.RefImplCtx{Val{T}}, func::typeof($funcname),
                $(funcargs...)) where {T <: ReferenceImplementations.RefImplAll} =
                ReferenceImplementations.recurse(ctx, func, ReferenceImplementations.RefImpl(), $(funcargs...))
            ReferenceImplementations.overdub(ctx::ReferenceImplementations.RefImplCtx{Val{T}}, func::T,
                $(funcargs...)) where {T <: typeof($funcname)} =
                ReferenceImplementations.recurse(ctx, func, ReferenceImplementations.RefImpl(), $(funcargs...))
        end
    end

    return (Expr(:block, newfuncdef, overdub_block))
end


# used to convert kwarg iterator to NamedTuple
extractkwargs(; kwargs...) = values(kwargs)

# functions for overdubbing
refimplall(f, args...) = overdub(refimplctx(Val(RefImplAll)), f, args...)
refimplone(f, ref_func, args...) = overdub(refimplctx(Val(typeof(ref_func))), f, args...)


# evaluate expression with all reference implementations inside
function refimpl_call(ex)
    newex = postwalk(ex) do x
        if @capture(x, f_(args__; kwargs__))
            return quote
                ReferenceImplementations.refimplall(Core.kwfunc($(esc(f))),
                    ReferenceImplementations.extractkwargs(;$(kwargs...)), $(esc(f)), $(args...))
            end
        elseif @capture(x, f_(args__))
            return quote
                ReferenceImplementations.refimplall($(esc(f)), $(args...))
            end
        else
            return x
        end
    end
    return newex
end


# evaluate expression with where only one function's reference implementations are invoked
function refimpl_call(ref_func, ex)
    newex = postwalk(ex) do x
        if @capture(x, f_(args__; kwargs__))
            return quote
                ReferenceImplementations.refimplone(Core.kwfunc($(esc(f))), $(esc(ref_func)),
                    ReferenceImplementations.extractkwargs(;$(kwargs...)), $(esc(f)), $(args...))
            end
        elseif @capture(x, f_(args__))
            return quote
                ReferenceImplementations.refimplone($(esc(f)), $(esc(ref_func)), $(args...))
            end
        else
            return x
        end
    end
end


"""
    @refimpl (method definition)
    @refimpl (expression)
    @refimpl (function name) (expression)

* If prefacing a function definition, defines a reference implementation for that function.
* If prefacing an expression, calls reference implementations of methods defined with [`@refimpl`](@ref).

Preface an expression performs a Cassette pass on every top-level function
in the expression, recursively looking for methods with @refimpl implementations.
If a function is passed before the expression (separated by a space), only that
method is switched with its reference implementation.

# Examples

Calling `@refimpl` on an expression calls every method with a reference implementation
in the nested sequence of calls for that expression.

```julia
using ReferenceImplementations
@refimpl mysin(x) = begin println("ref mysin"); return sin(x) end
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
"""
macro refimpl(ex)
    if @capture(MacroTools.longdef1(ex),
                   function (fcall_ | fcall_) body_ end)
        return esc(refimpl_def(ex))
    else
        return refimpl_call(ex)
    end
end


# invoke a a specific function's reference implementation
macro refimpl(ref_func, ex)
    return refimpl_call(ref_func, ex)
end



end  # module
