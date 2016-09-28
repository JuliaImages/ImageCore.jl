using ImageCore, FixedPointNumbers, Colors, ColorVectorSpace
using Base.Test

@testset "map" begin
    @testset "clamp01" begin
        @test clamp01(0.1) === 0.1
        @test clamp01(-0.1) === 0.0
        @test clamp01(0.9) === 0.9
        @test clamp01(1.1) === 1.0
        @test clamp01(Inf) === 1.0
        @test clamp01(-Inf) === 0.0
        @test isnan(clamp01(NaN))
        @test clamp01(U8(0.1)) === U8(0.1)
        @test clamp01(UFixed12(1.2)) === UFixed12(1.0)
        @test clamp01(Gray(-0.2)) === Gray(0.0)
        @test clamp01(Gray(0.7)) === Gray(0.7)
        @test clamp01(Gray(UFixed12(1.2))) === Gray(UFixed12(1.0))
        @test clamp01(RGB(0.2,-0.2,1.8)) === RGB(0.2,0.0,1.0)
        A = [-1.2,0.4,800.3]
        f = takemap(clamp01, A)
        fA = f.(A)
        @test eltype(fA) == Float64
        @test fA == [0, 0.4, 1]
        f = takemap(clamp01, U8, A)
        fA = f.(A)
        @test eltype(fA) == U8
        @test fA == [U8(0), U8(0.4), U8(1)]
    end

    @testset "clamp01nan" begin
        @test clamp01nan(0.1) === 0.1
        @test clamp01nan(-0.1) === 0.0
        @test clamp01nan(0.9) === 0.9
        @test clamp01nan(1.1) === 1.0
        @test clamp01nan(Inf) === 1.0
        @test clamp01nan(-Inf) === 0.0
        @test clamp01nan(NaN) === 0.0
        @test clamp01nan(U8(0.1)) === U8(0.1)
        @test clamp01nan(UFixed12(1.2)) === UFixed12(1.0)
        @test clamp01nan(Gray(-0.2)) === Gray(0.0)
        @test clamp01nan(Gray(0.7)) === Gray(0.7)
        @test clamp01nan(Gray(NaN32)) === Gray(0.0f0)
        @test clamp01nan(Gray(UFixed12(1.2))) === Gray(UFixed12(1.0))
        @test clamp01nan(RGB(0.2,-0.2,1.8)) === RGB(0.2,0.0,1.0)
        @test clamp01nan(RGB(0.2,NaN,1.8)) === RGB(0.2,0.0,1.0)
        A = [-1.2,0.4,-Inf,NaN,Inf,800.3]
        f = takemap(clamp01nan, A)
        fA = f.(A)
        @test eltype(fA) == Float64
        @test fA == [0, 0.4, 0, 0, 1, 1]
        f = takemap(clamp01nan, U8, A)
        fA = f.(A)
        @test eltype(fA) == U8
        @test fA == [U8(0), U8(0.4), U8(0), U8(0), U8(1), U8(1)]
    end

    @testset "scaleminmax" begin
        A = [0, 1, 100, 1000, 2000, -7]
        target = map(x->clamp(x, 0, 1), A/1000)
        for (f, tgt) in ((scaleminmax(0, 1000), target),
                          (scaleminmax(0, 1000.0), target),
                          (scaleminmax(U8, 0, 1000), U8.(target)),
                          (scaleminmax(U8, 0, 1000.0), U8.(target)),
                          (scaleminmax(Gray, 0, 1000), Gray{Float64}.(target)),
                          (scaleminmax(Gray{U8}, 0, 1000.0), Gray{U8}.(target)))
             fA = @inferred(map(f, A))
            @test fA == tgt
            @test eltype(fA) == eltype(tgt)
        end
        B = A+10
        f = scaleminmax(10, 1010)
        @test f.(B) == target
        A = [0, 1, 100, 1000]
        target = A/1000
        for (f, tgt) in ((takemap(scaleminmax, A), target),
                          (takemap(scaleminmax, U8, A), U8.(target)),
                          (takemap(scaleminmax, Gray{U8}, A), Gray{U8}.(target)))
            fA = @inferred(map(f, A))
            @test fA == tgt
            @test eltype(fA) == eltype(tgt)
        end
        A = [Gray(-0.1),Gray(0.1)]
        f = scaleminmax(Gray, -0.1, 0.1)
        @test f.(A) == [Gray(0.0),Gray(1.0)]
        A = reinterpret(RGB, [0.0 128.0; 255.0 0.0; 0.0 0.0])
        f = scaleminmax(RGB, 0, 255)
        @test f.(A) == [RGB(0,1.0,0), RGB(128/255,0,0)]
        f = scaleminmax(RGB{U8}, 0, 255)
        @test f.(A) == [RGB(0,1,0), RGB{U8}(128/255,0,0)]
        f = takemap(scaleminmax, A)
        @test f.(A) == [RGB(0,1.0,0), RGB(128/255,0,0)]
        f = takemap(scaleminmax, RGB{U8}, A)
        @test f.(A) == [RGB(0,1,0), RGB{U8}(128/255,0,0)]
    end

    @testset "scalesigned" begin
        A = [-100,1000]
        target = A/1000
        for (f, tgt) in ((scalesigned(1000), target),
                         (scalesigned(-1000, 0, 1000), target),
                         (scalesigned(-1000, 0, 1000.0), target),
                         (takemap(scalesigned, A), target))
            fA = f.(A)
            @test fA == tgt
            @test eltype(fA) == eltype(tgt)
        end
    end

    @testset "colorsigned" begin
        g, w, m = colorant"green1", colorant"white", colorant"magenta"
        for f in (colorsigned(),
                  colorsigned(g, m),
                  colorsigned(g, w, m))
            @test f(-1) == g
            @test f( 0) == w
            @test f( 1) == m
            @test f(-0.5) ≈ mapc(U8, 0.5g+0.5w)
            @test f( 0.5) ≈ mapc(U8, 0.5w+0.5m)
            @test f(-0.25) ≈ mapc(U8, 0.25g+0.75w)
            @test f( 0.75) ≈ mapc(U8, 0.75m+0.25w)
        end
    end
end

nothing
