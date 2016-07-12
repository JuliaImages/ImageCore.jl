using Base: @pure
using Colors

typealias Color1{N,T} Color{T,1}
typealias Color3{N,T} Color{T,3}
typealias AColor{N,C,T} AlphaColor{C,T,N}
typealias ColorA{N,C,T} ColorAlpha{C,T,N}

const squeeze1 = true  # Gray images don't add a new dimension (of size 1) for color

immutable ChannelView{T,N,A<:AbstractArray} <: AbstractArray{T,N}
    parent::A

    function ChannelView{C<:Colorant}(parent::AbstractArray{C})
        n = length(channelviewsize(parent))
        n == N || throw(DimensionMismatch("for an $N-dimensional ChannelView with color type $C, input dimensionality should be $n instead of $(ndims(parent))"))
        new(parent)
    end
end

# Creating a ChannelView in a type-stable fashion requires use of tuples to compute N+1
ChannelView(parent::AbstractArray) = _channelview(parent, channelviewsize(parent))
function _channelview{C<:Colorant,N}(parent::AbstractArray{C}, sz::NTuple{N,Int})
    ChannelView{eltype(C),N,typeof(parent)}(parent)
end

@inline channelviewsize{C<:Colorant}(parent::AbstractArray{C}) = (length(C), size(parent)...)
if squeeze1
    @inline channelviewsize{C<:Color1}(parent::AbstractArray{C}) = size(parent)
end

Base.parent(A::ChannelView) = A.parent
parenttype{T,N,A}(::Type{ChannelView{T,N,A}}) = A
@inline Base.size(A::ChannelView) = channelviewsize(parent(A))
# Base.linearindexing{T<:ChannelView}(::Type{T}) = Base.linearindexing(parenttype(T))

# colortype(A::ChannelView) = eltype(parent(A))

Base.@propagate_inbounds function Base.getindex{T,N}(A::ChannelView{T,N}, I::Vararg{Int,N})
    P = parent(A)
    Ic, Ia = indexsplit(P, I)
    @boundscheck checkbounds(P, Ia...)
    @inbounds ret = getfield(P[Ia...], colorperm(eltype(P))[Ic])
    ret
end

Base.@propagate_inbounds function Base.setindex!{T,N}(A::ChannelView{T,N}, val, I::Vararg{Int,N})
    P = parent(A)
    Ic, Ia = indexsplit(P, I)
    @boundscheck checkbounds(P, Ia...)
    @inbounds c = P[Ia...]
    @inbounds P[Ia...] = setchannel(c, val, Ic)
    val
end

@inline function indexsplit{C<:Colorant}(A::AbstractArray{C}, I)
    Ic, Ia = I[1], tail(I)
    @boundscheck checkindex(Bool, 1:length(C), Ic) || Base.throw_boundserror(A, I)
    Ic, Ia
end

if squeeze1
    @inline indexsplit{C<:Color1}(A::AbstractArray{C}, I) = 1, I
end

function Base.similar{S,N}(A::ChannelView, ::Type{S}, dims::NTuple{N,Int})
    P = parent(A)
    check_ncolorchan(P, dims)
    ChannelView(similar(P, base_colorant_type(eltype(P)){S}, parentsize(P, dims)))
end

function check_ncolorchan{C<:Colorant}(::AbstractArray{C}, dims)
    dims[1] == length(C) || throw(DimensionMismatch("new array has $(dims[1]) color channels, must have $(length(C))"))
end

parentsize{C<:Colorant}(::AbstractArray{C}, dims) = tail(dims)

if squeeze1
    check_ncolorchan{C<:Color1}(::AbstractArray{C}, dims) = nothing
    parentsize{C<:Color1}(::AbstractArray{C}, dims) = dims
end

## Low-level color utilities

colorperm{C<:Color1}(::Type{C}) = (1,)
colorperm{C<:Color3}(::Type{C}) = (1,2,3)
colorperm{C<:BGR }(::Type{C}) = (3,2,1)
colorperm{C<:RGB1}(::Type{C}) = (2,3,4)
@pure colorperm{CA<:ColorA}(::Type{CA}) = (colorperm(base_color_type(CA))..., length(CA))
@pure colorperm{AC<:AColor}(::Type{AC}) = (map(n->n+1, colorperm(base_color_type(AC)))..., 1)

# setchannel (similar to setfield!)
# These don't check bounds since that's already done
"""
    setchannel(c, val, idx)

Equivalent to:

    cc = copy(c)
    cc[idx] = val
    cc

for immutable colors. `idx` is interpreted in the sense of constructor
arguments, so `setchannel(c, 0.5, 1)` would set red color channel for
any `c::AbstractRGB`, even if red isn't the first field in the type.
"""
setchannel{T}(c::Colorant{T,1}, val, Ic::Int) = typeof(c)(val)

setchannel{C,T}(c::TransparentColor{C,T,2}, val, Ic::Int) =
    typeof(c)(ifelse(Ic==1,val,comp1(c)),
              ifelse(Ic==2,val,alpha(c)))

setchannel{T}(c::Colorant{T,3}, val, Ic::Int) = typeof(c)(ifelse(Ic==1,val,comp1(c)),
                                                          ifelse(Ic==2,val,comp2(c)),
                                                          ifelse(Ic==3,val,comp3(c)))
setchannel{C,T}(c::TransparentColor{C,T,4}, val, Ic::Int) =
    typeof(c)(ifelse(Ic==1,val,comp1(c)),
              ifelse(Ic==2,val,comp2(c)),
              ifelse(Ic==3,val,comp3(c)),
              ifelse(Ic==4,val,alpha(c)))
