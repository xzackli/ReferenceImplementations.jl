using Slow
using Test

@testset "Slow.jl" begin

    # test long form
    @slowdef function f(x)
        sleep(1)
        return sin(x)
    end
    @test @slow(f(1.0)) == sin(1.0)
    f(x) = sin(x)
    @test f(1.0) == @slow f(1.0)
    Slow.@slowtest f(2.0)


    # test short form
    @slowdef g(x) = isnothing(sleep(1)) && return cos(x)
    @test @slow(g(1.0)) == cos(1.0)
    g(x) = cos(x)
    @test g(1.0) == @slow g(1.0)
    Slow.@slowtest g(2.0)

end


# @testset "kwargs" begin
#     @slowdef f(x; y=0) = return y
#     f(x; y=0) = 0
#     @test @slow(f(1; y=1)) == 1
# end


@testset "slow a specific function" begin
    # fake naive implementation
    @slowdef function f(x)
        return 0
    end
    f(x) = x

    @slowdef function g(x)
        return f(x) * 2
    end
    g(x) = f(x) * 3
    @test @slow(f, g(1)) == 0
    @test @slow(g, g(1)) == 2
    @test @slow(g(1)) == 0
end


@testset "nesting" begin

    # fake naive implementation
    @slowdef function f(x)
        print("slow f\n")
        return x
    end

    @slowdef function g(x)
        print("slow g\n")
        return f(x) + 1
    end

    @test 2 == @slow g(1)
end