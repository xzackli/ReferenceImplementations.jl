module Slow

using MacroTools
using Cassette
using Test

struct SlowImplementation end
Cassette.@context SlowCtx
slow_call(func, args...; kwargs...) = func(args...; kwargs...)
Cassette.overdub(::SlowCtx{Val{nothing}}, func, args...; kwargs...) = slow_call(func, args...; kwargs...)
Cassette.overdub(::SlowCtx{Val{T}}, func::T, args...; kwargs...) where T = slow_call(func, args...; kwargs...)

# reused in @slow to avoid having Cassette import in user code
overdub(args...; kwargs...) = Cassette.overdub(args...; kwargs...)

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
        slow_call(::typeof($funcname), args...; kwargs...) =
            ($funcname)(Slow.SlowImplementation(), args...; kwargs...)
    end
    # @show expr
    esc(expr)
end


"""
    @slow

Call a slow version of a function that was defined with [`@slowdef`](@ref).
```
"""
macro slow(func)
    # kwargs
    if @capture(func, f_(args__; kwargs__))
        newex = quote
            Slow.overdub(Slow.SlowCtx(metadata=Val(nothing)), $(esc(f)), $(args...); $(kwargs...))
        end
        return newex
    end

    # no kwargs
    if @capture(func, f_(args__))
        newex = quote
            Slow.overdub(Slow.SlowCtx(metadata=Val(nothing)), $(esc(f)), $(args...))
        end
        return newex
    end

    throw(ArgumentError("@slow must be applied to a function, i.e. @slow( f(x) )"))
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
