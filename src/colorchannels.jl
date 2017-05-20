# Implements two view types for "converting" between arrays-of-colors
# and arrays-of-numbers (with the "first dimension" corresponding to
# color channels)
#  - ChannelView: view a color array as if it were an array of numbers
#  - ColorView: view an array of numbers as if it were an array of colors
# Examples:
#    img is a m-by-n Array{RGB{Float32}}
#    ChannelView(img) is a 3-by-m-by-n AbstractArray{Float32}
#
#    buffer is a 3-by-m-by-n Array{N0f8}
#    ColorView{RGB}(buffer) is an m-by-n AbstractArray{RGB{N0f8}}

# "First dimension" applies to colors like RGB; by default, Gray
# images don't use a whole dimension (of size 1) just to encode
# colors. But it's easy to change that behavior with the flip of a
# switch:
const squeeze1 = true # when true, don't use a dimension for the color channel of grayscale

@compat Color1{T} = Colorant{T,1}
@compat Color2{T} = Colorant{T,2}
@compat Color3{T} = Colorant{T,3}
@compat Color4{T} = Colorant{T,4}
@compat AColor{N,C,T} = AlphaColor{C,T,N}
@compat ColorA{N,C,T} = ColorAlpha{C,T,N}
const NonparametricColors = Union{RGB24,ARGB32,Gray24,AGray32}

## ChannelView

immutable ChannelView{T,N,A<:AbstractArray} <: AbstractArray{T,N}
    parent::A

    function (::Type{ChannelView{T,N,A}}){T,N,A,C<:Colorant}(parent::AbstractArray{C})
        n = length(channelview_indices(parent))
        n == N || throw(DimensionMismatch("for an $N-dimensional ChannelView with color type $C, input dimensionality should be $n instead of $(ndims(parent))"))
        new{T,N,A}(parent)
    end
end


"""
    ChannelView(A)

creates a "view" of the Colorant array `A`, splitting out (if
necessary) the separate color channels of `eltype(A)` into a new first
dimension. For example, if `A` is a m-by-n RGB{N0f8} array,
`ChannelView(A)` will return a 3-by-m-by-n N0f8 array. Color spaces with
a single element (i.e., grayscale) do not add a new first dimension of
`A`.

Of relevance for types like RGB and BGR, the channels of the returned
array will be in constructor-argument order, not memory order (see
`reinterpret` if you want to use memory order).

The opposite transformation is implemented by [`ColorView`](@ref). See
also [`channelview`](@ref).
"""
ChannelView(parent::AbstractArray) = _channelview(parent, channelview_indices(parent))
function _channelview{C<:Colorant,N}(parent::AbstractArray{C}, inds::Indices{N})
    # Creating a ChannelView in a type-stable fashion requires use of tuples to compute N+1
    ChannelView{eltype(C),N,typeof(parent)}(parent)
end

@compat Color1Array{C<:Color1,N} = AbstractArray{C,N}
@compat ChannelView1{T,N,A<:Color1Array} = ChannelView{T,N,A}

Base.parent(A::ChannelView) = A.parent
parenttype{T,N,A}(::Type{ChannelView{T,N,A}}) = A
@inline Base.size(A::ChannelView)    = channelview_size(parent(A))
@inline Base.indices(A::ChannelView) = channelview_indices(parent(A))

# Can be IndexLinear for grayscale (1-channel images), otherwise must be IndexCartesian
@compat Base.IndexStyle{T<:ChannelView1}(::Type{T}) = IndexStyle(parenttype(T))

# colortype(A::ChannelView) = eltype(parent(A))

Base.@propagate_inbounds function Base.getindex{T,N}(A::ChannelView{T,N}, I::Vararg{Int,N})
    @boundscheck checkbounds(A, I...)
    P = parent(A)
    Ic, Ia = indexsplit(P, I)
    @inbounds ret = tuplify(P[Ia...])[Ic]
    ret
end

Base.@propagate_inbounds function Base.getindex{T}(A::ChannelView1{T,1}, i::Int) # ambiguity
    @boundscheck checkbounds(A, i)
    @inbounds ret = eltype(A)(parent(A)[i])
    ret
end
Base.@propagate_inbounds function Base.getindex(A::ChannelView1, i::Int)
    @boundscheck checkbounds(A, i)
    @inbounds ret = eltype(A)(parent(A)[i])
    ret
end

