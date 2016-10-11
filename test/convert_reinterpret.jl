using ImageCore, Colors, FixedPointNumbers, OffsetArrays
using Base.Test

@testset "reinterpret" begin
    # Gray
    for sz in ((4,), (4,5))
        a = rand(Gray{U8}, sz)
        for T in (Gray{U8}, Gray{Float32}, Gray{Float64})
            b = @inferred(convert(Array{T}, a))
            rb = @inferred(reinterpret(eltype(T), b))
            if ImageCore.squeeze1
                @test isa(rb, Array{eltype(T),length(sz)})
                @test size(rb) == sz
            else
                @test isa(rb, Array{eltype(T),length(sz)+1})
                @test size(rb) == (1,sz...)
            end
            c = copy(rb)
            rc = @inferred(reinterpret(T, c))
            @test isa(rc, Array{T,length(sz)})
            @test size(rc) == sz
        end
    end
    for sz in ((4,), (4,5))
        # Bool/Gray{Bool}
        b = rand(Bool, sz)
        rb = @inferred(reinterpret(Gray{Bool}, b))
        @test isa(rb, Array{Gray{Bool}, length(sz)})
        @test size(rb) == sz
        c = copy(rb)
        rc = @inferred(reinterpret(Bool, c))
        @test isa(rc, Array{Bool,length(sz)})
        @test size(rc) == sz
    end
    for sz in ((4,), (4,5))
        b = Gray24.(reinterpret(U8, rand(UInt8, sz)))
        for T in (UInt32, RGB24)
            rb = @inferred(reinterpret(T, b))
            @test isa(rb, Array{T,length(sz)})
            @test size(rb) == sz
            c = copy(rb)
            rc = @inferred(reinterpret(Gray24, c))
            @test isa(rc, Array{Gray24,length(sz)})
            @test size(rc) == sz
        end
    end
    # TransparentGray
    a = rand(AGray{U8}, (4,5))
    for T in (AGray{U8}, GrayA{Float32}, AGray{Float64})
        b = @inferred(convert(Array{T}, a))
        rb = @inferred(reinterpret(eltype(T), b))
        @test isa(rb, Array{eltype(T),3})
        @test size(rb) == (2,4,5)
        c = copy(rb)
        rc = @inferred(reinterpret(T, c))
        @test isa(rc, Array{T,2})
        @test size(rc) == (4,5)
    end
    # Color3
    a = rand(RGB{U8}, (4,5))
    for T in (RGB{U8}, HSV{Float32}, XYZ{Float64})
        b = @inferred(convert(Array{T}, a))
        rb = @inferred(reinterpret(eltype(T), b))
        @test isa(rb, Array{eltype(T),3})
        @test size(rb) == (3,4,5)
        c = copy(rb)
        rc = @inferred(reinterpret(T, c))
        @test isa(rc, Array{T,2})
        @test size(rc) == (4,5)
    end
    for a in (rand(RGB{U8}, 4), rand(RGB{U8}, (4,5)))
        b = @inferred(reinterpret(HSV{Float32}, float32.(a)))
        @test isa(b, Array{HSV{Float32}})
        @test ndims(b) == ndims(a)
    end
    # Transparent color
    a = rand(ARGB{U8}, (4,5))
    for T in (ARGB{U8}, AHSV{Float32}, AXYZ{Float64})
        b = @inferred(convert(Array{T}, a))
        rb = @inferred(reinterpret(eltype(T), b))
        @test isa(rb, Array{eltype(T),3})
        @test size(rb) == (4,4,5)
        c = copy(rb)
        rc = @inferred(reinterpret(T, c))
        @test isa(rc, Array{T,2})
        @test size(rc) == (4,5)
    end
    # RGB1/RGB4
    a = rand(RGB{U8}, (4,5))
    for T in (RGB1{U8},RGB4{Float32})
        b = @inferred(convert(Array{T}, a))
        rb = @inferred(reinterpret(eltype(T), b))
        @test isa(rb, Array{eltype(T),3})
        @test size(rb) == (4,4,5)
        c = copy(rb)
        rc = @inferred(reinterpret(T, c))
        @test isa(rc, Array{T,2})
        @test size(rc) == (4,5)
    end
    a = [RGB(1,0,0) RGB(0,0,1);
         RGB(0,1,0) RGB(1,1,1)]
    @test reinterpret(U8, a) == cat(3, [1 0; 0 1; 0 0], [0 1; 0 1; 1 1])
    b = convert(Array{BGR{U8}}, a)
    @test reinterpret(U8, b) == cat(3, [0 0; 0 1; 1 0], [1 1; 0 1; 0 1])
    # RGB24, ARGB32
    for sz in ((4,), (4,5))
        a = rand(UInt32, sz)
        for T in (RGB24, ARGB32)
            b = @inferred(reinterpret(T, a))
            @test isa(b, Array{T,length(sz)})
            @test size(b) == sz
            @test eltype(b) == T
            @test reinterpret(UInt32, b) == a
        end
    end

    # indeterminate type tests
    a = Array(RGB{AbstractFloat},3)
    @test_throws ErrorException reinterpret(Float64, a)
    Tu = TypeVar(:T)
    a = Array(RGB{Tu},3)
    @test_throws ErrorException reinterpret(Float64, a)

    # Invalid conversions
    a = rand(UInt8, 4,5)
    ret = @test_throws ArgumentError reinterpret(Gray, a)
    @test contains(ret.value.msg, "ufixedview")
    @test contains(ret.value.msg, "reinterpret")
    a = rand(Int8, 4,5)
    ret = @test_throws ArgumentError reinterpret(Gray, a)
    @test contains(ret.value.msg, " Fixed")
    @test contains(ret.value.msg, "reinterpret")

