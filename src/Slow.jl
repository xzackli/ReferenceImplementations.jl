module Slow

using MacroTools
using Cassette
using Test

struct SlowImplementation end
struct SlowAll end
Cassette.@context SlowCtx

Cassette.overdub(ctx::SlowCtx{Val{T}}, func::Tf, args...) where {T, Tf<:T} =
    Cassette.recurse(ctx, func, SlowImplementation(), args...)

# used as Slow.overdub, etc. in macros
const overdub = Cassette.overdub
const recurse = Cassette.recurse
slowctx(valT) = Cassette.disablehooks(SlowCtx(metadata=valT))

export @slowdef, @slow


"""
    @slowdef

Define a slow version of a function which can be called with [`@slow`](@ref).
"""
macro slowdef(func)
    funcdef = splitdef(func)
    pushfirst!(funcdef[:args], :(::Slow.SlowImplementation))
    funcname = funcdef[:name]
    newfuncdef = MacroTools.combinedef(funcdef)
    expr = quote
        if @isdefined(slow_call) == false
            slow_call(::Slow.SlowCtx{Val{T}}, func, args...) where {T <: Slow.SlowAll} = func(args...)
            Slow.overdub(ctx::Slow.SlowCtx{Val{T}}, func, args...) where {T <: Slow.SlowAll} = slow_call(ctx, func, args...)
        end
        $newfuncdef
        slow_call(ctx::Slow.SlowCtx{T}, func::typeof($funcname),
            args...) where {T <: Val{Slow.SlowAll}} =
            Slow.recurse(ctx, func, Slow.SlowImplementation(), args...)
    end
    esc(expr)
end


"""
    @slow

Call a slow version of a function that was defined with [`@slowdef`](@ref).
```
"""
macro slow(func_call)
    # # kwargs
    # if @capture(func_call, f_(args__; kwargs__))
    #     newex = quote
    #         Slow.overdub(Slow.SlowCtx(metadata=Val(nothing)), $(esc(f)), $(args...); $(kwargs...))
    #     end
    #     return newex
    # end

    # no kwargs
    if @capture(func_call, f_(args__))
        newex = quote
            Slow.overdub(Slow.slowctx(Val(Slow.SlowAll)), $(esc(f)), $(args...))
        end
        return newex
    end

    throw(ArgumentError("@slow must be applied to a function, i.e. @slow( f(x) )"))
end


# slow down a specific function
macro slow(slow_func, func_call)
    # # kwargs
    # if @capture(func_call, f_(args__; kwargs__))
    #     newex = quote
    #         Slow.overdub(Slow.SlowCtx(metadata=Val(typeof($(esc(slow_func))))),
    #             $(esc(f)), $(args...); $(kwargs...))
    #     end
    #     return newex
    # end

    # no kwargs
    if @capture(func_call, f_(args__))
        newex = quote
            Slow.overdub(Slow.slowctx(Val(typeof($(esc(slow_func))))),
                $(esc(f)), $(args...))
        end
        return newex
    end

    throw(ArgumentError("@slow must be applied to a function, i.e. @slow(f, f(x))"))
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