Base.@propagate_inbounds function Base.setindex!{T,N}(A::ChannelView{T,N}, val, I::Vararg{Int,N})
    @boundscheck checkbounds(A, I...)
    P = parent(A)
    Ic, Ia = indexsplit(P, I)
    @inbounds c = P[Ia...]
    @inbounds P[Ia...] = setchannel(c, val, Ic)
    val
end

Base.@propagate_inbounds function Base.setindex!{T}(A::ChannelView1{T,1}, val, i::Int) # amb
    @boundscheck checkbounds(A, i)
    @inbounds parent(A)[i] = val
    val
end
Base.@propagate_inbounds function Base.setindex!(A::ChannelView1, val, i::Int)
    @boundscheck checkbounds(A, i)
    @inbounds parent(A)[i] = val
    val
end

function Base.similar{S,N}(A::ChannelView, ::Type{S}, dims::NTuple{N,Int})
    P = parent(A)
    check_ncolorchan(P, dims)
    ChannelView(similar(P, base_colorant_type(eltype(P)){S}, chanparentsize(P, dims)))
end

## ColorView

"""
    ColorView{C}(A)

creates a "view" of the numeric array `A`, interpreting the first
dimension of `A` as if were the channels of a Colorant `C`. The first
dimension must have the proper number of elements for the constructor
of `C`. For example, if `A` is a 3-by-m-by-n N0f8 array,
`ColorView{RGB}(A)` will create an m-by-n array with element type
`RGB{N0f8}`. Color spaces with a single element (i.e., grayscale) do not
"consume" the first dimension of `A`.

Of relevance for types like RGB and BGR, the elements of `A`
are interpreted in constructor-argument order, not memory order (see
`reinterpret` if you want to use memory order).

The opposite transformation is implemented by
[`ChannelView`](@ref). See also [`colorview`](@ref).
"""
immutable ColorView{C<:Colorant,N,A<:AbstractArray} <: AbstractArray{C,N}
    parent::A

    function (::Type{ColorView{C,N,A}}){C,N,A,T<:Number}(parent::AbstractArray{T})
        n = length(colorview_size(C, parent))
        n == N || throw(DimensionMismatch("for an $N-dimensional ColorView with color type $C, input dimensionality should be $n instead of $(ndims(parent))"))
        checkdim1(C, indices(parent))
        new{C,N,A}(parent)
    end
end

function (::Type{ColorView{C}}){C<:Colorant,T<:Number}(parent::AbstractArray{T})
    CT = ccolor_number(C, T)
    _ColorView(CT, eltype(CT), parent)
end
function _ColorView{C<:Colorant,T<:Number}(::Type{C}, ::Type{T}, parent::AbstractArray{T})
    # Creating a ColorView in a type-stable fashion requires use of tuples to compute N+1
    _colorview(C, parent, colorview_size(C, parent))
end
function _colorview{C,N}(::Type{C}, parent::AbstractArray, sz::NTuple{N,Int})
    ColorView{C,N,typeof(parent)}(parent)
end

ColorView(::AbstractArray) = error("specify the desired colorspace with ColorView{C}(parent)")

Base.parent(A::ColorView) = A.parent
@inline Base.size(A::ColorView) = colorview_size(eltype(A), parent(A))
@inline Base.indices(A::ColorView) = colorview_indices(eltype(A), parent(A))

@compat Base.IndexStyle{C<:Color1,N,A<:AbstractArray}(::Type{ColorView{C,N,A}}) = IndexStyle(A)
@compat Base.IndexStyle{V<:ColorView}(::Type{V}) = IndexCartesian()

Base.@propagate_inbounds function Base.getindex{C,N}(A::ColorView{C,N}, I::Vararg{Int,N})
    P = parent(A)
    @boundscheck Base.checkbounds_indices(Bool, parentindices(C, indices(P)), I) || Base.throw_boundserror(A, I)
    @inbounds ret = C(getchannels(P, C, I)...)
    ret
end

Base.@propagate_inbounds function Base.setindex!{C,N}(A::ColorView{C,N}, val::C, I::Vararg{Int,N})
    P = parent(A)
    @boundscheck Base.checkbounds_indices(Bool, parentindices(C, indices(P)), I) || Base.throw_boundserror(A, I)
    setchannels!(P, val, I)
    val
end
Base.@propagate_inbounds function Base.setindex!{C,N}(A::ColorView{C,N}, val, I::Vararg{Int,N})
    setindex!(A, convert(C, val), I...)
