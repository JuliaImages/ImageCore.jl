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

        @testset "indexed image" begin
            index = [1 2 3 4 5
                     2 3 4 5 1]
            values = [0.0 0.0 0.0  # black
                      1.0 0.0 0.0  # red
                      0.0 1.0 0.0  # green
                      0.0 0.0 1.0  # blue
                      1.0 1.0 1.0] # white
            img = im_from_matlab(index, values)
            @test size(img) == (2, 5)
            @test eltype(img) == RGB{Float64}
            @test img[2, 3] == RGB(0.0, 0.0, 1.0)

            lab_values = permutedims(channelview(Lab.(img.values)), (2, 1))
            lab_img = im_from_matlab(Lab, index, lab_values)
            @test sum(abs2, channelview(RGB.(lab_img) - img)) < 1e-10
        end
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
            data = if VERSION >= v"1.6"
                @inferred im_to_matlab(img)
            else
                im_to_matlab(img)
            end
            @test eltype(data) == N0f8
            @test size(data) == (4, 5, 3)
            @test permutedims(channelview(img), (2, 3, 1)) == data
            data = if VERSION >= v"1.6"
                @inferred im_to_matlab(Float64, img)
            else
                im_to_matlab(Float64, img)
            end
            @test eltype(data) == Float64
            @test size(data) == (4, 5, 3)
            @test permutedims(channelview(img), (2, 3, 1)) == data

            img = rand(RGB{Float64}, 4, 5)
            data = if VERSION >= v"1.6"
                @inferred im_to_matlab(img)
            else
                im_to_matlab(img)
            end
            @test eltype(data) == Float64
            @test size(data) == (4, 5, 3)
            @test permutedims(channelview(img), (2, 3, 1)) == data

            img = rand(UInt8, 4, 5, 3)
            @test img === @inferred im_to_matlab(img)

            img = rand(RGB{Float64}, 4)
            data = if VERSION >= v"1.6"
                @inferred im_to_matlab(img)
            else
                im_to_matlab(img)
            end
            @test eltype(data) == Float64
            @test size(data) == (4, 3)
        end

        @testset "Color3" begin
            img = Lab.(rand(RGB, 4, 5))
            if VERSION >= v"1.6"
                @test @inferred(im_to_matlab(img)) ≈ @inferred(im_to_matlab(RGB.(img)))
            else
                @test im_to_matlab(img) ≈ im_to_matlab(RGB.(img))
            end
        end
        @testset "transparent" begin
            img = rand(AGray, 4, 5)
            if VERSION >= v"1.6"
                @test @inferred(im_to_matlab(img)) == @inferred(im_to_matlab(Gray.(img)))
            else
                @test im_to_matlab(img) == im_to_matlab(Gray.(img))
            end
            img = rand(RGBA, 4, 5)
            if VERSION >= v"1.6"
                @test @inferred(im_to_matlab(img)) == @inferred(im_to_matlab(RGB.(img)))
            else
                @test im_to_matlab(img) == im_to_matlab(RGB.(img))
            end
        end

        @testset "indexed image" begin
            index = [1 2 3 4 5
                     2 3 4 5 1]
            values = [
                RGB(0.0,0.0,0.0), # black
                RGB(1.0,0.0,0.0), # red
                RGB(0.0,1.0,0.0), # green
                RGB(0.0,0.0,1.0), # blue
                RGB(1.0,1.0,1.0)  # white
            ]
            img = IndirectArray(index, values)
            m_index, m_values = im_to_matlab(img)
            @test size(m_index) == (2, 5)
            @test eltype(m_index) == eltype(index)
            @test size(m_values) == (5, 3)
            @test eltype(m_values) == Float64
            @test index == m_index
            @test m_values == permutedims(channelview(values), (2, 1))

            m_index, m_values = im_to_matlab(N0f8, img)
            @test eltype(m_values) == N0f8
            @test m_values == permutedims(channelview(values), (2, 1))
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
