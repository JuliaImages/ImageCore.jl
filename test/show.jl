using ImageCore, Colors, FixedPointNumbers, OffsetArrays, Test

if VERSION >= v"1.2.0-DEV.229"
    sumsz(img) = Base.dims2string(size(img)) * ' '
else
    sumsz(img) = ""
end

@testset "show" begin
    thismodule = string(@__MODULE__)
    if thismodule != "Main"
        prefixF = "FixedPointNumbers."
        prefixC = "ColorTypes."
    else
        prefixF = prefixC = ""
    end
    rgb32 = rand(RGB{Float32}, 3, 5)
    v = view(rgb32, 2:3, :)
    @test summary(v) == "2×5 view(::Array{RGB{Float32},2}, 2:3, :) with eltype $(prefixC)RGB{Float32}"
    a = channelview(rgb32)
    @test summary(a) == "3×3×5 reinterpret(Float32, ::Array{RGB{Float32},3})"
    num64 = rand(3,5)
    b = colorview(RGB, num64)
    @test summary(b) == "5-element reshape(reinterpret(RGB{Float64}, ::Array{Float64,2}), 5) with eltype $(prefixC)RGB{Float64}"
    rgb8 = rand(RGB{N0f8}, 3, 5)
    c = rawview(channelview(rgb8))
    @test summary(c) == "3×3×5 rawview(reinterpret(N0f8, ::Array{RGB{N0f8},3})) with eltype UInt8"
    @test summary(rgb8) == "3×5 Array{RGB{N0f8},2} with eltype $(prefixC)RGB{$(prefixF)Normed{UInt8,8}}"
    rand8 = rand(UInt8, 3, 5)
    d = normedview(permuteddimsview(rand8, (2,1)))
    @test summary(d) == "5×3 normedview(N0f8, PermutedDimsArray(::Array{UInt8,2}, (2, 1))) with eltype $(prefixF)Normed{UInt8,8}"
    e = permuteddimsview(normedview(rand8), (2,1))
    @test summary(e) == "5×3 PermutedDimsArray(reinterpret(N0f8, ::Array{UInt8,2}), (2, 1)) with eltype $(prefixF)Normed{UInt8,8}"
    f = permuteddimsview(normedview(N0f16, rand(UInt16, 3, 5)), (2,1))
    @test summary(f) == "5×3 PermutedDimsArray(reinterpret(N0f16, ::Array{UInt16,2}), (2, 1)) with eltype $(prefixF)Normed{UInt16,16}"
    g = channelview(rgb8)
    @test summary(g) == "3×3×5 reinterpret(N0f8, ::Array{RGB{N0f8},3})"
    h = OffsetArray(rgb8, -1:1, -2:2)
    @test summary(h) == "$(sumsz(h))OffsetArray(::Array{RGB{N0f8},2}, -1:1, -2:2) with eltype $(prefixC)RGB{$(prefixF)Normed{UInt8,8}} with indices -1:1×-2:2"
    i = channelview(h)
    @test summary(i) == "$(sumsz(i))reinterpret(N0f8, OffsetArray(::Array{RGB{N0f8},3}, 1:1, -1:1, -2:2)) with indices 1:3×-1:1×-2:2"
    c = channelview(rand(RGB{N0f8}, 2))
    o = OffsetArray(c, -1:1, 0:1)
    @test summary(o) == "$(sumsz(o))OffsetArray(reinterpret(N0f8, ::Array{RGB{N0f8},2}), -1:1, 0:1) with eltype $(prefixF)Normed{UInt8,8} with indices -1:1×0:1"
    # Issue #45
    a = collect(tuple())
    @test summary(a) == "0-element Array{Union{},1}"
    b = view(a, :)
    @test summary(b) == "0-element view(::Array{Union{},1}, :) with eltype Union{}"
end

nothing
