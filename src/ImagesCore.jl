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
    u16

include("colorchannels.jl")
include("convert_reinterpret.jl")

"""
    rawview(img::AbstractArray{FixedPoint})

returns a "view" of `img` where the values are interpreted in terms of
their raw underlying storage. For example, if `img` is an `Array{U8}`,
the view will act like an `Array{UInt8}`.
"""
rawview{T<:FixedPoint}(a::AbstractArray{T}) = mappedarray((x->x.i, y->T(y,0)), a)

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
