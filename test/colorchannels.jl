using Colors, ImageCore, OffsetArrays, FixedPointNumbers, Base.Test
using Compat

struct ArrayLF{T,N} <: AbstractArray{T,N}
    A::Array{T,N}
end
@compat Base.IndexStyle{A<:ArrayLF}(::Type{A}) = IndexLinear()
Base.size(A::ArrayLF) = size(A.A)
Base.getindex(A::ArrayLF, i::Int) = A.A[i]
Base.setindex!(A::ArrayLF, val, i::Int) = A.A[i] = val

struct ArrayLS{T,N} <: AbstractArray{T,N}
    A::Array{T,N}
end
@compat Base.IndexStyle{A<:ArrayLS}(::Type{A}) = IndexCartesian()
Base.size(A::ArrayLS) = size(A.A)
Base.getindex{T,N}(A::ArrayLS{T,N}, i::Vararg{Int,N}) = A.A[i...]
Base.setindex!{T,N}(A::ArrayLS{T,N}, val, i::Vararg{Int,N}) = A.A[i...] = val

@testset "ChannelView" begin

@testset "grayscale" begin
    a = rand(2,3)
    @test channelview(a) === a

    a0 = [Gray(N0f8(0.2)), Gray(N0f8(0.4))]
    for (a, VT, LI) in ((copy(a0), Array, IndexLinear()),
                       (ArrayLF(copy(a0)), ChannelView, IndexLinear()),
                       (ArrayLS(copy(a0)), ChannelView, IndexCartesian()))
        v = ChannelView(a)
        @test isa(channelview(a), VT)
        @test IndexStyle(v) == LI
        @test isa(colorview(Gray, v), typeof(a))
        @test ndims(v) == 2 - ImageCore.squeeze1
        @test size(v) == (ImageCore.squeeze1 ? (2,) : (1, 2))
        @test eltype(v) == N0f8
        @test parent(v) === a
        @test v[1] == N0f8(0.2)
        @test v[2] == N0f8(0.4)
        @test_throws BoundsError v[0]
        @test_throws BoundsError v[3]
        v[1] = 0.8
        @test a[1] === Gray(N0f8(0.8))
        @test_throws BoundsError (v[0] = 0.6)
        @test_throws BoundsError (v[3] = 0.6)
        c = similar(v)
        @test isa(c, ChannelView{N0f8,1,Array{Gray{N0f8},1}})
        @test length(c) == 2
        c = similar(v, ImageCore.squeeze1 ? 3 : (1,3))
        @test isa(c, ChannelView{N0f8,1,Array{Gray{N0f8},1}})
        @test length(c) == 3
        c = similar(v, Float32)
        @test isa(c, ChannelView{Float32,1,Array{Gray{Float32},1}})
        @test length(c) == 2
        c = similar(v, Float16, ImageCore.squeeze1 ? (5,5) : (1,5,5))
        @test isa(c, ChannelView{Float16,2,Array{Gray{Float16},2}})
        @test size(c) == (ImageCore.squeeze1 ? (5,5) : (1,5,5))
    end
end

@testset "RGB, HSV, etc" begin
    for T in (RGB, BGR, RGB1, RGB4, HSV, Lab, XYZ)
        a0 = [T(0.1,0.2,0.3), T(0.4, 0.5, 0.6)]
        for (a, VT) in ((copy(a0), T<:Union{BGR,RGB1,RGB4} ? ChannelView : Array),
                        (ArrayLS(copy(a0)), ChannelView))
            v = ChannelView(a)
            @test isa(channelview(a), VT)
            @test isa(colorview(T, v), typeof(a))
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
    a = reshape([RGB(1,0,0)])  # 0-dimensional
    v = channelview(a)
    @test indices(v) === (Base.OneTo(3),)
    v = ChannelView(a)
    @test indices(v) === (Base.OneTo(3),)
end

