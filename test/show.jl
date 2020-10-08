using ImageCore, Colors, FixedPointNumbers, OffsetArrays, Test

if VERSION >= v"1.2.0-DEV.229"
    sumsz(img) = Base.dims2string(size(img)) * ' '
else
    sumsz(img) = ""
end

const rrstr = VERSION >= v"1.6.0-DEV.1083" ? "reshape, " : ""
rrdim(n) = VERSION >= v"1.6.0-DEV.1083" ? n-1 : n

# N0f8 is shown as either N0f8 or Normed{UInt8, 8}
# RGB is shown as ColorTypes.RGB or RGB
function typestring(::Type{T}) where T
    buf = IOBuffer()
    show(buf, T)
    String(take!(buf))
end
N0f8_str = typestring(N0f8)
N0f16_str = typestring(N0f16)
RGB_str = typestring(RGB)

@testset "show" begin
    rgb32 = rand(RGB{Float32}, 3, 5)
    v = view(rgb32, 2:3, :)
    @test summary(v) == "2×5 view(::Array{RGB{Float32},2}, 2:3, :) with eltype $(RGB_str){Float32}"
    a = channelview(rgb32)
    @test summary(a) == (VERSION >= v"1.6.0-DEV.1083" ? "3×3×5 reinterpret(reshape, Float32, ::Array{RGB{Float32},2}) with eltype Float32" :
                                                        "3×3×5 reinterpret(Float32, ::Array{RGB{Float32},3})")
    num64 = rand(3,5)
    b = colorview(RGB, num64)
    @test summary(b) == (VERSION >= v"1.6.0-DEV.1083" ? "5-element reinterpret(reshape, RGB{Float64}, ::$(typeof(num64))) with eltype $(RGB_str){Float64}" :
                                                        "5-element reshape(reinterpret(RGB{Float64}, ::$(typeof(num64))), 5) with eltype $(RGB_str){Float64}")
    rgb8 = rand(RGB{N0f8}, 3, 5)
    c = rawview(channelview(rgb8))
    @test summary(c) == "3×3×5 rawview(reinterpret($(rrstr)N0f8, ::Array{RGB{N0f8},$(rrdim(3))})) with eltype UInt8"
    @test summary(rgb8) == "3×5 Array{RGB{N0f8},2} with eltype $(RGB_str){$(N0f8_str)}"
    rand8 = rand(UInt8, 3, 5)
    d = normedview(PermutedDimsArray(rand8, (2,1)))
    @test summary(d) == "5×3 normedview(N0f8, PermutedDimsArray(::$(typeof(rand8)), (2, 1))) with eltype $(N0f8_str)"
    e = PermutedDimsArray(normedview(rand8), (2,1))
    @test summary(e) == "5×3 PermutedDimsArray(reinterpret(N0f8, ::$(typeof(rand8))), (2, 1)) with eltype $(N0f8_str)"
    rand16 = rand(UInt16, 3, 5)
    f = PermutedDimsArray(normedview(N0f16, rand16), (2,1))
    @test summary(f) == "5×3 PermutedDimsArray(reinterpret(N0f16, ::$(typeof(rand16))), (2, 1)) with eltype $(N0f16_str)"
    g = channelview(rgb8)
    etstr = VERSION >= v"1.6.0-DEV.1083" ? " with eltype N0f8" : ""
    @test summary(g) == "3×3×5 reinterpret($(rrstr)N0f8, ::Array{RGB{N0f8},$(rrdim(3))})$etstr"
    h = OffsetArray(rgb8, -1:1, -2:2)
    @test summary(h) == "$(sumsz(h))OffsetArray(::Array{RGB{N0f8},2}, -1:1, -2:2) with eltype $(RGB_str){$(N0f8_str)} with indices -1:1×-2:2"
    i = channelview(h)
    @test summary(i) == "$(sumsz(i))reinterpret($(rrstr)N0f8, OffsetArray(::Array{RGB{N0f8},$(rrdim(3))}, 1:1, -1:1, -2:2)) with indices 1:3×-1:1×-2:2"
    c = channelview(rand(RGB{N0f8}, 2))
    o = OffsetArray(c, -1:1, 0:1)
    @test summary(o) == "$(sumsz(o))OffsetArray(reinterpret($(rrstr)N0f8, ::Array{RGB{N0f8},$(rrdim(2))}), -1:1, 0:1) with eltype $(N0f8_str) with indices -1:1×0:1"
    # Issue #45
    a = collect(tuple())
    @test summary(a) == "0-element $(typeof(a))"
    b = view(a, :)
    @test summary(b) == "0-element view(::$(typeof(a)), :) with eltype Union{}"
end

nothing
