using Colors, ImagesCore, Base.Test, BenchmarkTools

@testset "ChannelView" begin

@testset "color channel order" begin
    @test ImagesCore.colorperm(Gray)  == (1,)
    @test ImagesCore.colorperm(AGray) == (2,1)
    @test ImagesCore.colorperm(GrayA) == (1,2)

    @test ImagesCore.colorperm(RGB)  == (1,2,3)
    @test ImagesCore.colorperm(ARGB) == (2,3,4,1)
    @test ImagesCore.colorperm(RGBA) == (1,2,3,4)
    @test ImagesCore.colorperm(BGR)  == (3,2,1)
    @test ImagesCore.colorperm(ABGR) == (4,3,2,1)
    @test ImagesCore.colorperm(BGRA) == (3,2,1,4)

    @test ImagesCore.colorperm(HSV)   == (1,2,3)
    @test ImagesCore.colorperm(YCbCr) == (1,2,3)
    @test ImagesCore.colorperm(XYZA)  == (1,2,3,4)
    @test ImagesCore.colorperm(ALab)  == (2,3,4,1)
end

@testset "grayscale" begin
    a = [Gray(U8(0.2)), Gray(U8(0.4))]
    v = ChannelView(a)
    @test ndims(v) == 2 - ImagesCore.squeeze1
    @test size(v) == (ImagesCore.squeeze1 ? (2,) : (1, 2))
    @test eltype(v) == U8
    @test parent(v) === a
    @test v[1] == U8(0.2)
    @test v[2] == U8(0.4)
    @test_throws BoundsError v[0]
    @test_throws BoundsError v[3]
    v[1] = 0.8
    @test a[1] === Gray(U8(0.8))
    @test_throws BoundsError (v[0] = 0.6)
    @test_throws BoundsError (v[3] = 0.6)
    c = similar(v)
    @test isa(c, ChannelView{U8,1,Array{Gray{U8},1}})
    @test length(c) == 2
    c = similar(v, ImagesCore.squeeze1 ? 3 : (1,3))
    @test isa(c, ChannelView{U8,1,Array{Gray{U8},1}})
    @test length(c) == 3
    c = similar(v, Float32)
    @test isa(c, ChannelView{Float32,1,Array{Gray{Float32},1}})
    @test length(c) == 2
    c = similar(v, Float16, ImagesCore.squeeze1 ? (5,5) : (1,5,5))
    @test isa(c, ChannelView{Float16,2,Array{Gray{Float16},2}})
    @test size(c) == (ImagesCore.squeeze1 ? (5,5) : (1,5,5))
end

@testset "RGB, HSV, etc" begin
    for T in (RGB, BGR, RGB1, RGB4, HSV, Lab, XYZ)
        a = [T(0.1,0.2,0.3), T(0.4, 0.5, 0.6)]
        v = ChannelView(a)
        @test ndims(v) == 2
        @test size(v) == (3,2)
        @test eltype(v) == Float64
        @test parent(v) === a
        @test v[1] == v[1,1] == 0.1
        @test v[2] == v[2,1] == 0.2
        @test v[3] == v[3,1] == 0.3
        @test v[4] == v[1,2] == 0.4
        @test v[5] == v[2,2] == 0.5
        @test v[6] == v[3,2] == 0.6
        @test_throws BoundsError v[0,1]
        @test_throws BoundsError v[4,1]
        @test_throws BoundsError v[2,0]
        @test_throws BoundsError v[2,3]
        v[2] = 0.8
        @test a[1] == T(0.1,0.8,0.3)
        v[2,1] = 0.7
        @test a[1] == T(0.1,0.7,0.3)
        @test_throws BoundsError (v[0,1] = 0.7)
        @test_throws BoundsError (v[4,1] = 0.7)
        @test_throws BoundsError (v[2,0] = 0.7)
        @test_throws BoundsError (v[2,3] = 0.7)
        c = similar(v)
        @test isa(c, ChannelView{Float64,2,Array{T{Float64},1}})
        @test size(c) == (3,2)
        c = similar(v, (3,4))
        @test isa(c, ChannelView{Float64,2,Array{T{Float64},1}})
        @test size(c) == (3,4)
        @test_throws DimensionMismatch similar(v, (5,4))
        c = similar(v, Float32)
        @test isa(c, ChannelView{Float32,2,Array{T{Float32},1}})
        @test size(c) == (3,2)
        c = similar(v, Float16, (3,5,5))
        @test isa(c, ChannelView{Float16,3,Array{T{Float16},2}})
        @test size(c) == (3,5,5)
        @test_throws DimensionMismatch similar(v, Float16, (2,5,5))
    end
end