@testset "Gray+Alpha" begin
    for (T,VT) in ((AGray,ChannelView),(GrayA,Array))
        a = [T(0.1f0,0.2f0), T(0.3f0,0.4f0), T(0.5f0,0.6f0)]
        v = ChannelView(a)
        @test isa(channelview(a), VT)
        @test isa(colorview(T, v), Array)
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
    for (T, VT) in ((ARGB, ChannelView),
                    (ABGR, ChannelView),
                    (AHSV, ChannelView),
                    (ALab, ChannelView),
                    (AXYZ, ChannelView),
                    (RGBA, Array),
                    (BGRA, ChannelView),
                    (HSVA, Array),
                    (LabA, Array),
                    (XYZA, Array))
        a = [T(0.1,0.2,0.3,0.4), T(0.5,0.6,0.7,0.8)]
        v = ChannelView(a)
        @test isa(channelview(a), VT)
        @test isa(colorview(T, v), Array)
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

    @testset "Non-1 indices" begin
        a = OffsetArray(rand(RGB{N0f8}, 3, 5), -1:1, -2:2)
        v = channelview(a)
        @test @inferred(indices(v)) === (1:3, -1:1, -2:2)
        @test @inferred(v[1,0,0]) === a[0,0].r
        a = OffsetArray(rand(Gray{Float32}, 3, 5), -1:1, -2:2)
        v = channelview(a)
        @test @inferred(indices(v)) === (-1:1, -2:2)
        @test @inferred(v[0,0]) === gray(a[0,0])
        @test @inferred(v[5]) === gray(a[5])
        v[5] = -1
        @test v[5] === -1.0f0
    end
end

end

@testset "ColorView" begin

@testset "grayscale" begin
    _a0 = [N0f8(0.2), N0f8(0.4)]
    a0 = ImageCore.squeeze1 ? _a0 : reshape(_a0, (1, 2))
    for (a, VT, LI) in ((copy(a0), Array{Gray{N0f8}}, IndexLinear()),
                        (ArrayLF(copy(a0)), ColorView{Gray{N0f8}}, IndexLinear()),
                        (ArrayLS(copy(a0)), ColorView{Gray{N0f8}}, IndexCartesian()))
        @test_throws ErrorException ColorView(a)
        v = ColorView{Gray}(a)
        @test isa(colorview(Gray,a), VT)
        @test IndexStyle(v) == LI
        @test isa(channelview(v), typeof(a))
        @test ndims(v) == 1
        @test size(v) == (2,)
        @test eltype(v) == Gray{N0f8}
        @test parent(v) === a
        @test v[1] == Gray(N0f8(0.2))
        @test v[2] == Gray(N0f8(0.4))
        @test_throws BoundsError v[0]
        @test_throws BoundsError v[3]
        v[1] = 0.8
        @test a[1] === N0f8(0.8)
        @test_throws BoundsError (v[0] = 0.6)
        @test_throws BoundsError (v[3] = 0.6)
        c = similar(v)
        @test isa(c, ColorView{Gray{N0f8},1,Array{N0f8,1}})
        @test length(c) == 2
        c = similar(v, ImageCore.squeeze1 ? 3 : (1,3))
        @test isa(c, ColorView{Gray{N0f8},1,Array{N0f8,1}})
        @test length(c) == 3
        c = similar(v, Gray{Float32})
        @test isa(c, ColorView{Gray{Float32},1,Array{Float32,1}})
        @test length(c) == 2
        c = similar(v, Gray{Float16}, ImageCore.squeeze1 ? (5,5) : (1,5,5))
        @test isa(c, ColorView{Gray{Float16},2,Array{Float16,2}})
        @test size(c) == (ImageCore.squeeze1 ? (5,5) : (1,5,5))
        c = similar(v, Float32)
        @test isa(c, Array{Float32, 1})
    end
    # two dimensional images and linear indexing
    _a0 = N0f8[0.2 0.4; 0.6 0.8]
    a0 = ImageCore.squeeze1 ? _a0 : reshape(_a0, (1, 2, 2))
    for (a, VT, LI) in ((copy(a0), Array{Gray{N0f8}}, IndexLinear()),
                        (ArrayLF(copy(a0)), ColorView{Gray{N0f8}}, IndexLinear()),
                        (ArrayLS(copy(a0)), ColorView{Gray{N0f8}}, IndexCartesian()))
        @test_throws ErrorException ColorView(a)
        v = ColorView{Gray}(a)
        @test isa(colorview(Gray,a), VT)
        @test IndexStyle(v) == LI
        @test isa(channelview(v), typeof(a))
        @test ndims(v) == 2
        @test size(v) == (2,2)
        @test eltype(v) == Gray{N0f8}
        @test parent(v) === a
        @test v[1] == Gray(N0f8(0.2))
        @test v[2] == Gray(N0f8(0.6))
        @test_throws BoundsError v[0]
        @test_throws BoundsError v[5]
        v[1] = 0.9
        @test a[1] === N0f8(0.9)
        @test_throws BoundsError (v[0] = 0.6)
        @test_throws BoundsError (v[5] = 0.6)
    end
