using Slow
using Test

@testset "Slow.jl" begin

    # test long form
    @slowdef function f(x)
        sleep(1)
        return sin(x)
    end
    f(x) = sin(x)

    @test f(1.0) == @slow f(1.0)
    @slowtest f(2.0)

    # test short form
    @slowdef g(x) = isnothing(sleep(1)) && return cos(x)
    g(x) = cos(x)

    @test g(1.0) == @slow g(1.0)
    @slowtest g(2.0)

end
