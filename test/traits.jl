using ImageCore, Colors, FixedPointNumbers, ColorVectorSpace, MappedArrays, OffsetArrays
using Test

@testset "Image traits" begin
    for (B, swap) in ((rand(UInt16(1):UInt16(20), 3, 5), false),
                      (rand(Gray{Float32}, 3, 5), false),
                      (rand(RGB{Float16}, 3, 5), false),
                      (bitrand(3, 5), false),
                      (rand(UInt32, 3, 5), false),
                      (view(rand(3, 2, 5), :, 1, :), false),
                      (OffsetArray(rand(3, 5), -1:1, -2:2), false),
                      (permuteddimsview(rand(5, 3), (2, 1)), true),
                      (mappedarray(identity, permuteddimsview(rand(5, 3), (2, 1))), true))
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

nothing