end

# A grayscale ColorView can be LinearFast, so support this too
Base.@propagate_inbounds function Base.getindex{C<:Color1,N}(A::ColorView{C,N}, i::Int)
    P = parent(A)
    @boundscheck checkindex(Bool, linearindices(P), i) || Base.throw_boundserror(A, i)
    @inbounds ret = C(getchannels(P, C, i)[1])
    ret
end
Base.@propagate_inbounds function Base.setindex!{C<:Color1}(A::ColorView{C,1}, val::C, i::Int)  # for ambiguity resolution
    P = parent(A)
    @boundscheck checkindex(Bool, linearindices(P), i) || Base.throw_boundserror(A, i)
    setchannels!(P, val, i)
    val
end
Base.@propagate_inbounds function Base.setindex!{C<:Color1,N}(A::ColorView{C,N}, val::C, i::Int)
    P = parent(A)
    @boundscheck checkindex(Bool, linearindices(P), i) || Base.throw_boundserror(A, i)
    setchannels!(P, val, i)
    val
end
Base.@propagate_inbounds function Base.setindex!{C<:Color1,N}(A::ColorView{C,N}, val, i::Int)
    setindex!(A, convert(C, val), i)
end

function Base.similar{S<:Colorant,N}(A::ColorView, ::Type{S}, dims::NTuple{N,Int})
    P = parent(A)
    ColorView{S}(similar(P, celtype(eltype(S), eltype(P)), colparentsize(S, dims)))
end
function Base.similar{S<:Number,N}(A::ColorView, ::Type{S}, dims::NTuple{N,Int})
    P = parent(A)
    similar(P, S, dims)
end
function Base.similar{S<:NonparametricColors,N}(A::ColorView, ::Type{S}, dims::NTuple{N,Int})
    P = parent(A)
    similar(P, S, dims)
end

## Construct a view that's conceptually equivalent to a ChannelView or ColorView,
## but which may be simpler (i.e., strip off a wrapper or use reinterpret)

"""
    channelview(A)

returns a view of `A`, splitting out (if necessary) the color channels
of `A` into a new first dimension. This is almost identical to
`ChannelView(A)`, except that if `A` is a `ColorView`, it will simply
return the parent of `A`, or will use `reinterpret` when appropriate.
Consequently, the output may not be a [`ChannelView`](@ref) array.

Of relevance for types like RGB and BGR, the channels of the returned
array will be in constructor-argument order, not memory order (see
`reinterpret` if you want to use memory order).
"""
channelview{T<:Number}(A::AbstractArray{T}) = A
channelview(A::AbstractArray) = ChannelView(A)
channelview(A::ColorView) = parent(A)
channelview{T}(A::Array{RGB{T}}) = reinterpret(T, A)
channelview{C<:AbstractRGB}(A::Array{C}) = ChannelView(A) # BGR, RGB1, etc don't satisfy conditions
channelview{C<:Color}(A::Array{C}) = reinterpret(eltype(C), A)
channelview{C<:ColorAlpha}(A::Array{C}) = _channelview(base_color_type(C), A)
_channelview(::Type{RGB}, A) = reinterpret(eltype(eltype(A)), A)
_channelview{C<:AbstractRGB}(::Type{C}, A) = ChannelView(A)
_channelview{C<:Color}(::Type{C}, A) = reinterpret(eltype(eltype(A)), A)


"""
    colorview(C, A)

returns a view of the numeric array `A`, interpreting successive
elements of `A` as if they were channels of Colorant `C`. This is
almost identical to `ColorView{C}(A)`, except that if `A` is a
`ChannelView`, it will simply return the parent of `A`, or use
`reinterpret` when appropriate. Consequently, the output may not be a
[`ColorView`](@ref) array.

Of relevance for types like RGB and BGR, the elements of `A` are
interpreted in constructor-argument order, not memory order (see
`reinterpret` if you want to use memory order).

# Example
```jl
A = rand(3, 10, 10)
img = colorview(RGB, A)
```
"""
colorview{C<:Colorant,T<:Number}(::Type{C}, A::AbstractArray{T}) =
    _ccolorview(ccolor_number(C, T), A)
