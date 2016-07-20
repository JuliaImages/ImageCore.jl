using ImagesCore, Colors, ColorVectorSpace, FixedPointNumbers
using Base.Test

@testset "reinterpret" begin
    a = rand(Gray{U8}, (4,5))
    for T in (Gray{U8}, Gray{Float32}, Gray{Float64})
        b = @inferred(convert(Array{T}, a))
        rb = @inferred(reinterpret(eltype(T), b))
        if ImagesCore.squeeze1
            @test isa(rb, Array{eltype(T),2})
            @test size(rb) == (4,5)
        else
            @test isa(rb, Array{eltype(T),3})
            @test size(rb) == (1,4,5)
        end
        c = copy(rb)
        rc = @inferred(reinterpret(T, c))
        @test isa(rc, Array{T,2})
        @test size(rc) == (4,5)
    end
    a = rand(AGray{U8}, (4,5))
    for T in (AGray{U8}, GrayA{Float32}, AGray{Float64})
        b = @inferred(convert(Array{T}, a))
        rb = @inferred(reinterpret(eltype(T), b))
        @test isa(rb, Array{eltype(T),3})
        @test size(rb) == (2,4,5)
        c = copy(rb)
        rc = @inferred(reinterpret(T, c))
        @test isa(rc, Array{T,2})
        @test size(rc) == (4,5)
    end
    a = rand(RGB{U8}, (4,5))
    for T in (RGB{U8}, HSV{Float32}, XYZ{Float64})
        b = @inferred(convert(Array{T}, a))
        rb = @inferred(reinterpret(eltype(T), b))
        @test isa(rb, Array{eltype(T),3})
        @test size(rb) == (3,4,5)
        c = copy(rb)
        rc = @inferred(reinterpret(T, c))
        @test isa(rc, Array{T,2})
        @test size(rc) == (4,5)
    end
    a = rand(ARGB{U8}, (4,5))
    for T in (ARGB{U8}, AHSV{Float32}, AXYZ{Float64})
        b = @inferred(convert(Array{T}, a))
        rb = @inferred(reinterpret(eltype(T), b))
        @test isa(rb, Array{eltype(T),3})
        @test size(rb) == (4,4,5)
        c = copy(rb)
        rc = @inferred(reinterpret(T, c))
        @test isa(rc, Array{T,2})
        @test size(rc) == (4,5)
    end
    # RGB1/RGB4
    a = rand(RGB{U8}, (4,5))
    for T in (RGB1{U8},RGB4{Float32})
        b = @inferred(convert(Array{T}, a))
        rb = @inferred(reinterpret(eltype(T), b))
        @test isa(rb, Array{eltype(T),3})
        @test size(rb) == (4,4,5)
        c = copy(rb)
        rc = @inferred(reinterpret(T, c))
        @test isa(rc, Array{T,2})
        @test size(rc) == (4,5)
    end
    a = [RGB(1,0,0) RGB(0,0,1);
         RGB(0,1,0) RGB(1,1,1)]
    @test reinterpret(U8, a) == cat(3, [1 0; 0 1; 0 0], [0 1; 0 1; 1 1])
    b = convert(Array{BGR{U8}}, a)
    @test reinterpret(U8, b) == cat(3, [0 0; 0 1; 1 0], [1 1; 0 1; 0 1])
end

@testset "convert" begin
    a = [RGB(1,0,0) RGB(0,0,1);
         RGB(0,1,0) RGB(1,1,1)]
    c = @inferred(convert(Array{BGR}, a))
    @test eltype(c) == BGR{U8}
    c = @inferred(convert(Array{BGR{Float32}}, a))
    @test eltype(c) == BGR{Float32}
    c = @inferred(convert(Array{Lab}, a))
    @test eltype(c) == Lab{Float32}
end

@testset "eltype conversion" begin
    a = [RGB(1,0,0) RGB(0,0,1);
         RGB(0,1,0) RGB(1,1,1)]
    @test eltype(a) == RGB{U8}
    @test eltype(u8(a))       == RGB{U8}
    @test eltype(ufixed8(a))  == RGB{U8}
    @test eltype(ufixed10(a)) == RGB{UFixed10}
    @test eltype(ufixed12(a)) == RGB{UFixed12}
    @test eltype(ufixed14(a)) == RGB{UFixed14}
    @test eltype(ufixed16(a)) == RGB{U16}
    @test eltype(u16(a))      == RGB{U16}
#    @test eltype(float16(a)) == RGB{Float16}
    @test eltype(float32(a)) == RGB{Float32}
    @test eltype(float64(a)) == RGB{Float64}
end
