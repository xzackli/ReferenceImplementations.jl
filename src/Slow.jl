module Slow

using MacroTools
using Cassette
using Test

struct SlowImplementation end
struct SlowAll end
Cassette.@context SlowCtx

slow_call(::SlowCtx{Val{T}}, func, args...) where {T <: SlowAll} = func(args...)
Cassette.overdub(ctx::SlowCtx{Val{T}}, func, args...) where {T <: SlowAll} = slow_call(ctx, func, args...)
Cassette.overdub(ctx::SlowCtx{Val{T}}, func::Tf, args...) where {T, Tf<:T} =
    Cassette.recurse(ctx, func, SlowImplementation(), args...)

# reused in @slow to avoid having Cassette import in user code
overdub(args...; kwargs...) = Cassette.overdub(args...; kwargs...)
recurse(args...; kwargs...) = Cassette.recurse(args...; kwargs...)
slowctx(valt) = Cassette.disablehooks(SlowCtx(metadata=valt))

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
        $newfuncdef
        Slow.slow_call(ctx::Slow.SlowCtx{T}, func::typeof($funcname),
            args...) where {T <: Val{Slow.SlowAll}} =
            Slow.recurse(ctx, func, Slow.SlowImplementation(), args...)
    end
    # @show expr
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


# # slow down a specific function
# macro slow(slow_func, func_call)
#     # kwargs
#     if @capture(func_call, f_(args__; kwargs__))
#         newex = quote
#             Slow.overdub(Slow.SlowCtx(metadata=Val(typeof($(esc(slow_func))))),
#                 $(esc(f)), $(args...); $(kwargs...))
#         end
#         return newex
#     end

#     # no kwargs
#     if @capture(func_call, f_(args__))
#         newex = quote
#             Slow.overdub(Slow.SlowCtx(metadata=Val(
#                 typeof($(esc(slow_func))))), $(esc(f)), $(args...))
#         end
#         return newex
#     end

#     throw(ArgumentError("@slow must be applied to a function, i.e. @slow( f(x) )"))
# end


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