end

@testset "convert" begin
    a = [RGB(1,0,0) RGB(0,0,1);
         RGB(0,1,0) RGB(1,1,1)]
    c = @inferred(convert(Array{BGR}, a))
    @test eltype(c) == BGR{U8}
    c = @inferred(convert(Array{BGR{Float32}}, a))
    @test eltype(c) == BGR{Float32}
    c = @inferred(convert(Array{Lab}, a))
    @test eltype(c) == Lab{Float32}
    for a in (rand(Float32, (4,5)),
              bitrand(4,5))
        b = @inferred(convert(Array{Gray}, a))
        @test eltype(b) == Gray{eltype(a)}
        b = @inferred(convert(Array{Gray{U8}}, a))
        @test eltype(b) == Gray{U8}
    end
end

@testset "eltype conversion" begin
    @test float32(Float64) == Float32
    @test float32(U8)      == Float32
    @test float64(RGB{U8}) == RGB{Float64}

    a = [RGB(1,0,0) RGB(0,0,1);
         RGB(0,1,0) RGB(1,1,1)]
    @test eltype(a) == RGB{U8}
    @test eltype(u8.(a))       == RGB{U8}
    @test eltype(ufixed8.(a))  == RGB{U8}
    @test eltype(ufixed10.(a)) == RGB{UFixed10}
    @test eltype(ufixed12.(a)) == RGB{UFixed12}
    @test eltype(ufixed14.(a)) == RGB{UFixed14}
    @test eltype(ufixed16.(a)) == RGB{U16}
    @test eltype(u16.(a))      == RGB{U16}
#    @test eltype(float16.(a)) == RGB{Float16}
    @test eltype(float32.(a)) == RGB{Float32}
    @test eltype(float64.(a)) == RGB{Float64}

    a = U8[0.1,0.2,0.3]
    @test eltype(a) == U8
    @test eltype(u8.(a))       == U8
    @test eltype(ufixed8.(a))  == U8
    @test eltype(ufixed10.(a)) == UFixed10
    @test eltype(ufixed12.(a)) == UFixed12
    @test eltype(ufixed14.(a)) == UFixed14
    @test eltype(ufixed16.(a)) == U16
    @test eltype(u16.(a))      == U16
#    @test eltype(float16.(a)) == Float16
    @test eltype(float32.(a)) == Float32
    @test eltype(float64.(a)) == Float64

    a = OffsetArray(U8[0.1,0.2,0.3], -1:1)
    @test eltype(a) == U8
    @test eltype(u8.(a))       == U8
    @test eltype(ufixed8.(a))  == U8
    @test eltype(ufixed10.(a)) == UFixed10
    @test eltype(ufixed12.(a)) == UFixed12
    @test eltype(ufixed14.(a)) == UFixed14
    @test eltype(ufixed16.(a)) == U16
    @test eltype(u16.(a))      == U16
#    @test eltype(float16.(a)) == Float16
    @test eltype(float32.(a)) == Float32
    @test eltype(float64.(a)) == Float64
    @test indices(float32.(a)) == (-1:1,)
end

nothing