@testset "Gray+Alpha" begin
    for T in (AGray,GrayA)
        a = [T(0.1f0,0.2f0), T(0.3f0,0.4f0), T(0.5f0,0.6f0)]
        v = ChannelView(a)
        @test ndims(v) == 2
        @test size(v) == (2,3)
        @test eltype(v) == Float32
        @test parent(v) === a
        @test v[1] == v[1,1] == 0.1f0
        @test v[2] == v[2,1] == 0.2f0
        @test v[3] == v[1,2] == 0.3f0
        @test v[4] == v[2,2] == 0.4f0
        @test v[5] == v[1,3] == 0.5f0
        @test v[6] == v[2,3] == 0.6f0
        @test_throws BoundsError v[0,1]
        @test_throws BoundsError v[3,1]
        @test_throws BoundsError v[2,0]
        @test_throws BoundsError v[2,4]
        v[2] = 0.8
        @test a[1] == T(0.1f0,0.8f0)
        v[2,1] = 0.7
        @test a[1] == T(0.1f0,0.7f0)
        @test_throws BoundsError (v[0,1] = 0.7)
        @test_throws BoundsError (v[3,1] = 0.7)
        @test_throws BoundsError (v[2,0] = 0.7)
        @test_throws BoundsError (v[2,4] = 0.7)
        c = similar(v)
        @test isa(c, ChannelView{Float32,2,Array{T{Float32},1}})
        @test size(c) == (2,3)
        c = similar(v, (2,4))
        @test isa(c, ChannelView{Float32,2,Array{T{Float32},1}})
        @test size(c) == (2,4)
        @test_throws DimensionMismatch similar(v, (3,4))
        c = similar(v, Float64)
        @test isa(c, ChannelView{Float64,2,Array{T{Float64},1}})
        @test size(c) == (2,3)
        c = similar(v, Float16, (2,5,5))
        @test isa(c, ChannelView{Float16,3,Array{T{Float16},2}})
        @test size(c) == (2,5,5)
        @test_throws DimensionMismatch similar(v, Float16, (3,5,5))
    end
end

@testset "Alpha+RGB, HSV, etc" begin
    for T in (ARGB, ABGR, AHSV, ALab, AXYZ,
              RGBA, BGRA, HSVA, LabA, XYZA)
        a = [T(0.1,0.2,0.3,0.4), T(0.5,0.6,0.7,0.8)]
        v = ChannelView(a)
        @test ndims(v) == 2
        @test size(v) == (4,2)
        @test eltype(v) == Float64
        @test parent(v) === a
        @test v[1] == v[1,1] == 0.1
        @test v[2] == v[2,1] == 0.2
        @test v[3] == v[3,1] == 0.3
        @test v[4] == v[4,1] == 0.4
        @test v[5] == v[1,2] == 0.5
        @test v[6] == v[2,2] == 0.6
        @test v[7] == v[3,2] == 0.7
        @test v[8] == v[4,2] == 0.8
        @test_throws BoundsError v[0,1]
        @test_throws BoundsError v[5,1]
        @test_throws BoundsError v[2,0]
        @test_throws BoundsError v[2,3]
        v[2] = 0.9
        @test a[1] == T(0.1,0.9,0.3,0.4)
        v[2,1] = 0.7
        @test a[1] == T(0.1,0.7,0.3,0.4)
        @test_throws BoundsError (v[0,1] = 0.7)
        @test_throws BoundsError (v[5,1] = 0.7)
        @test_throws BoundsError (v[2,0] = 0.7)
        @test_throws BoundsError (v[2,3] = 0.7)
        c = similar(v)
        @test isa(c, ChannelView{Float64,2,Array{T{Float64},1}})
        @test size(c) == (4,2)
        c = similar(v, (4,4))
        @test isa(c, ChannelView{Float64,2,Array{T{Float64},1}})
        @test size(c) == (4,4)
        @test_throws DimensionMismatch similar(v, (5,4))
        c = similar(v, Float32)
        @test isa(c, ChannelView{Float32,2,Array{T{Float32},1}})
        @test size(c) == (4,2)
        c = similar(v, Float16, (4,5,5))
        @test isa(c, ChannelView{Float16,3,Array{T{Float16},2}})
        @test size(c) == (4,5,5)
        @test_throws DimensionMismatch similar(v, Float16, (3,5,5))
    end
end

end

@testset "ColorView" begin

@testset "grayscale" begin
    _a = [U8(0.2), U8(0.4)]
    a = ImagesCore.squeeze1 ? _a : reshape(_a, (1, 2))
    v = ColorView{Gray}(a)
    @test ndims(v) == 1
    @test size(v) == (2,)
    @test eltype(v) == Gray{U8}
    @test parent(v) === a
    @test v[1] == Gray(U8(0.2))
    @test v[2] == Gray(U8(0.4))
    @test_throws BoundsError v[0]
    @test_throws BoundsError v[3]
    v[1] = 0.8
    @test _a[1] === U8(0.8)
    @test_throws BoundsError (v[0] = 0.6)
    @test_throws BoundsError (v[3] = 0.6)
    c = similar(v)
    @test isa(c, ColorView{Gray{U8},1,Array{U8,1}})
    @test length(c) == 2
    c = similar(v, ImagesCore.squeeze1 ? 3 : (1,3))
    @test isa(c, ColorView{Gray{U8},1,Array{U8,1}})
    @test length(c) == 3
    c = similar(v, Gray{Float32})
    @test isa(c, ColorView{Gray{Float32},1,Array{Float32,1}})
    @test length(c) == 2
    c = similar(v, Gray{Float16}, ImagesCore.squeeze1 ? (5,5) : (1,5,5))
    @test isa(c, ColorView{Gray{Float16},2,Array{Float16,2}})
    @test size(c) == (ImagesCore.squeeze1 ? (5,5) : (1,5,5))
