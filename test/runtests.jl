using ReferenceImplementations
using Test

@testset "ReferenceImplementations.jl" begin

    # test long form
    @refimpl function f(x)
        sleep(1)
        return sin(x)
    end
    @test @refimpl(f(1.0)) == sin(1.0)
    f(x) = sin(x)
    @test f(1.0) == @refimpl f(1.0)


    # test short form
    @refimpl g(x) = isnothing(sleep(1)) && return cos(x)
    @test @refimpl(g(1.0)) == cos(1.0)
    g(x) = cos(x)
    @test g(1.0) == @refimpl g(1.0)

end

##
@testset "kwargs" begin
    @refimpl f(x; y=0) = return y
    f(x; y=0) = 0
    @test @refimpl(f(1; y=1)) == 1
    @test @refimpl(f, f(1; y=1)) == 1

    @refimpl kwf(y; x=0.) = cos(x)
    kwf(y; x=0.) = sin(x)
    @test @refimpl kwf(0.; x=0.) == 1.
end

##
@testset "refimpl a specific function" begin
    # fake naive implementation
    @refimpl function f(x)
        return 0
    end
    f(x) = x

    @refimpl function g(x)
        return f(x) * 2
    end
    g(x) = f(x) * 3
    @test @refimpl(f, g(1)) == 0
    @test @refimpl(g, g(1)) == 2
    @test @refimpl(g(1)) == 0
end

##
@testset "nesting" begin

    # fake naive implementation
    @refimpl function f(x)
        print("ref f\n")
        return x
    end

    @refimpl function g(x)
        print("ref g\n")
        return f(x) + 1
    end

    @test 2 == @refimpl g(1)
end

## shouldn't replace methods that don't have reference implementations
@testset "refimpl only specific type signatures" begin
    @refimpl f(x::Int) = x
    f(x::Float64) = x
    @test @refimpl f(0.) == 0.
    @test @refimpl f f(0.) == 0.
end


## no composite arguments (i.e. function definition and other expressions)
@testset "no composites" begin
    @test_throws ArgumentError("To define a new reference implementation, the argument"*
        " of @refimpl must contain only a function definition.") try @eval (@refimpl begin
                    f(x) = 1
                    1 + 1
                end) catch err; throw(err.error) end
end

## escaping local
@testset "escaping locals" begin
    x = 0.0
    @refimpl f(x) = sin(x)
    @test @refimpl f(x) == 0.0
end
