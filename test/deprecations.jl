using ImageCore, Colors, FixedPointNumbers, OffsetArrays
using Test, Random

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

@testset "convert (deprecations)" begin
    @info "Deprecation warnings are expected"
    a = [RGB(1,0,0) RGB(0,0,1);
         RGB(0,1,0) RGB(1,1,1)]
    c = @inferred(convert(Array{BGR}, a))
    @test eltype(c) == BGR{N0f8}
    c = @inferred(convert(Array{BGR{Float32}}, a))
    @test eltype(c) == BGR{Float32}
    c = @inferred(convert(Array{Lab}, a))
    @test eltype(c) == Lab{Float32}
    for a in (rand(Float32, (4,5)),
              bitrand(4,5))
        b = @inferred(convert(Array{Gray}, a))
        @test eltype(b) == Gray{eltype(a)}
        b = @inferred(convert(Array{Gray{N0f8}}, a))
        @test eltype(b) == Gray{N0f8}
    end

    # Gray images wrapped by an OffsetArray.
    A = rand(8,8)
    for img in ( Gray.(A),
                 Gray.(N0f8.(A)),
                 Gray.(N0f16.(A)) )
        imgo = OffsetArray(img, -2, -1)
        s = @inferred(convert(OffsetArray{Gray{Float32},2,Array{Gray{Float32}}},imgo))
        @test eltype(s) == Gray{Float32}
        @test s isa OffsetArray{Gray{Float32},2,Array{Gray{Float32},2}}
        @test permutedims(permutedims(s,(2,1)),(2,1)) == s
        @test axes(s) === axes(imgo)
    end

    for img in ( Gray.(A),
                 Gray.(N0f8.(A)),
                 Gray.(N0f16.(A)) )
        imgo = OffsetArray(img, -2, -1)
        s = @inferred(convert(OffsetArray{Gray{N0f8},2,Array{Gray{N0f8}}},imgo))
        @test eltype(s) == Gray{N0f8}
        @test s isa OffsetArray{Gray{N0f8},2,Array{Gray{N0f8},2}}
        @test permutedims(permutedims(s,(2,1)),(2,1)) == s
        @test axes(s) === axes(imgo)
    end

    for img in ( Gray.(A),
                 Gray.(N0f8.(A)),
                 Gray.(N0f16.(A)) )
        imgo = OffsetArray(img, -2, -1)
        s = @inferred(convert(OffsetArray{Gray{N0f16},2,Array{Gray{N0f16}}},imgo))
        @test eltype(s) == Gray{N0f16}
        @test s isa OffsetArray{Gray{N0f16},2,Array{Gray{N0f16},2}}
        @test permutedims(permutedims(s,(2,1)),(2,1)) == s
        @test axes(s) === axes(imgo)
    end

    # Color images wrapped by an OffsetArray.
    A = rand(RGB{Float32},8,8)
    for img in ( A,
                 n0f8.(A),
                 n6f10.(A),
                 n4f12.(A),
                 n2f14.(A),
                 n0f16.(A))
        imgo = OffsetArray(img, -2, -1)
        s = @inferred(convert(OffsetArray{RGB{N0f8},2,Array{RGB{N0f8}}},imgo))
        @test eltype(s) == RGB{N0f8}
        @test s isa OffsetArray{RGB{N0f8},2,Array{RGB{N0f8},2}}
        @test permutedims(permutedims(s,(2,1)),(2,1)) == s
        @test axes(s) === axes(imgo)
    end

    A = rand(RGB{Float32},8,8)
    for img in ( A,
                 n0f8.(A),
                 n6f10.(A),
                 n4f12.(A),
                 n2f14.(A),
                 n0f16.(A))
        imgo = OffsetArray(img, -2, -1)
        s = @inferred(convert(OffsetArray{RGB{Float32},2,Array{RGB{Float32}}},imgo))
        @test eltype(s) == RGB{Float32}
        @test s isa OffsetArray{RGB{Float32},2,Array{RGB{Float32},2}}
        @test permutedims(permutedims(s,(2,1)),(2,1)) == s
        @test axes(s) === axes(imgo)
    end
end
