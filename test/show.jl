using ImageCore, Colors, FixedPointNumbers, Base.Test

@testset "show" begin
    a = ChannelView(rand(RGB{Float32}, 3, 5))
    @test summary(a) == "3×3×5 ChannelView(::Array{RGB{Float32},2}) with element type Float32"
    b = ColorView{RGB{Float64}}(rand(3,5))
    @test summary(b) == "5-element ColorView{RGB}(::Array{Float64,2}) with element type ColorTypes.RGB{Float64}"
    c = rawview(ChannelView(rand(RGB{U8}, 3, 5)))
    @test summary(c) == "3×3×5 rawview(ChannelView(::Array{RGB{U8},2})) with element type UInt8"
    rand8 = rand(UInt8, 3, 5)
    d = ufixedview(permuteddimsview(rand8, (2,1)))
    @test summary(d) == "5×3 ufixedview(U8, permuteddimsview(::Array{UInt8,2}, (2,1))) with element type FixedPointNumbers.UFixed{UInt8,8}"
    e = permuteddimsview(ufixedview(rand8), (2,1))
    @test summary(e) == "5×3 permuteddimsview(::Array{U8,2}, (2,1)) with element type FixedPointNumbers.UFixed{UInt8,8}"
    f = permuteddimsview(ufixedview(UFixed16, rand(UInt16, 3, 5)), (2,1))
    @test summary(f) == "5×3 permuteddimsview(::Array{FixedPointNumbers.UFixed{UInt16,16},2}, (2,1)) with element type FixedPointNumbers.UFixed{UInt16,16}"
end

nothing
