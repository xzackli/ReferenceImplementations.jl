module ReferenceImplementations

export @slowdef, @slow

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


"""
    @slowdef [function definition]

Define a slow version of a function which can be called with [`@slow`](@ref). To use,
preface a method definition with this macro.

# Examples
```julia
using ReferenceImplementations

# define a slow version of x
@slowdef f(x) = println("slow")
f(x) = println("fast")

@slow f(0.0)  # prints "slow"
f(0.0)        # prints "fast"

# you can also use the full function definition form, of course
@slowdef function g(x::T) where T
    return x
end
```
"""
macro slowdef(func)
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

    return esc(Expr(:block, newfuncdef, overdub_block))
end

# used to convert kwarg iterator to NamedTuple
extractkwargs(; kwargs...) = values(kwargs)

# functions for overdubbing
refimplall(f, args...) = overdub(refimplctx(Val(RefImplAll)), f, args...)
refimplone(f, slow_func, args...) = overdub(refimplctx(Val(typeof(slow_func))), f, args...)


"""
    @slow (expr)
    @slow (func) (expr)

Call a slow version of a function that was defined with [`@slowdef`](@ref).
Preface an expression in order to perform a Cassette pass on every top-level function
in the expression, recursively looking for functions with @slowdef implementations.
If a function is passed before the expression (separated by a space), only that
function is slowed.

# Examples

Calling `@slow` on an expression calls every function with a slow implementation
in the nested sequence of calls for that expression.

```julia
@slowdef s(x) = begin println("slow s"); return sin(x) end
s(x) = begin println("fast s"); return sin(x) end

# call the slow version
@slow s(0.)  # prints "slow s"
s(0.)        # prints "fast s"
```

This works for slow functions that are nested inside other functions in the expression.

```julia
@slowdef f(x) = begin println("slow f"); return s(x)^2 end
f(x) = begin println("fast f"); return s(x)^2 end

# call the slow version
@slow f(0.)  # prints "slow f", "slow s"
f(0.)        # prints "fast f", "fast s"
```

You can target individual functions for slowing by passing a function after ReferenceImplementations.

```julia
@slow s f(0.)  # prints "fast f", "slow s"
@slow f f(0.)  # prints "slow f", "fast s"
```
"""
macro slow(ex)
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


# slow down a specific function.
macro slow(slow_func, ex)
    newex = postwalk(ex) do x
        if @capture(x, f_(args__; kwargs__))
            return quote
                ReferenceImplementations.refimplone(Core.kwfunc($(esc(f))), $(esc(slow_func)),
                    ReferenceImplementations.extractkwargs(;$(kwargs...)), $(esc(f)), $(args...))
            end
        elseif @capture(x, f_(args__))
            return quote
                ReferenceImplementations.refimplone($(esc(f)), $(esc(slow_func)), $(args...))
            end
        else
            return x
        end
    end
end


# Shortcut for `@test (@slow func(args...)) == func(args...)`.
macro slowtest(func)
    if @capture(func, f_(xs__))
        newex = quote
            @test $(esc(func)) == $(esc(f))(ReferenceImplementations.RefImpl(), $(xs...))
        end
        return newex
    end
    throw(ArgumentError("@slowtest must be applied to a function, i.e. @slowtest( f(x) ) or @slowtest f(x)"))
end

end  # module
