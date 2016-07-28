__precompile__()

module ImagesCore

using Colors, FixedPointNumbers, MappedArrays
using Colors: Fractional

using Base: tail, @pure

export
    ## Types
    ChannelView,
    ColorView,
    ## functions
    # views
    channelview,
    colorview,
    permuteddimsview,
    rawview,
    ufixedview,
    # conversions
#    float16,
    float32,
    float64,
    u8,
    ufixed8,
    ufixed10,
    ufixed12,
    ufixed14,
    ufixed16,
    u16,
    # traits
    assert_timedim_last,
    coords_spatial,
    height,
    indices_spatial,
    nimages,
    pixelspacing,
    sdims,
    size_spatial,
    spacedirections,
    width,
    widthheight

include("colorchannels.jl")
include("convert_reinterpret.jl")
include("traits.jl")
include("deprecated.jl")

"""
    rawview(img::AbstractArray{FixedPoint})

returns a "view" of `img` where the values are interpreted in terms of
their raw underlying storage. For example, if `img` is an `Array{U8}`,
the view will act like an `Array{UInt8}`.
"""
rawview{T<:FixedPoint}(a::AbstractArray{T}) = mappedarray((x->x.i, y->T(y,0)), a)
rawview{T<:Real}(a::AbstractArray{T}) = a

"""
    ufixedview([T], img::AbstractArray{Unsigned})

returns a "view" of `img` where the values are interpreted in terms of
`UFixed` number types. For example, if `img` is an `Array{UInt8}`, the
view will act like an `Array{UFixed8}`.  Supply `T` if the element
type of `img` is `UInt16`, to specify whether you want a `UFixed10`,
`UFixed12`, `UFixed14`, or `UFixed16` result.
"""
ufixedview{T<:FixedPoint,S<:Unsigned}(::Type{T}, a::AbstractArray{S}) = mappedarray((y->T(y,0),x->x.i), a)
ufixedview(a::AbstractArray{UInt8}) = ufixedview(U8, a)
ufixedview{T<:UFixed}(::Type{T}, a::AbstractArray{T}) = a

"""
    permuteddimsview(A, perm)

returns a "view" of `A` with its dimensions permuted as specified by
`perm`. This is like `permutedims`, except that it produces a view
rather than a copy of `A`; consequently, any manipulations you make to
the output will be mirrored in `A`. Compared to the copy, the view is
much faster to create, but generally slower to use.
"""
permuteddimsview(A, perm) = Base.PermutedDimsArrays.PermutedDimsArray(A, perm)

end ## module
