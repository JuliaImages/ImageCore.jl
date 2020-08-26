Base.@deprecate_binding ChannelView channelview

export ColorView

struct ColorView{C<:Colorant,N,A<:AbstractArray} <: AbstractArray{C,N}
    parent::A

    function ColorView{C,N,A}(parent::AbstractArray{T}) where {C,N,A,T<:Number}
        n = length(colorview_size(C, parent))
        n == N || throw(DimensionMismatch("for an $N-dimensional ColorView with color type $C, input dimensionality should be $n instead of $(ndims(parent))"))
        checkdim1(C, axes(parent))
        Base.depwarn("ColorView{C}(A) is deprecated, use colorview(C, A)", :ColorView)
        colorview(C, A)
    end
end

function ColorView{C}(A::AbstractArray) where C<:Colorant
    Base.depwarn("ColorView{C}(A) is deprecated, use colorview(C, A)", :ColorView)
    colorview(C, A)
end

ColorView(parent::AbstractArray) = error("must specify the colortype, use colorview(C, A)")

Base.@deprecate_binding squeeze1 true

import Base: convert

function cname(::Type{C}) where C
    io = IOBuffer()
    ColorTypes.colorant_string_with_eltype(io, C)
    return String(take!(io))
end

function convert(::Type{Array{Cdest}}, img::AbstractArray{Csrc,n}) where {Cdest<:Colorant,n,Csrc<:Colorant}
    Base.depwarn("`convert(Array{$(cname(Cdest))}, img)` is deprecated, use $(cname(Cdest)).(img) instead", :convert)
    Cdest.(img)
end

function convert(::Type{Array{Cdest}}, img::AbstractArray{T,n}) where {Cdest<:Color1,n,T<:Real}
    Base.depwarn("`convert(Array{$(cname(Cdest))}, img)` is deprecated, use $(cname(Cdest)).(img) instead", :convert)
    Cdest.(img)
end

function convert(::Type{OffsetArray{Cdest,n,A}}, img::AbstractArray{Csrc,n}) where {Cdest<:Colorant,n, A <:AbstractArray,Csrc<:Colorant}
    Base.depwarn("`convert(OffsetArray{$(cname(Cdest))}, img)` is deprecated, use $(cname(Cdest)).(img) instead", :convert)
    Cdest.(img)
end

convert(::Type{OffsetArray{Cdest,n,A}}, img::OffsetArray{Cdest,n,A}) where {Cdest<:Colorant,n, A <:AbstractArray} = img

# a perhaps "permanent" deprecation
Base.@deprecate_binding permuteddimsview PermutedDimsArray
