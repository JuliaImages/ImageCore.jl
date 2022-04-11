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

        @testset "Color3" begin
            img = Lab.(rand(RGB{Float64}, 4, 5))
            data = permutedims(channelview(img), (2, 3, 1))
            img1 = im_from_matlab(Lab, data)
            @test eltype(img1) == Lab{Float64}
            @test size(img1) == (4, 5)
            @test RGB.(img) ≈ RGB.(img1)
        end

        data = rand(4, 4, 2)
        msg = "Unrecognized MATLAB image layout."
        @test_throws ArgumentError(msg) im_from_matlab(data)

        data = rand(4, 4, 3, 1)
        msg = "Unrecognized MATLAB image layout."
        @test_throws ArgumentError(msg) im_from_matlab(data)
        msg = "For 4 dimensional numerical array, manual conversion from MATLAB layout is required."
        @test_throws ArgumentError(msg) im_from_matlab(RGB, data)
    end

    @testset "im_to_matlab" begin
        @testset "Gray" begin
            img = rand(Gray{N0f8}, 4, 5)
            data = @inferred im_to_matlab(img)
            @test eltype(data) == N0f8
            @test size(data) == (4, 5)
            @test img == data
            data = @inferred im_to_matlab(Float64, img)
            @test eltype(data) == Float64
            @test img == data

            img = rand(Gray{Float64}, 4, 5)
            data = @inferred im_to_matlab(img)
            @test eltype(data) == Float64
            @test size(data) == (4, 5)
            @test img == data

            img = rand(UInt8, 4, 5)
            @test img === @inferred im_to_matlab(img)

            img = rand(Gray{Float64}, 4)
            data = @inferred im_to_matlab(img)
            @test eltype(data) == Float64
            @test size(data) == (4,)
        end

        @testset "RGB" begin
            img = rand(RGB{N0f8}, 4, 5)
            data = @inferred im_to_matlab(img)
            @test eltype(data) == N0f8
            @test size(data) == (4, 5, 3)
            @test permutedims(channelview(img), (2, 3, 1)) == data
            data = @inferred im_to_matlab(Float64, img)
            @test eltype(data) == Float64
            @test size(data) == (4, 5, 3)
            @test permutedims(channelview(img), (2, 3, 1)) == data

            img = rand(RGB{Float64}, 4, 5)
            data = @inferred im_to_matlab(img)
            @test eltype(data) == Float64
            @test size(data) == (4, 5, 3)
            @test permutedims(channelview(img), (2, 3, 1)) == data

            img = rand(UInt8, 4, 5, 3)
            @test img === @inferred im_to_matlab(img)

            img = rand(RGB{Float64}, 4)
            data = @inferred im_to_matlab(img)
            @test eltype(data) == Float64
            @test size(data) == (4, 1, 3) # oh yes, we add one extra dimension for RGB but not for Gray

            img = rand(RGB{Float64}, 2, 3, 4)
            msg = "For 3 dimensional color image, manual conversion to MATLAB layout is required."
            @test_throws ArgumentError(msg) im_to_matlab(img)
        end

        @testset "Color3" begin
            img = Lab.(rand(RGB, 4, 5))
            @test @inferred(im_to_matlab(img)) ≈ @inferred(im_to_matlab(RGB.(img)))
        end
        @testset "transparent" begin
            img = rand(AGray, 4, 5)
            @test @inferred(im_to_matlab(img)) == @inferred(im_to_matlab(Gray.(img)))
            img = rand(RGBA, 4, 5)
            @test @inferred(im_to_matlab(img)) == @inferred(im_to_matlab(RGB.(img)))
        end
    end

    # test `im_from_matlab` and `im_to_matlab` are inverses of each other.
    data = rand(4, 5)
    @test data === im_to_matlab(im_from_matlab(data))
    # For RGB, ideally we would want to ensure this === equality, but it's not possible at the moment.
    data = rand(4, 5, 3)
    @test data == im_to_matlab(im_from_matlab(data))
    # the output range are always in [0, 1]; in this case they're not inverse of each other.
    data = rand(UInt8, 4, 5)
    img = im_from_matlab(data)
    @test im_to_matlab(img) == data ./ 255
end