end

@testset "RGB, HSV, etc" begin
    for T in (RGB, BGR, RGB1, RGB4, HSV, Lab, XYZ)
        a0 = [0.1 0.2 0.3; 0.4 0.5 0.6]'
        for (a, VT) in ((copy(a0), T<:Union{BGR,RGB1,RGB4} ? ColorView : Array),
                        (ArrayLS(copy(a0)), ColorView))
            @test_throws ErrorException ColorView(a)
            v = ColorView{T}(a)
            @test isa(@inferred(colorview(T,a)), VT)
            @test isa(@inferred(channelview(v)), typeof(a))
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
            c = similar(v, T)
            @test isa(c, ColorView{T{Float64},1,Array{Float64,2}})
            @test size(c) == (2,)
            c = similar(v, T{Float16}, (5,5))
            @test isa(c, ColorView{T{Float16},2,Array{Float16,3}})
            @test size(c) == (5,5)
            c = similar(v, RGB24)
            @test eltype(c) == RGB24
            @test size(c) == size(v)
        end
    end
    a = rand(ARGB{N0f8}, 5, 5)
    vc = channelview(a)
    @test isa(colorview(ARGB, vc), Array{ARGB{N0f8},2})
    cvc = colorview(RGBA, vc)
    @test all(cvc .== a)
end

@testset "Gray+Alpha" begin
    for (T,VT) in ((AGray,ColorView),(GrayA,Array))
        a = [0.1f0 0.2f0; 0.3f0 0.4f0; 0.5f0 0.6f0]'
        v = ColorView{T}(a)
        @test isa(colorview(T,a), VT{T{Float32}})
        @test isa(channelview(v), Array)
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
    for (T,VT) in ((ARGB, ColorView),
                   (ABGR, ColorView),
                   (AHSV, ColorView),
                   (ALab, ColorView),
                   (AXYZ, ColorView),
                   (RGBA, Array),
                   (BGRA, ColorView),
                   (HSVA, Array),
                   (LabA, Array),
                   (XYZA, Array))
        a = [0.1 0.2 0.3 0.4; 0.5 0.6 0.7 0.8]'
        v = ColorView{T}(a)
        @test isa(colorview(T,a), VT{T{Float64}})
        @test isa(channelview(v), Array)
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

    @testset "Non-1 indices" begin
        a = OffsetArray(rand(3, 3, 5), 1:3, -1:1, -2:2)
        v = colorview(RGB, a)
        @test @inferred(indices(v)) === (-1:1, -2:2)
        @test @inferred(v[0,0]) === RGB(a[1,0,0], a[2,0,0], a[3,0,0])
        a = OffsetArray(rand(3, 3, 5), 0:2, -1:1, -2:2)
        @test_throws DimensionMismatch colorview(RGB, a)
    end
end

end

nothing
