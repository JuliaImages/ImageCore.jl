# some views are in colorchannels.jl
using Colors, ImageCore, Base.Test

@testset "rawview" begin
    a = map(U8, rand(3,5))
    v = rawview(a)
    @test v[2,2] === a[2,2].i
    v[1,3] = 0xff
    @test a[1,3] === U8(1)
    v[1,3] = 0x01
    @test a[1,3] === U8(1/255)
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
