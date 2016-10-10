# some views are in colorchannels.jl
using Colors, ImageCore, Base.Test

@testset "rawview" begin
    a = map(U8, rand(3,5))
    a[2,2] = U8(0.5)
    v = rawview(a)
    @test v[2,2] === a[2,2].i
    v[1,3] = 0xff
    @test a[1,3] === U8(1)
    v[1,3] = 0x01
    @test a[1,3] === U8(1/255)
    s = view(a, 1:2, 1:2)
    v = rawview(s)
    @test v[2,2] === a[2,2].i
    v[2,2] = 0x0f
    @test a[2,2].i == 0x0f
    @test rawview(v) === v
end

@testset "ufixedview" begin
    a = rand(UInt8, 3, 5)
    a[2,2] = 0x80
    v = ufixedview(a)
    @test v[2,2] === U8(0.5)
    v[1,3] = 1
    @test a[1,3] === 0xff
    v[1,3] = 1/255
    @test a[1,3] === 0x01
    s = view(a, 1:2, 1:2)
    v = ufixedview(s)
    @test v[2,2] === U8(0.5)
    v[2,2] = 15/255
    @test a[2,2] == 0x0f
    @test ufixedview(v) === v
    @test ufixedview(U8, v) === v
end

@testset "permuteddimsview" begin
    a = [1 3; 2 4]
    v = permuteddimsview(a, (1,2))
    @test v == a
    v = permuteddimsview(a, (2,1))
    @test v == a'
    a = rand(3,7,5)
    v = permuteddimsview(a, (2,3,1))
    @test v == permutedims(a, (2,3,1))
end

@testset "StackedView" begin
    for (A, B, T) = (([1 3;2 4], [-1 -5; -2 -3], Int),
                     ([1 3;2 4], [-1.0 -5.0; -2.0 -3.0], Float64))
        V = @inferred(StackedView(A, B))
        @test eltype(V) == T
        @test size(V) == (2, 2, 2)
        @test indices(V) === (Base.OneTo(2), Base.OneTo(2), Base.OneTo(2))
        @test @inferred(V[1,1,1]) === T(1)
        @test @inferred(V[2,1,1]) === T(-1)
        @test V[1,:,:] == A
        @test V[2,:,:] == B
        @test_throws BoundsError V[0,1,1]
        @test_throws BoundsError V[3,1,1]
        @test_throws BoundsError V[2,0,1]
        @test_throws BoundsError V[2,3,1]
        @test_throws BoundsError V[1,1,0]
        @test_throws BoundsError V[1,1,3]
        V32 = @inferred(StackedView{Float32}(A, B))
        @test eltype(V32) == Float32
        @test V32[1,1,2] == Float32(3)
        V[1,2,2] = 0
        @test A[2,2] == 0
        V[2,1,2] = 11
        @test B[1,2] == 11

        V = @inferred(StackedView(A, zeroarray, B))
        @test eltype(V) == T
        @test size(V) == (3, 2, 2)
        @test indices(V) === (Base.OneTo(3), Base.OneTo(2), Base.OneTo(2))
        @test V[1,:,:] == A
        @test all(V[2,:,:] .== 0)
        @test V[3,:,:] == B
        @test_throws ErrorException V[2,1,1] = 7
        V32 = @inferred(StackedView{Float32}(A, zeroarray, B))
        @test eltype(V32) == Float32
        @test V32[1,1,2] == Float32(3)
    end

    # With mixed grayscale/real arrays
    a, b = Gray{U8}[0.1 0.2; 0.3 0.4], [0.5 0.6; 0.7 0.8]
    V = @inferred(StackedView(a, b))
    @test eltype(V) == Float64
    @test V[1,1,1] === Float64(U8(0.1))
    @test V[2,1,1] === 0.5
    V = @inferred(StackedView{U8}(a, b))
    @test eltype(V) == U8
    @test V[1,1,1] === U8(0.1)
    @test V[2,1,1] === U8(0.5)
    @test b[1,1] === 0.5
    V = @inferred(StackedView(a, zeroarray, b))
    @test eltype(V) == Float64
    V = @inferred(StackedView{U8}(a, zeroarray, b))
    @test eltype(V) == U8

    # With colorview
    a = [0.1 0.2; 0.3 0.4]
    b = [0.5 0.6; 0.7 0.8]
    v = @inferred(colorview(RGB{U8}, a, zeroarray, b))
    @test @inferred(v[2,1]) === RGB{U8}(0.3,0,0.7)
    z = zeros(2,2)  # because setindex! won't work with zeroarray
    v = colorview(RGB{U8}, a, z, b)
    @test @inferred(v[2,1]) === RGB{U8}(0.3,0,0.7)
    v[2,1] = RGB(0,0.9,0)
    @test @inferred(v[2,1]) === RGB{U8}(0,0.9,0)
    @test a[2,1] == b[2,1] == 0
    @test z[2,1] == U8(0.9)

    @test_throws DimensionMismatch StackedView(rand(2,3), rand(2,5))
end

nothing
