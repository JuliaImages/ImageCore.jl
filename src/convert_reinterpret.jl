### reinterpret

@pure samesize(::Type{T}, ::Type{S}) where {T,S} = sizeof(T) == sizeof(S)

## Color->Color
function Base.reinterpret(::Type{CV1}, a::Array{CV2,1}) where {CV1<:Colorant,CV2<:Colorant}
    CV = ccolor(CV1, CV2)
    l = (length(a)*sizeof(CV2))÷sizeof(CV1)
    l*sizeof(CV1) == length(a)*sizeof(CV2) || throw(ArgumentError("sizes are incommensurate"))
    reinterpret(CV, a, (l,))
end
function Base.reinterpret(::Type{CV1}, a::Array{CV2}) where {CV1<:Colorant,CV2<:Colorant}
    CV = ccolor(CV1, CV2)
    if samesize(CV, CV2)
        return reinterpret(CV, a, size(a))
    end
    throw(ArgumentError("result shape not specified"))
end

## Color->T
function Base.reinterpret(::Type{T}, a::Array{CV,1}) where {T<:Number,CV<:Colorant}
    l = (length(a)*sizeof(CV))÷sizeof(T)
    l*sizeof(T) == length(a)*sizeof(CV) || throw(ArgumentError("sizes are incommensurate"))
    reinterpret(T, a, (l,))
end
function Base.reinterpret(::Type{T}, a::Array{CV}) where {T<:Number,CV<:Colorant}
    if samesize(T, CV)
        return reinterpret(T, a, size(a))
    end
    if sizeof(CV) == sizeof(T)*_len(CV)
        return reinterpret(T, a, (_len(CV), size(a)...))
    end
    throw(ArgumentError("result shape not specified"))
end

_len(::Type{C}) where {C} = _len(C, eltype(C))
_len(::Type{C}, ::Type{Any}) where {C} = error("indeterminate type")
_len(::Type{C}, ::Type{T}) where {C,T} = sizeof(C) ÷ sizeof(T)

## T->Color
# We have to distinguish two forms of call:
#   form 1: reinterpret(RGB{N0f8}, img)
#   form 2: reinterpret(RGB, img)
function Base.reinterpret(::Type{CV}, a::Array{T,1}) where {CV<:Colorant,T<:Number}
    CVT = ccolor_number(CV, T)
    l = (length(a)*sizeof(T))÷sizeof(CVT)
    l*sizeof(CVT) == length(a)*sizeof(T) || throw(ArgumentError("sizes are incommensurate"))
    reinterpret(CVT, a, (l,))
end
function Base.reinterpret(::Type{CV}, a::Array{T}) where {CV<:Colorant,T<:Number}
    CVT = ccolor_number(CV, T)
    if samesize(CVT, T)
        return reinterpret(CVT, a, size(a))
    end
    if size(a, 1)*sizeof(T) == sizeof(CVT)
        return reinterpret(CVT, a, tail(size(a)))
    end
    throw(ArgumentError("result shape not specified"))
end

# ccolor_number converts form 2 calls to form 1 calls
ccolor_number(::Type{CV}, ::Type{T}) where {CV<:Colorant,T<:Number} =
    ccolor_number(CV, eltype(CV), T)
ccolor_number(::Type{CV}, ::Type{CVT}, ::Type{T}) where {CV,CVT<:Number,T} = CV # form 1
ccolor_number(::Type{CV}, ::Type{Any}, ::Type{T}) where {CV<:Colorant,T} = CV{T} # form 2


### convert
#
# The main contribution here is "concretizing" the colorant type: allow
#    convert(RGB, a)
# rather than requiring
#    convert(RGB{N0f8}, a)
# Where possible the raw element type of the source is retained.
Base.convert(::Type{Array{C}},   img::Array{C,n}) where {C<:Color1,n} = img
Base.convert(::Type{Array{C,n}}, img::Array{C,n}) where {C<:Color1,n} = img
Base.convert(::Type{Array{C}},   img::Array{C,n}) where {C<:Colorant,n} = img
Base.convert(::Type{Array{C,n}}, img::Array{C,n}) where {C<:Colorant,n} = img

function Base.convert(::Type{Array{Cdest}},
                      img::AbstractArray{Csrc,n}) where {Cdest<:Colorant,n,Csrc<:Colorant}
    convert(Array{Cdest,n}, img)
end

function Base.convert(::Type{Array{Cdest,n}},
                      img::AbstractArray{Csrc,n}) where {Cdest<:Colorant,n,Csrc<:Colorant}
    copy!(Array{ccolor(Cdest, Csrc)}(size(img)), img)
end

function Base.convert(::Type{Array{Cdest}},
                      img::BitArray{n}) where {Cdest<:Color1,n}
    convert(Array{Cdest,n}, img)
end

function Base.convert(::Type{Array{Cdest}},
                      img::AbstractArray{T,n}) where {Cdest<:Color1,n,T<:Real}
    convert(Array{Cdest,n}, img)
end

function Base.convert(::Type{Array{Cdest,n}},
                      img::BitArray{n}) where {Cdest<:Color1,n}
    copy!(Array{ccolor(Cdest, Gray{Bool})}(size(img)), img)
end

function Base.convert(::Type{Array{Cdest,n}},
                      img::AbstractArray{T,n}) where {Cdest<:Color1,n,T<:Real}
    copy!(Array{ccolor(Cdest, Gray{T})}(size(img)), img)
end

# for docstrings in the operations below
shortname(::Type{T}) where {T<:FixedPoint} = (io = IOBuffer(); FixedPointNumbers.showtype(io, T); String(take!(io)))
shortname(::Type{T}) where {T} = string(T)

# float32, float64, etc. Used for conversions like
#     Array{RGB{N0f8}} -> Array{RGB{Float32}},
# since
#    convert(Array{RGB{Float32}}, A)
# is annoyingly verbose for such a common operation.
for (fn,T) in (#(:float16, Float16),   # Float16 currently has promotion problems
               (:float32, Float32), (:float64, Float64),
               (:n0f8, N0f8), (:n6f10, N6f10),
               (:n4f12, N4f12), (:n2f14, N2f14), (:n0f16, N0f16))
    @eval begin
        ($fn)(::Type{C}) where {C<:Colorant} = base_colorant_type(C){$T}
        ($fn)(::Type{S}) where {S<:Number  } = $T
        ($fn)(c::Colorant) = convert(($fn)(typeof(c)), c)
        ($fn)(n::Number)   = convert(($fn)(typeof(n)), n)
        @deprecate ($fn){C<:Colorant}(A::AbstractArray{C}) ($fn).(A)
        fname = $(Expr(:quote, fn))
        Tname = shortname($T)
@doc """
    $fname.(img)

converts the raw storage type of `img` to `$Tname`, without changing the color space.
""" $fn

    end
end
