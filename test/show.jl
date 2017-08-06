using ImageCore, Colors, FixedPointNumbers, OffsetArrays, Base.Test

if VERSION >= v"0.6.0-dev.2505"
    tformat(x...) = join(string.(x), ", ")
else
    tformat(x...) = join(map(string, x), ",")
end

@testset "show" begin
    rgb32 = rand(RGB{Float32}, 3, 5)
    v = view(rgb32, 2:3, :)
    @test summary(v) == "2×5 view(::Array{RGB{Float32},2}, 2:3, :) with element type ColorTypes.RGB{Float32}"
    a = ChannelView(rgb32)
    @test summary(a) == "3×3×5 ChannelView(::Array{RGB{Float32},2}) with element type Float32"
    num64 = rand(3,5)
    b = ColorView{RGB}(num64)
    @test summary(b) == "5-element ColorView{RGB}(::Array{Float64,2}) with element type ColorTypes.RGB{Float64}"
    rgb8 = rand(RGB{N0f8}, 3, 5)
    c = rawview(ChannelView(rgb8))
    @test summary(c) == "3×3×5 rawview(ChannelView(::Array{RGB{N0f8},2})) with element type UInt8"
    @test summary(rgb8) == "3×5 Array{RGB{N0f8},2}"
    rand8 = rand(UInt8, 3, 5)
    d = normedview(permuteddimsview(rand8, (2,1)))
    @test summary(d) == "5×3 normedview(N0f8, permuteddimsview(::Array{UInt8,2}, $(tformat((2,1))))) with element type FixedPointNumbers.Normed{UInt8,8}"
    e = permuteddimsview(normedview(rand8), (2,1))
    @test summary(e) == "5×3 permuteddimsview(::Array{N0f8,2}, $(tformat((2,1)))) with element type FixedPointNumbers.Normed{UInt8,8}"
    f = permuteddimsview(normedview(N0f16, rand(UInt16, 3, 5)), (2,1))
    @test summary(f) == "5×3 permuteddimsview(::Array{N0f16,2}, $(tformat((2,1)))) with element type FixedPointNumbers.Normed{UInt16,16}"
    g = channelview(rgb8)
    @test summary(g) == "3×3×5 Array{N0f8,3}"
    h = OffsetArray(rgb8, -1:1, -2:2)
    @test summary(h) == "-1:1×-2:2 OffsetArray{RGB{N0f8},2}"
    i = channelview(h)
    @test summary(i) == "1:3×-1:1×-2:2 ChannelView(::OffsetArray{RGB{N0f8},2}) with element type FixedPointNumbers.Normed{UInt8,8}"
    c = ChannelView(rand(RGB{N0f8}, 2))
    o = OffsetArray(c, -1:1, 0:1)
    @test summary(o) == "-1:1×0:1 OffsetArray{N0f8,2,ImageCore.ChannelView{FixedPointNumbers.Normed{UInt8,8},2,Array{ColorTypes.RGB{FixedPointNumbers.Normed{UInt8,8}},1}}}"
    # Issue #45
    a = collect(tuple())
    @test summary(a) == "0-element Array{Union{},1}"
    b = view(a, :)
    @test summary(b) == "0-element view(::Array{Union{},1}, :) with element type Union{}"
end

nothing
