@testset "MATLAB" begin
    @testset "im_from_matlab" begin
        @testset "Gray" begin
            # Float64
            data = rand(4, 5)
            img = @inferred im_from_matlab(data)
            @test eltype(img) == Gray{Float64}
            @test size(img) == (4, 5)
            @test channelview(img) == data

            # N0f8
            data = rand(N0f8, 4, 5)
            img = @inferred im_from_matlab(data)
            mn, mx = extrema(img)
            @test eltype(img) == Gray{N0f8}
            @test size(img) == (4, 5)
            @test 0.0 <= mn <= mx <= 1.0

            # UInt8
            data = rand(UInt8, 4, 5)
            img = @inferred im_from_matlab(data)
            mn, mx = extrema(img)
            @test eltype(img) == Gray{N0f8}
            @test size(img) == (4, 5)
            @test 0.0 <= mn <= mx <= 1.0

            # UInt16
            data = rand(UInt16, 4, 5)
            img = @inferred im_from_matlab(data)
            mn, mx = extrema(img)
            @test eltype(img) == Gray{N0f16}
            @test size(img) == (4, 5)
            @test 0.0 <= mn <= mx <= 1.0

            # Int16 -- MATLAB's im2double supports Int16
            data = rand(Int16, 4, 5)
            img = @inferred im_from_matlab(data)
            mn, mx = extrema(img)
            @test eltype(img) == Gray{Float64}
            @test size(img) == (4, 5)
            @test 0.0 <= mn <= mx <= 1.0
            data = Int16[-32768 0; 0 32767]
            @test isapprox([0.0 0.5; 0.5 1.0], @inferred im_from_matlab(data); atol=1e-4)

            # Int is ambiguious -- manual conversion is required but we provide some basic hints
            data = rand(1:255, 4, 5)
            msg = "Unrecognized element type $(Int), manual conversion to float point number or fixed point number is needed. For instance: `UInt8.(X)` or `X./255`"
            @test_throws ArgumentError(msg) im_from_matlab(data)
            data = rand(256:65535, 4, 5)
            msg = "Unrecognized element type $(Int), manual conversion to float point number or fixed point number is needed. For instance: `UInt16.(X)` or `X./65535`"
            @test_throws ArgumentError(msg) im_from_matlab(data)

            # vector
            data = rand(UInt8, 4)
            img = @inferred im_from_matlab(data)
            @test eltype(img) == Gray{N0f8}
            @test size(img) == (4,)
        end

        @testset "RGB" begin
            # Float64
            data = rand(4, 5, 3)
            img = im_from_matlab(data)
            @test_broken @inferred im_from_matlab(data)
            @test_nowarn @inferred collect(im_from_matlab(data)) # type inference issue only occurs in lazy mode
            @test eltype(img) == RGB{Float64}
            @test size(img) == (4, 5)
            @test permutedims(channelview(img), (2, 3, 1)) == data

            # N0f8
            data = rand(N0f8, 4, 5, 3)
            img = im_from_matlab(data)
            @test_broken @inferred im_from_matlab(data)
            @test_nowarn @inferred collect(im_from_matlab(data)) # type inference issue only occurs in lazy mode
            mn, mx = extrema(channelview(img))
            @test eltype(img) == RGB{N0f8}
            @test size(img) == (4, 5)
            @test 0.0 <= mn <= mx <= 1.0

            # UInt8
            data = rand(UInt8, 4, 5, 3)
            img = im_from_matlab(data)
            @test_broken @inferred im_from_matlab(data)
            @test_nowarn @inferred collect(im_from_matlab(data)) # type inference issue only occurs in lazy mode
            mn, mx = extrema(channelview(img))
            @test eltype(img) == RGB{N0f8}
            @test size(img) == (4, 5)
            @test 0.0 <= mn <= mx <= 1.0

            # UInt16
            data = rand(UInt16, 4, 5, 3)
            img = im_from_matlab(data)
            @test_broken @inferred im_from_matlab(data)
            @test_nowarn @inferred collect(im_from_matlab(data)) # type inference issue only occurs in lazy mode
            mn, mx = extrema(channelview(img))
            @test eltype(img) == RGB{N0f16}
            @test size(img) == (4, 5)
            @test 0.0 <= mn <= mx <= 1.0

            # Int16 -- MATLAB's im2double supports Int16
            data = rand(Int16, 4, 5, 3)
            img = im_from_matlab(data)
            @test_broken @inferred im_from_matlab(data)
            @test_nowarn @inferred collect(im_from_matlab(data)) # type inference issue only occurs in lazy mode
            mn, mx = extrema(channelview(img))
            @test eltype(img) == RGB{Float64}
            @test size(img) == (4, 5)
            @test 0.0 <= mn <= mx <= 1.0

            # Int is ambiguious -- manual conversion is required but we provide some basic hints
            data = rand(1:255, 4, 5, 3)
            msg = "Unrecognized element type $(Int), manual conversion to float point number or fixed point number is needed. For instance: `UInt8.(X)` or `X./255`"
            @test_throws ArgumentError(msg) im_from_matlab(data)
            data = rand(256:65535, 4, 5, 3)
            msg = "Unrecognized element type $(Int), manual conversion to float point number or fixed point number is needed. For instance: `UInt16.(X)` or `X./65535`"
            @test_throws ArgumentError(msg) im_from_matlab(data)
        end

        data = rand(4, 4, 2)
        msg = "Unrecognized MATLAB image layout."
        @test_throws ArgumentError(msg) im_from_matlab(data)

        data = rand(4, 4, 3, 1)
        msg = "Unrecognized MATLAB image layout."
        @test_throws ArgumentError(msg) im_from_matlab(data)
    end
end
