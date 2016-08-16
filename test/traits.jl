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

@testset "Utilities" begin
    using ImagesCore.permutation
    @test permutation((1,2,3), (1,2,3)) == [1,2,3]
    @test permutation((3,1,2), (1,2,3)) == [3,1,2]
    @test permutation(["b", "c", "a"], ["a", "b", "c"]) == [2,3,1]
    @test_throws ArgumentError permutation(["b", "c", "a"], ["a", "bb", "c"])
    @test permutation(["b", "c", "a"], ["a", "bb", "b", "c"]) == [3,4,1,2]
    @test permutation(["a", "bb", "b", "c"], ["b", "c", "a"]) == [3,0,1,2]
    @test_throws ArgumentError permutation(["a", "b"], [:cat, :dog])
    @test_throws ArgumentError permutation(["a", "b"], ["a", "a", "b"])
end

nothing
