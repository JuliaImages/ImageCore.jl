__precompile__()

module ImageCore

using Colors, FixedPointNumbers, MappedArrays, Graphics, ShowItLikeYouBuildIt
using OffsetArrays # for show.jl
using ColorTypes: colorant_string
using Colors: Fractional

using Base: tail, @pure, Indices

import Graphics: width, height

typealias AbstractGray{T} Color{T,1}
typealias RealLike Union{Real,AbstractGray}

export
    ## Types
    ChannelView,
    ColorView,
    StackedView,
    ## constants
    zeroarray,
    ## functions
    # views
    channelview,
    colorview,
    permuteddimsview,
    rawview,
    normedview,
    # conversions
#    float16,
    float32,
    float64,
    n0f8,
    n6f10,
    n4f12,
    n2f14,
    n0f16,
    # mapping values
    clamp01,
    clamp01nan,
    colorsigned,
    scaleminmax,
    scalesigned,
    takemap,
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
include("stackedviews.jl")
include("convert_reinterpret.jl")
include("traits.jl")
include("map.jl")
include("functions.jl")
include("show.jl")
include("deprecated.jl")

"""
    rawview(img::AbstractArray{FixedPoint})

returns a "view" of `img` where the values are interpreted in terms of
their raw underlying storage. For example, if `img` is an `Array{N0f8}`,
the view will act like an `Array{UInt8}`.
"""
rawview{T<:FixedPoint}(a::AbstractArray{T}) = mappedarray((reinterpret, y->T(y,0)), a)
rawview{T<:FixedPoint}(a::Array{T}) = reinterpret(FixedPointNumbers.rawtype(T), a)
rawview{T<:Real}(a::AbstractArray{T}) = a

"""
    normedview([T], img::AbstractArray{Unsigned})

returns a "view" of `img` where the values are interpreted in terms of
`Normed` number types. For example, if `img` is an `Array{UInt8}`, the
view will act like an `Array{N0f8}`.  Supply `T` if the element
type of `img` is `UInt16`, to specify whether you want a `N6f10`,
`N4f12`, `N2f14`, or `N0f16` result.
"""
normedview{T<:FixedPoint,S<:Unsigned}(::Type{T}, a::AbstractArray{S}) = mappedarray((y->T(y,0),reinterpret), a)
normedview{T<:FixedPoint,S<:Unsigned}(::Type{T}, a::Array{S}) = reinterpret(T, a)
normedview{T<:Normed}(::Type{T}, a::AbstractArray{T}) = a
normedview(a::AbstractArray{UInt8}) = normedview(N0f8, a)
normedview{T<:Normed}(a::AbstractArray{T}) = a

"""
    permuteddimsview(A, perm)

returns a "view" of `A` with its dimensions permuted as specified by
`perm`. This is like `permutedims`, except that it produces a view
rather than a copy of `A`; consequently, any manipulations you make to
the output will be mirrored in `A`. Compared to the copy, the view is
much faster to create, but generally slower to use.
"""
permuteddimsview(A, perm) = Base.PermutedDimsArrays.PermutedDimsArray(A, perm)

# Support transpose
Base.transpose{C<:Colorant}(a::AbstractMatrix{C}) = permutedims(a, (2,1))
function Base.transpose{C<:Colorant}(a::AbstractVector{C})
    ind = indices(a, 1)
    out = similar(Array{C}, (oftype(ind, Base.OneTo(1)), ind))
    outr = reshape(out, ind)
    copy!(outr, a)
    out
end

Base.ctranspose{C<:Colorant}(a::AbstractMatrix{C}) = transpose(a)
Base.ctranspose{C<:Colorant}(a::AbstractVector{C}) = transpose(a)

end ## module
