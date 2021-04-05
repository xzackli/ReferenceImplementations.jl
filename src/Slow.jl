module Slow

export @slowdef, @slow

using MacroTools
using MacroTools: postwalk
using Cassette
using Test

struct SlowImplementation end
struct SlowAll end
Cassette.@context SlowCtx

# used as Slow.overdub, etc. in macros to shorten the expressions a bit
const overdub = Cassette.overdub
const recurse = Cassette.recurse

# generate a standard SlowCtx context (no hooks!)
slowctx(valT) = Cassette.disablehooks(SlowCtx(metadata=valT))


"""
    @slowdef

Define a slow version of a function which can be called with [`@slow`](@ref).
"""
macro slowdef(func)
    funcdef = splitdef(func)
    pushfirst!(funcdef[:args], :(::Slow.SlowImplementation))
    funcname = funcdef[:name]
    newfuncdef = MacroTools.combinedef(funcdef)

    if length(funcdef[:kwargs]) > 0  # we have kwargs
        kwblock = quote
            Slow.overdub(ctx::Slow.SlowCtx{Val{T}}, kwf::Core.kwftype(typeof($funcname)),
                kwargs::Any, func::typeof($funcname), args...) where {T <: Slow.SlowAll} =
                    Slow.recurse(ctx, kwf, kwargs, func, Slow.SlowImplementation(), args...)
            Slow.overdub(ctx::Slow.SlowCtx{Val{T}}, kwf::Core.kwftype(typeof($funcname)),
                kwargs::Any, func::T, args...) where {T <: typeof($funcname)} =
                    Slow.recurse(ctx, kwf, kwargs, func, Slow.SlowImplementation(), args...)
        end
    else  # just args
        kwblock = quote
            Slow.overdub(ctx::Slow.SlowCtx{Val{T}}, func::typeof($funcname), args...) where {T <: Slow.SlowAll} =
                Slow.recurse(ctx, func, Slow.SlowImplementation(), args...)
            Slow.overdub(ctx::Slow.SlowCtx{Val{T}}, func::T, args...) where {T <: typeof($funcname)} =
                Slow.recurse(ctx, func, Slow.SlowImplementation(), args...)
        end
    end

    # @show kwblock
    return esc(Expr(:block, newfuncdef, kwblock))
end


extractkwargs(; kwargs...) = values(kwargs)
slowall(f, args...) = overdub(slowctx(Val(SlowAll)), f, args...)
slowone(f, slow_func, args...) = Slow.overdub(
    Slow.slowctx(Val(typeof(slow_func))), f, args...)


"""
    @slow

Call a slow version of a function that was defined with [`@slowdef`](@ref).
```
"""
macro slow(ex)
    newex = postwalk(ex) do x
        if @capture(x, f_(args__; kwargs__))
            return quote
                Slow.slowall(Core.kwfunc($(esc(f))),
                    Slow.extractkwargs(;$(kwargs...)), $(esc(f)), $(args...))
            end
        elseif @capture(x, f_(args__))
            return quote
                Slow.slowall($(esc(f)), $(args...))
            end
        else
            return x
        end
    end
    return newex
end


# slow down a specific function
macro slow(slow_func, ex)
    newex = postwalk(ex) do x
        if @capture(x, f_(args__; kwargs__))
            return quote
                Slow.slowone(Core.kwfunc($(esc(f))), $(esc(slow_func)),
                    Slow.extractkwargs(;$(kwargs...)), $(esc(f)), $(args...))
            end
        elseif @capture(x, f_(args__))
            return quote
                Slow.slowone($(esc(f)), $(esc(slow_func)), $(args...))
            end
        else
            return x
        end
    end
end


"""
    @slowtest

Shortcut for `@test (@slow func(args...)) == func(args...)`.
"""
macro slowtest(func)
    if @capture(func, f_(xs__))
        newex = quote
            @test $(esc(func)) == $(esc(f))(Slow.SlowImplementation(), $(xs...))
        end
        return newex
    end
    throw(ArgumentError("@slowtest must be applied to a function, i.e. @slowtest( f(x) ) or @slowtest f(x)"))
end

end  # module
