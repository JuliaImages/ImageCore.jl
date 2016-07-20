module ImagesCore

using Colors, FixedPointNumbers, MappedArrays
using Colors: Fractional

using Base: tail, @pure

export
    ChannelView,
    ColorView,
    rawview

include("colorchannels.jl")
"""
    rawview(img::AbstractArray{FixedPoint})

returns a "view" of `img` where the values are interpreted in terms of
their raw underlying storage. For example, if `img` is an `Array{U8}`,
the view will act like an `Array{UInt8}`.
"""
rawview{T<:FixedPoint}(a::AbstractArray{T}) = mappedarray((x->x.i, y->T(y,0)), a)

end ## module
