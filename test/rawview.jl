@testset "rawview" begin
    a = map(U8, rand(3,5))
    v = rawview(a)
    @test v[2,2] === a[2,2].i
    v[1,3] = 0xff
    @test a[1,3] === U8(1)
    v[1,3] = 0x01
    @test a[1,3] === U8(1/255)
end
