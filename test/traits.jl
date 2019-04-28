using ImageCore, Colors, FixedPointNumbers, ColorVectorSpace, MappedArrays, OffsetArrays
using Test
using ImageCore: NumberLike, RealLike, FloatLike, FractionalLike, IntegerLike,
      GrayLike, GrayImageLike

@testset "Image traits" begin
    for (B, swap) in ((rand(UInt16(1):UInt16(20), 3, 5), false),
                      (rand(Gray{Float32}, 3, 5), false),
                      (rand(RGB{Float16}, 3, 5), false),
                      (bitrand(3, 5), false),
                      (rand(UInt32, 3, 5), false),
                      (view(rand(3, 2, 5), :, 1, :), false),
                      (OffsetArray(rand(3, 5), -1:1, -2:2), false),
                      (permuteddimsview(rand(5, 3), (2, 1)), true),
                      (mappedarray(identity, permuteddimsview(rand(5, 3), (2, 1))), true),
                      (colorview(RGB, zeros(3, 5), zeroarray, zeros(3, 5)), false))
        @test pixelspacing(B) == (1,1)
        if !isa(B, SubArray)
            @test spacedirections(B) == (swap ? ((0,1),(1,0)) : ((1,0),(0,1)))
        else
            @test spacedirections(B) == ((1,0,0), (0,0,1))
        end
        @test sdims(B) == 2
        @test coords_spatial(B) == (swap ? (2,1) : (1,2))
        @test nimages(B) == 1
        @test size_spatial(B) == (3,5)
        if isa(B, OffsetArray)
            @test indices_spatial(B) == (-1:1, -2:2)
        else
            @test indices_spatial(B) == (Base.OneTo(3), Base.OneTo(5))
        end
        assert_timedim_last(B)
        @test width(B) == 5
        @test height(B) == 3
    end
end

@testset "*Like traits" begin
    # delibrately written in a redundant way
    @testset "NumberLike" begin
        @test RealLike <: NumberLike
        @test FloatLike <: NumberLike
        @test FractionalLike <: NumberLike
        @test IntegerLike <: NumberLike

        @test Number <: NumberLike
        @test Real <: NumberLike
        @test AbstractFloat <: NumberLike
        @test FixedPoint <: NumberLike
        @test Integer <: NumberLike
        @test Bool <: NumberLike

        @test Gray <: NumberLike
        @test Gray{<:AbstractFloat} <: NumberLike
        @test Gray{<:Bool} <: NumberLike

        @test isa(oneunit(Gray), NumberLike)
    end

    @testset "RealLike" begin
        @test FloatLike <: RealLike
        @test FractionalLike <: RealLike
        @test IntegerLike <: RealLike

        @test Real <: RealLike
        @test AbstractFloat <: RealLike
        @test FixedPoint <: RealLike
        @test Integer <: RealLike
        @test Bool <: RealLike

        @test Gray{<:AbstractFloat} <: RealLike
        @test Gray{<:Bool} <: RealLike
        @test Gray{<:FixedPoint} <: RealLike

        @test isa(oneunit(Gray), RealLike)
    end

    @testset "FractionalLike" begin
        @test AbstractFloat <: FractionalLike
        @test FixedPoint <: FractionalLike

        @test !(Gray <: FractionalLike)
        @test Gray{<:AbstractFloat} <: FractionalLike
        @test Gray{<:FixedPoint} <: FractionalLike

        @test isa(oneunit(Gray), FractionalLike)
    end

    @testset "GrayLike" begin
        @test AbstractFloat <: GrayLike
        @test FixedPoint <: GrayLike
        @test Bool <: GrayLike

        @test Gray <: GrayLike
        @test Gray{<:AbstractFloat} <: GrayLike
        @test Gray{<:FixedPoint} <: GrayLike
        @test Gray{Bool} <: GrayLike

        @test isa(oneunit(Gray), GrayLike)
    end

    @testset "FloatLike" begin
        @test AbstractFloat <: FloatLike

        @test !(Gray <: FloatLike)
        @test Gray{<:AbstractFloat} <: FloatLike

        @test !isa(oneunit(Gray), FloatLike)
    end

    @testset "IntegerLike" begin
        @test Integer <: IntegerLike
        @test FixedPoint <: IntegerLike
        @test Bool <: IntegerLike

        @test !(Gray <: IntegerLike)
        @test Gray{<:Bool} <: IntegerLike
        @test Gray{<:FixedPoint} <: IntegerLike

        @test isa(oneunit(Gray), IntegerLike)
    end

    @testset "GrayImageLike" begin
        sz = (3,3)
        @test isa(rand(Bool, sz), GrayImageLike)
        @test isa(rand(N0f8, sz), GrayImageLike)
        @test isa(rand(Float32, sz), GrayImageLike)

        @test isa(rand(Gray, sz), GrayImageLike)
        @test isa(rand(Gray{Bool}, sz), GrayImageLike)
        @test isa(rand(Gray{N0f8}, sz), GrayImageLike)
        @test isa(rand(Gray{Float32}, sz), GrayImageLike)
    end
end

nothing