_ccolorview{T<:Number,C<:Colorant}(::Type{C}, A::AbstractArray{T}) = ColorView{C}(A)
_ccolorview{T<:Number,C<:RGB{T}}(::Type{C}, A::Array{T}) = reinterpret(C, A)
_ccolorview{T<:Number,C<:AbstractRGB}(::Type{C}, A::Array{T}) = ColorView{C}(A)
_ccolorview{T<:Number,C<:Color{T}}(::Type{C}, A::Array{T}) = reinterpret(C, A)
_ccolorview{T<:Number,C<:ColorAlpha}(::Type{C}, A::Array{T}) =
    _colorviewalpha(base_color_type(C), C, eltype(C), A)
_colorviewalpha{C<:RGB,CA,T}(::Type{C}, ::Type{CA}, ::Type{T}, A::Array{T}) =
    reinterpret(CA, A)
_colorviewalpha{C<:AbstractRGB,CA}(::Type{C}, ::Type{CA}, ::Type, A::Array) =
    ColorView{CA}(A)
_colorviewalpha{C<:Color,CA,T}(::Type{C}, ::Type{CA}, ::Type{T}, A::Array{T}) =
    reinterpret(CA, A)

colorview{C1<:Colorant,C2<:Colorant}(::Type{C1}, A::AbstractArray{C2}) =
    colorview(C1, channelview(A))

function colorview{C<:Colorant}(::Type{C}, A::ChannelView)
    P = parent(A)
    C0 = ccolor_number(C, eltype(A))
    _colorview_chanview(C0, base_colorant_type(C), base_colorant_type(eltype(P)), P, A)
end
_colorview_chanview{T<:Number,C0<:Colorant{T},C<:Colorant}(::Type{C0}, ::Type{C}, ::Type{C}, P, A::AbstractArray{T}) = P
_colorview_chanview{C0}(::Type{C0}, ::Type, ::Type, P, A) =
    _ccolorview(ccolor_number(C0, eltype(A)), A)

"""
    colorview(C, gray1, gray2, ...) -> imgC

Combine numeric/grayscale images `gray1`, `gray2`, etc., into the
separate color channels of an array `imgC` with element type
`C<:Colorant`.

As a convenience, the constant `zeroarray` fills in an array of
matched size with all zeros.

# Example
```julia
imgC = colorview(RGB, r, zeroarray, b)
```

creates an image with `r` in the red chanel, `b` in the blue channel,
and nothing in the green channel.

See also: [`StackedView`](@ref).
"""
function colorview{C<:Colorant}(::Type{C}, gray1, gray2, grays...)
    T = _colorview_type(eltype(C), promote_eleltype_all(gray1, gray2, grays...))
    sv = StackedView{T}(gray1, gray2, grays...)
    CT = base_colorant_type(C){T}
    colorview(CT, sv)
end

_colorview_type{T}(::Type{Any}, ::Type{T}) = T
_colorview_type{T1,T2}(::Type{T1}, ::Type{T2}) = T1

Base.@pure promote_eleltype_all(gray, grays...) = _promote_eleltype_all(beltype(eltype(gray)), grays...)
@inline function _promote_eleltype_all{T}(::Type{T}, gray, grays...)
    _promote_eleltype_all(promote_type(T, beltype(eltype(gray))), grays...)
end
_promote_eleltype_all{T}(::Type{T}) = T

beltype{T}(::Type{T}) = eltype(T)
beltype(::Type{Union{}}) = Union{}

## Tuple & indexing utilities

_size(A::AbstractArray) = map(length, indices(A))

# color->number
@inline channelview_size{C<:Colorant}(parent::AbstractArray{C}) = (length(C), _size(parent)...)
@inline channelview_indices{C<:Colorant}(parent::AbstractArray{C}) =
    _cvi(Base.OneTo(length(C)), indices(parent))
_cvi(rc, ::Tuple{}) = (rc,)
_cvi{R<:AbstractUnitRange}(rc, inds::Tuple{R,Vararg{R}}) = (convert(R, rc), inds...)
if squeeze1
    @inline channelview_size{C<:Color1}(parent::AbstractArray{C}) = _size(parent)
    @inline channelview_indices{C<:Color1}(parent::AbstractArray{C}) = indices(parent)
end

function check_ncolorchan{C<:Colorant}(::AbstractArray{C}, dims)
    dims[1] == length(C) || throw(DimensionMismatch("new array has $(dims[1]) color channels, must have $(length(C))"))
end
chanparentsize{C<:Colorant}(::AbstractArray{C}, dims) = tail(dims)
@inline colparentsize{C<:Colorant}(::Type{C}, dims) = (length(C), dims...)

