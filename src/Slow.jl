module Slow

using MacroTools
using Test

export @slowdef, @slow
# export @slowtest

struct SlowImplementation end


"""
    @slowdef

Define a slow version of a function which can be called with [`@slow`](@ref).
"""
macro slowdef(func)
    funcdef = splitdef(func)
    pushfirst!(funcdef[:args], :(::Slow.SlowImplementation))
    newex = MacroTools.combinedef(funcdef)
    esc(newex)
end


"""
    @slow

Call a slow version of a function that was defined with [`@slowdef`](@ref).
```
"""
macro slow(func)
    if @capture(func, f_(xs__))
        newex = quote
            $(esc(f))(Slow.SlowImplementation(), $(xs...))
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
