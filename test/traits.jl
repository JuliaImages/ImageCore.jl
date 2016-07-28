using ImagesCore, Colors, FixedPointNumbers, ColorVectorSpace
using Base.Test

@testset "Image traits" begin
    for (B,S) in ((rand(UInt16(1):UInt16(20), 3, 5),"Gray"),
                  (rand(Gray{Float32}, 3, 5),"Gray"),
                  (rand(RGB{Float16}, 3, 5),"RGB"),
                  (bitrand(3, 5),"Binary"),
                  (rand(UInt32, 3, 5),"RGB24"))
        @test pixelspacing(B) == (1,1)
        @test spacedirections(B) == ((1,0),(0,1))
        @test sdims(B) == 2
        @test coords_spatial(B) == (1,2)
        @test nimages(B) == 1
        @test size_spatial(B) == (3,5)
        @test indices_spatial(B) == (Base.OneTo(3), Base.OneTo(5))
        assert_timedim_last(B)
        @test width(B) == 3
        @test height(B) == 5
    end
end

nothing
