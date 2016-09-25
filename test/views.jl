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

nothing