channelview_dims_offset{C<:Colorant}(parent::AbstractArray{C}) = 1

if squeeze1
    check_ncolorchan{C<:Color1}(::AbstractArray{C}, dims) = nothing
    chanparentsize{C<:Color1}(::AbstractArray{C}, dims) = dims
    colparentsize{C<:Color1}(::Type{C}, dims) = dims
    channelview_dims_offset{C<:Color1}(parent::AbstractArray{C}) = 0
end

@inline indexsplit{C<:Colorant}(A::AbstractArray{C}, I) = I[1], tail(I)

if squeeze1
    @inline indexsplit{C<:Color1}(A::AbstractArray{C}, I) = 1, I
end

# number->color
@inline colorview_size{C<:Colorant}(::Type{C}, parent::AbstractArray) = tail(_size(parent))
@inline colorview_indices{C<:Colorant}(::Type{C}, parent::AbstractArray) = tail(indices(parent))
if squeeze1
    @inline colorview_size{C<:Color1}(::Type{C}, parent::AbstractArray) = _size(parent)
    @inline colorview_indices{C<:Color1}(::Type{C}, parent::AbstractArray) = indices(parent)
end

function checkdim1{C<:Colorant}(::Type{C}, inds)
    inds[1] == (1:length(C)) || throw(DimensionMismatch("dimension 1 must have indices 1:$(length(C)), got $(inds[1])"))
    nothing
end
if squeeze1
    checkdim1{C<:Color1}(::Type{C}, dims) = nothing
end

parentindices(::Type, inds) = tail(inds)
if squeeze1
    parentindices{C<:Color1}(::Type{C}, inds) = inds
end

celtype{T}(::Type{Any}, ::Type{T}) = T
celtype{T1,T2}(::Type{T1}, ::Type{T2}) = T1

## Low-level color utilities

tuplify(c::Color1) = (comp1(c),)
tuplify(c::Color3) = (comp1(c), comp2(c), comp3(c))
tuplify(c::Color2) = (comp1(c), alpha(c))
tuplify(c::Color4) = (comp1(c), comp2(c), comp3(c), alpha(c))

"""
    getchannels(P, C::Type, I)

Get a tuple of all channels needed to construct a Colorant of type `C`
from an `P::AbstractArray{<:Number}`.
"""
getchannels
if squeeze1
    @inline getchannels{C<:Color1}(P, ::Type{C}, I) = (@inbounds ret = (P[I...],); ret)
    @inline getchannels{C<:Color1}(P, ::Type{C}, I::Real) = (@inbounds ret = (P[I],); ret)
else
    @inline getchannels{C<:Color1}(P, ::Type{C}, I) = (@inbounds ret = (P[1, I...],); ret)
    @inline getchannels{C<:Color1}(P, ::Type{C}, I::Real) = (@inbounds ret = (P[1, I],); ret)
end
@inline function getchannels{C<:Color2}(P, ::Type{C}, I)
    @inbounds ret = (P[1,I...], P[2,I...])
    ret
end
@inline function getchannels{C<:Color3}(P, ::Type{C}, I)
    @inbounds ret = (P[1,I...], P[2,I...],P[3,I...])
    ret
end
@inline function getchannels{C<:Color4}(P, ::Type{C}, I)
    @inbounds ret = (P[1,I...], P[2,I...], P[3,I...], P[4,I...])
    ret
end

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

"""
    setchannels!(P, val, I)

For a color `val`, distribute its channels along `P[:, I...]` for
`P::AbstractArray{<:Number}`.
"""
setchannels!
if squeeze1
    @inline setchannels!(P, val::Color1, I) = (@inbounds P[I...] = comp1(val); val)
else
    @inline setchannels!(P, val::Color1, I) = (@inbounds P[1,I...] = comp1(val); val)
end
@inline function setchannels!(P, val::Color2, I)
    @inbounds P[1,I...] = comp1(val)
    @inbounds P[2,I...] = alpha(val)
    val
end
@inline function setchannels!(P, val::Color3, I)
    @inbounds P[1,I...] = comp1(val)
    @inbounds P[2,I...] = comp2(val)
    @inbounds P[3,I...] = comp3(val)
    val
end
@inline function setchannels!(P, val::Color4, I)
    @inbounds P[1,I...] = comp1(val)
    @inbounds P[2,I...] = comp2(val)
    @inbounds P[3,I...] = comp3(val)
    @inbounds P[4,I...] = alpha(val)
    val
end
