using ImageCore, Colors, FixedPointNumbers, ColorVectorSpace
using Base.Test

@testset "Deprecated" begin
    @testset "constructors" begin
        # grayim
        for a in (0x00:0x18, collect(0x00:0x18))
            B = reshape(a, 5, 5)
            img = grayim(B)
            @test colorspace(img) == "Gray"
            @test colordim(img) == 0
            @test img[5,2] === Gray{N0f8}(9/255)
        end
        for a in (0x00:0x7c, collect(0x00:0x7c))
            B = reshape(a, 5, 5, 5)
            img = grayim(B)
            @test colorspace(img) == "Gray"
            @test colordim(img) == 0
            @test img[5,2,3] === Gray{N0f8}(59/255)
        end
        for a in (0x0000:0x0018, collect(0x0000:0x0018))
            B = reshape(a, 5, 5)
            img = grayim(B)
            @test colorspace(img) == "Gray"
            @test colordim(img) == 0
            @test img[5,2] === Gray{N0f16}(9/65535)
        end
        for a in (0x0000:0x007c, collect(0x0000:0x007c))
            B = reshape(a, 5, 5, 5)
            img = grayim(B)
            @test colorspace(img) == "Gray"
            @test colordim(img) == 0
            @test img[5,2,3] === Gray{N0f16}(59/65535)
        end
        # colorim
        for a in (0x00:0x4a, collect(0x00:0x4a))
            C = reshape(a, 3, 5, 5)
            img = colorim(C)
            @test colorspace(img) == "RGB"
            @test colordim(img) == 0
            @test img[1,1] === RGB{N0f8}(0,1/255,2/255)
            C = reshape(a, 5, 5, 3)
            img = colorim(C)
            @test colorspace(img) == "RGB"
            @test colordim(img) == 0
            @test img[1,1] === RGB{N0f8}(0,25/255,50/255)
            @test_throws ErrorException colorim(reshape(a, 5, 3, 5))
        end
        for a in (0x0000:0x004a, collect(0x0000:0x004a))
            C = reshape(a, 3, 5, 5)
            img = colorim(C)
            @test colorspace(img) == "RGB"
            @test colordim(img) == 0
            @test img[1,1] === RGB{N0f16}(0,1/65535,2/65535)
            C = reshape(a, 5, 5, 3)
            img = colorim(C)
            @test colorspace(img) == "RGB"
            @test colordim(img) == 0
            @test img[1,1] === RGB{N0f16}(0,25/65535,50/65535)
            @test_throws ErrorException colorim(reshape(a, 5, 3, 5))
        end
        for a in (0x00:0x63, collect(0x00:0x63))
            for (S,T) in (("RGBA", RGBA), ("ARGB",ARGB))
                C = reshape(a, 4, 5, 5)
                img = colorim(C, S)
                @test colorspace(img) == S
                @test colordim(img) == 0
                @test img[1,1] === T{N0f8}(0,1/255,2/255,3/255)
                C = reshape(a, 5, 5, 4)
                img = colorim(C, S)
                @test colorspace(img) == S
                @test colordim(img) == 0
                @test img[1,1] === T{N0f8}(0,25/255,50/255,75/255)
            end
            @test_throws ErrorException colorim(reshape(a, 4, 5, 5), "RRRR")
        end
        # ambiguous sizes
        for a in (0x00:0x2c, collect(0x00:0x2c))
            C = reshape(a, 3, 5, 3)
            @test_throws ErrorException colorim(C)
        end
        for a in (0x00:0x4f, collect(0x00:0x4f))
            C = reshape(a, 4, 5, 4)
            @test_throws ErrorException colorim(C)
        end
    end
    @testset "traits" begin
        for (B,S) in ((rand(UInt16(1):UInt16(20), 3, 5),"Gray"),
                      (rand(Gray{Float32}, 3, 5),"Gray"),
                      (rand(RGB{Float16}, 3, 5),"RGB"),
                      (bitrand(3, 5),"Binary"),
                      (rand(UInt32, 3, 5),"RGB24"))
            T = eltype(B)
            @test data(B) === B
            @test colorspace(B) == S
            @test colordim(B) == 0
            @test timedim(B) == 0
            @test spatialorder(B) == (:y,:x)
            @test isdirect(B)
            @test limits(B) == (T==Bool ? (0,1) : (zero(T),one(T)))
            @test storageorder(B) == (:y,:x)
            @test ncolorelem(B) == 1
            assert2d(B)
            assert_scalar_color(B)
            @test isyfirst(B)
            @test !isxfirst(B)
            assert_yfirst(B)
            @test_throws ErrorException assert_xfirst(B)
            @test spatialproperties(B) == String[]
        end
        for (B,S) in ((rand(UInt16(1):UInt16(20), 5),"Gray"),
                      (rand(Gray{Float32}, 5),"Gray"),
                      (rand(RGB{Float16}, 5),"RGB"),
                      (bitrand(5),"Binary"))
            @test colorspace(B) == S
        end
        for (B,S) in ((rand(Gray{Float32}, 5, 5, 5),"Gray"),
                      (rand(RGB{Float16}, 5, 5, 5),"RGB"),
                      (bitrand(5, 5, 5),"Binary"))
            @test colorspace(B) == S
        end
        @test colorspace(rand(Float32, 5, 5, 3)) == "Gray"
        @test colorspace(rand(Float32, 5, 5, 5)) == "Gray"
    end
    @testset "Reinterpret, convert, separate, raw" begin
        # some of these are redundant with convert_reinterpret.jl, but
        # these are "classic" tests so it's good to make sure they
        # pass
        a = RGB{Float64}[RGB(1,1,0)]
        af = reinterpret(Float64, a)
        @test vec(af) == [1.0,1.0,0.0]
        @test size(af) == (3,1)
        @test_throws DimensionMismatch reinterpret(Float32, a)
        anew = reinterpret(RGB, af)
        @test anew == a
        anew = reinterpret(RGB, vec(af))
        @test anew[1] == a[1]
        @test ndims(anew) == 0
        anew = reinterpret(RGB{Float64}, af)
        @test anew == a
        @test_throws DimensionMismatch reinterpret(RGB{Float32}, af)
        Au8 = rand(0x00:0xff, 3, 5, 4)
        A8 = reinterpret(N0f8, Au8)
        rawrgb8 = reinterpret(RGB, A8)
        @test eltype(rawrgb8) == RGB{N0f8}
        @test reinterpret(N0f8, rawrgb8) == A8
        @test reinterpret(UInt8, rawrgb8) == Au8
        rawrgb32 = convert(Array{RGB{Float32}}, rawrgb8)
        @test eltype(rawrgb32) == RGB{Float32}
        @test ufixed8(rawrgb32) == rawrgb8
        @test reinterpret(N0f8, rawrgb8) == A8
        # imrgb8 = convert(Image, rawrgb8)
        # @test spatialorder(imrgb8) == ImageCore.yx
        # cvt = convert(Image, imrgb8)
        # @test cvt == imrgb8 && typeof(cvt) == typeof(imrgb8)
        # cvt = convert(Image{RGB{N0f8}}, imrgb8)
        # @test cvt == imrgb8 && typeof(cvt) == typeof(imrgb8)
        imrgb8 = rawrgb8
        im8 = reinterpret(N0f8, imrgb8)
        @test data(im8) == A8
        @test reinterpret(UInt8, imrgb8) == Au8
        @test reinterpret(RGB, im8) == imrgb8
        ims8 = separate(imrgb8)
        @test colorspace(ims8) == "Gray"
        # cvt = convert(Image, ims8)
        # @test cvt == ims8 && typeof(cvt) == typeof(ims8)
        # @test (cvt = convert(Image{N0f8}, ims8)) == ims8 && typeof(cvt) == typeof(ims8)
        # @test (cvt = separate(ims8)) == ims8 && typeof(cvt) == typeof(ims8)
        # imrgb8_2 = convert(Image{RGB}, ims8)
        # @test isa(imrgb8_2, Image{RGB{N0f8}})
        A = reinterpret(N0f8, UInt8[1 2; 3 4])
        # imgray = convert(Image{Gray{N0f8}}, A)
        imgray = convert(Array{Gray{N0f8}}, A)
        @test spatialorder(imgray) == ImageCore.yx
        @test data(imgray) == reinterpret(Gray{N0f8}, [0x01 0x02; 0x03 0x04])
        # @test eltype(convert(Image{HSV{Float32}}, imrgb8)) == HSV{Float32}
        # @test eltype(convert(Image{HSV}, float32(imrgb8))) == HSV{Float32}
        # local img = Image(reinterpret(Gray{N0f16}, rand(UInt16, 5, 5)))
        # imgs = subim(img, :, :)
        img = reinterpret(Gray{N0f16}, rand(UInt16, 5, 5))
        imgs = view(img, :, :)
        @test isa(minimum(imgs), Gray{N0f16})  # change in behavior from Images issue#232
        imgdata = rand(UInt16, 5, 5)
        # img = Image(reinterpret(Gray{N0f16}, imgdata))
        img = reinterpret(Gray{N0f16}, imgdata)
        @test all(raw(img) .== imgdata)
        # @test size(raw(Image(rawrgb8))) == (3,5,4)
        @test all(raw(imgdata) .== imgdata)
    end
end

nothing
