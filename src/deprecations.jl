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

const _explain =
"""will soon switch to returning an array with non-concrete element type, which adds flexibility but
   with great cost to performance. To maintain the current behavior, use """
function convert(::Type{Array{Cdest}}, img::AbstractArray{Csrc,n}) where {Cdest<:Colorant,n,Csrc<:Colorant}
    if isconcretetype(Cdest)
        # This mimics the Base implementation
        return img isa Array{Cdest} ? img : Array{Cdest}(img)
    end
    Base.depwarn("`convert(Array{$(cname(Cdest))}, img)` $_explain $(cname(Cdest)).(img) instead", :convert)
    convert(Array, Cdest.(img))
end

function convert(::Type{Array{Cdest}}, img::AbstractArray{T,n}) where {Cdest<:Color1,n,T<:Real}
    if isconcretetype(Cdest)
        return img isa Array{Cdest} ? img : Array{Cdest}(img)
    end
    Base.depwarn("`convert(Array{$(cname(Cdest))}, img)` $_explain $(cname(Cdest)).(img) instead", :convert)
    convert(Array, Cdest.(img))
end

function convert(::Type{OffsetArray{Cdest,n,A}}, img::AbstractArray{Csrc,n}) where {Cdest<:Colorant,n, A <:AbstractArray,Csrc<:Colorant}
    if isconcretetype(Cdest) && isconcretetype(A) && eltype(A) === Cdest
        return img isa OffsetArray{Cdest,n,A} ? img : (img isa OffsetArray ? OffsetArray(A(Cdest.(parent(img))), axes(img)) : OffsetArray(A(Cdest.(img)), axes(img)))
    end
    if img isa OffsetArray
        Base.depwarn("`convert(OffsetArray{$(cname(Cdest))}, img)` $_explain $(cname(Cdest)).(img) instead", :convert)
    else
        Base.depwarn("`convert(OffsetArray{$(cname(Cdest))}, img)` $_explain OffsetArray($(cname(Cdest)).(img)) instead", :convert)
    end
    OffsetArray(Cdest.(img), axes(img))
end

convert(::Type{OffsetArray{Cdest,n,A}}, img::OffsetArray{Cdest,n,A}) where {Cdest<:Colorant,n, A <:AbstractArray} = img

# a perhaps "permanent" deprecation
Base.@deprecate_binding permuteddimsview PermutedDimsArray