end

@testset "RGB, HSV, etc" begin
    for T in (RGB, BGR, RGB1, RGB4, HSV, Lab, XYZ)
        a = [0.1 0.2 0.3; 0.4 0.5 0.6]'
        v = ColorView{T}(a)
        @test ndims(v) == 1
        @test size(v) == (2,)
        @test eltype(v) == T{Float64}
        @test parent(v) === a
        @test v[1] == T(0.1,0.2,0.3)
        @test v[2] == T(0.4,0.5,0.6)
        @test_throws BoundsError v[0]
        @test_throws BoundsError v[3]
        v[2] = T(0.8, 0.7, 0.6)
        @test a == [0.1 0.2 0.3; 0.8 0.7 0.6]'
        @test_throws BoundsError (v[0] = T(0.8, 0.7, 0.6))
        @test_throws BoundsError (v[3] = T(0.8, 0.7, 0.6))
        c = similar(v)
        @test isa(c, ColorView{T{Float64},1,Array{Float64,2}})
        @test size(c) == (2,)
        c = similar(v, 4)
        @test isa(c, ColorView{T{Float64},1,Array{Float64,2}})
        @test size(c) == (4,)
        c = similar(v, T{Float32})
        @test isa(c, ColorView{T{Float32},1,Array{Float32,2}})
        @test size(c) == (2,)
        c = similar(v, T{Float16}, (5,5))
        @test isa(c, ColorView{T{Float16},2,Array{Float16,3}})
        @test size(c) == (5,5)
    end
end

@testset "Gray+Alpha" begin
    for T in (AGray,GrayA)
        a = [0.1f0 0.2f0; 0.3f0 0.4f0; 0.5f0 0.6f0]'
        v = ColorView{T}(a)
        @test ndims(v) == 1
        @test size(v) == (3,)
        @test eltype(v) == T{Float32}
        @test parent(v) === a
        @test v[1] == T(0.1f0, 0.2f0)
        @test v[2] == T(0.3f0, 0.4f0)
        @test v[3] == T(0.5f0, 0.6f0)
        @test_throws BoundsError v[0]
        @test_throws BoundsError v[4]
        v[2] = T(0.8, 0.7)
        @test a[1,2] === 0.8f0
        @test a[2,2] === 0.7f0
        @test_throws BoundsError (v[0] = T(0.8,0.7))
        @test_throws BoundsError (v[4] = T(0.8,0.7))
        c = similar(v)
        @test isa(c, ColorView{T{Float32},1,Array{Float32,2}})
        @test size(c) == (3,)
        c = similar(v, (4,))
        @test isa(c, ColorView{T{Float32},1,Array{Float32,2}})
        @test size(c) == (4,)
        c = similar(v, T{Float64})
        @test isa(c, ColorView{T{Float64},1,Array{Float64,2}})
        @test size(c) == (3,)
        c = similar(v, T{Float16}, (5,5))
        @test isa(c, ColorView{T{Float16},2,Array{Float16,3}})
        @test size(c) == (5,5)
    end
end

@testset "Alpha+RGB, HSV, etc" begin
    for T in (ARGB, ABGR, AHSV, ALab, AXYZ,
              RGBA, BGRA, HSVA, LabA, XYZA)
        a = [0.1 0.2 0.3 0.4; 0.5 0.6 0.7 0.8]'
        v = ColorView{T}(a)
        @test ndims(v) == 1
        @test size(v) == (2,)
        @test eltype(v) == T{Float64}
        @test parent(v) === a
        @test v[1] == T(0.1,0.2,0.3,0.4)
        @test v[2] == T(0.5,0.6,0.7,0.8)
        @test_throws BoundsError v[0]
        @test_throws BoundsError v[3]
        v[2] = T(0.9,0.8,0.7,0.6)
        @test a[1,2] == 0.9
        @test a[2,2] == 0.8
        @test a[3,2] == 0.7
        @test a[4,2] == 0.6
        @test_throws BoundsError (v[0] = T(0.9,0.8,0.7,0.6))
        @test_throws BoundsError (v[3] = T(0.9,0.8,0.7,0.6))
        c = similar(v)
        @test isa(c, ColorView{T{Float64},1,Array{Float64,2}})
        @test size(c) == (2,)
        c = similar(v, 4)
        @test isa(c, ColorView{T{Float64},1,Array{Float64,2}})
        @test size(c) == (4,)
        c = similar(v, T{Float32})
        @test isa(c, ColorView{T{Float32},1,Array{Float32,2}})
        @test size(c) == (2,)
        c = similar(v, T{Float16}, (5,5))
        @test isa(c, ColorView{T{Float16},2,Array{Float16,3}})
        @test size(c) == (5,5)
    end
end

end
