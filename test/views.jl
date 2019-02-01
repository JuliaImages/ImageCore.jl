# some views are in colorchannels.jl
using Colors, FixedPointNumbers, ImageCore, OffsetArrays, Test
using OffsetArrays: IdentityUnitRange

@testset "rawview" begin
    a = map(N0f8, rand(3,5))
    a[2,2] = N0f8(0.5)
    v = rawview(a)
    @test v[2,2] === a[2,2].i
    v[1,3] = 0xff
    @test a[1,3] === N0f8(1)
    v[1,3] = 0x01
    @test a[1,3] === N0f8(1/255)
    s = view(a, 1:2, 1:2)
    v = rawview(s)
    @test v[2,2] === a[2,2].i
    v[2,2] = 0x0f
    @test a[2,2].i == 0x0f
    @test rawview(v) === v
end

@testset "normedview" begin
    a = rand(UInt8, 3, 5)
    a[2,2] = 0x80
    v = normedview(a)
    @test v[2,2] === N0f8(0.5)
    v[1,3] = 1
    @test a[1,3] === 0xff
    v[1,3] = 1/255
    @test a[1,3] === 0x01
    s = view(a, 1:2, 1:2)
    v = normedview(s)
    @test v[2,2] === N0f8(0.5)
    v[2,2] = 15/255
    @test a[2,2] == 0x0f
    @test normedview(v) === v
    @test normedview(N0f8, v) === v
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
        @test axes(V) === (Base.OneTo(2), Base.OneTo(2), Base.OneTo(2))
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
        @test axes(V) === (Base.OneTo(3), Base.OneTo(2), Base.OneTo(2))
        @test V[1,:,:] == A
        @test all(V[2,:,:] .== 0)
        @test V[3,:,:] == B
        @test_throws ErrorException V[2,1,1] = 7
        V32 = @inferred(StackedView{Float32}(A, zeroarray, B))
        @test eltype(V32) == Float32
        @test V32[1,1,2] == Float32(3)
    end

    # With mixed grayscale/real arrays
    a, b = Gray{N0f8}[0.1 0.2; 0.3 0.4], [0.5 0.6; 0.7 0.8]
    V = @inferred(StackedView(a, b))
    @test eltype(V) == Float64
    @test V[1,1,1] === Float64(N0f8(0.1))
    @test V[2,1,1] === 0.5
    V = @inferred(StackedView{N0f8}(a, b))
    @test eltype(V) == N0f8
    @test V[1,1,1] === N0f8(0.1)
    @test V[2,1,1] === N0f8(0.5)
    @test b[1,1] === 0.5
    V = @inferred(StackedView(a, zeroarray, b))
    @test eltype(V) == Float64
    V = @inferred(StackedView{N0f8}(a, zeroarray, b))
    @test eltype(V) == N0f8

    # With colorview
    a = [0.1 0.2; 0.3 0.4]
    b = [0.5 0.6; 0.7 0.8]
    z = zeros(2,2)  # because setindex! won't work with zeroarray
    # GrayA
    v = @inferred(colorview(GrayA, a, b))
    @test eltype(v) == GrayA{Float64}
    @test @inferred(v[2,1]) === GrayA(0.3,0.7)
    v = @inferred(colorview(GrayA{N0f8}, a, b))
    @test @inferred(v[2,1]) === GrayA{N0f8}(0.3,0.7)
    v[1,2] = GrayA(0.25, 0.25)
    @test @inferred(v[1,2]) === GrayA{N0f8}(0.25, 0.25)
    v = @inferred(colorview(GrayA{N0f8}, a, zeroarray))
    @test @inferred(v[2,1]) === GrayA{N0f8}(0.3,0)
    @test_throws ErrorException (v[1,2] = GrayA(0.25, 0.25))
    # RGB
    v = @inferred(colorview(RGB{N0f8}, a, zeroarray, b))
    @test @inferred(v[2,1]) === RGB{N0f8}(0.3,0,0.7)
    v = colorview(RGB{N0f8}, a, z, b)
    @test @inferred(v[2,1]) === RGB{N0f8}(0.3,0,0.7)
    v[2,1] = RGB(0,0.9,0)
    @test @inferred(v[2,1]) === RGB{N0f8}(0,0.9,0)
    @test a[2,1] == b[2,1] == 0
    @test z[2,1] == N0f8(0.9)
    # RGBA
    v = @inferred(colorview(RGBA{N0f8}, a, zeroarray, b, b))
    @test @inferred(v[2,2]) === RGBA{N0f8}(0.4,0,0.8,0.8)
    v = colorview(RGBA{N0f8}, a, copy(z), b, copy(z))
    v[2,2] = RGBA(0.75,0.8,0.75,0.8)
    @test @inferred(v[2,2]) === RGBA{N0f8}(0.75,0.8,0.75,0.8)
    @test a[2,2] == b[2,2] == N0f8(0.75)

    @test eltype(zeroarray) == Union{}
    @test_throws ErrorException colorview(RGB{N0f8}, zeroarray, zeroarray, zeroarray)
    @test_throws DimensionMismatch StackedView(rand(2,3), rand(2,5))

    # With padding
    r = reshape([0.1,0.2], 2, 1)
    g = [false true]
    cv = colorview(RGB, paddedviews(0, r, g, zeroarray)...)
    @test cv[1,1] === RGB(0.1,0,0)
    @test cv[2,1] === RGB(0.2,0,0)
    @test cv[1,2] === RGB(0,1.0,0)
    @test cv[2,2] === RGB(0,0.0,0)
    @test axes(cv) === (Base.OneTo(2), Base.OneTo(2))

    a = [0.1 0.2; 0.3 0.4]
    b = OffsetArray([0.1 0.2; 0.3 0.4], 0:1, 2:3)
    @test_throws DimensionMismatch colorview(RGB, a, b, zeroarray)
    cv = colorview(RGB, paddedviews(0, a, b, zeroarray)...)
    @test axes(cv) == (0:2, 1:3)
    @test red.(cv[axes(a)...]) == a
    @test green.(cv[axes(b)...]) == b
    @test parent(copy(cv)) == [RGB(0,0,0)   RGB(0,0.1,0)   RGB(0,0.2,0);
                               RGB(0.1,0,0) RGB(0.2,0.3,0) RGB(0,0.4,0);
                               RGB(0.3,0,0) RGB(0.4,0,0)   RGB(0,0,0)]
    chanv = channelview(cv)
    @test @inferred(axes(chanv)) === (IdentityUnitRange(1:3), IdentityUnitRange(0:2), IdentityUnitRange(1:3))
    @test chanv[1,1,1] == 0.1
    @test chanv[2,1,2] == 0.3

    @test_throws ErrorException paddedviews(0, zeroarray, zeroarray)

    # Just to boost coverage. These methods are necessary to
    # make inference happy.
    @test_throws ErrorException ImageCore._unsafe_getindex(1, (1,1))
    @test_throws ErrorException ImageCore._unsafe_setindex!(1, (1,1), 0)
end

@testset "Multi-component colorview" begin
    r, g, b = rand(Gray{N0f16},5,5), rand(Gray{N0f16},5,5), rand(Gray{N0f16},5,5)
    A = colorview(RGB, r, g, b)
    @test A[1,1] == RGB(r[1,1], g[1,1], b[1,1])
    o = ones(2, 2)
    A = colorview(RGB, o, o, zeroarray)
    @test A[1,1] == RGB(1,1,0)
    @test size(A) == (2,2)
    @test axes(A) == (Base.OneTo(2),Base.OneTo(2))
    A = colorview(RGB, o, zeroarray, o)
    @test A[1,1] == RGB(1,0,1)
    @test size(A) == (2,2)
    @test axes(A) == (Base.OneTo(2),Base.OneTo(2))
    A = colorview(RGB, zeroarray, o, o)
    @test A[1,1] == RGB(0,1,1)
    @test size(A) == (2,2)
    @test axes(A) == (Base.OneTo(2),Base.OneTo(2))
end

nothing
