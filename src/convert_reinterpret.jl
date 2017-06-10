### reinterpret

@pure samesize{T,S}(::Type{T}, ::Type{S}) = sizeof(T) == sizeof(S)

## Color->Color
function Base.reinterpret{CV1<:Colorant,CV2<:Colorant}(::Type{CV1}, a::Array{CV2,1})
    CV = ccolor(CV1, CV2)
    l = (length(a)*sizeof(CV2))÷sizeof(CV1)
    l*sizeof(CV1) == length(a)*sizeof(CV2) || throw(ArgumentError("sizes are incommensurate"))
    reinterpret(CV, a, (l,))
end
function Base.reinterpret{CV1<:Colorant,CV2<:Colorant}(::Type{CV1}, a::Array{CV2})
    CV = ccolor(CV1, CV2)
    if samesize(CV, CV2)
        return reinterpret(CV, a, size(a))
    end
    throw(ArgumentError("result shape not specified"))
end

## Color->T
function Base.reinterpret{T<:Number,CV<:Colorant}(::Type{T}, a::Array{CV,1})
    l = (length(a)*sizeof(CV))÷sizeof(T)
    l*sizeof(T) == length(a)*sizeof(CV) || throw(ArgumentError("sizes are incommensurate"))
    reinterpret(T, a, (l,))
end
function Base.reinterpret{T<:Number,CV<:Colorant}(::Type{T}, a::Array{CV})
    if samesize(T, CV)
        return reinterpret(T, a, size(a))
    end
    if sizeof(CV) == sizeof(T)*_len(CV)
        return reinterpret(T, a, (_len(CV), size(a)...))
    end
    throw(ArgumentError("result shape not specified"))
end

_len{C}(::Type{C}) = _len(C, eltype(C))
_len{C}(::Type{C}, ::Type{Any}) = error("indeterminate type")
_len{C,T}(::Type{C}, ::Type{T}) = sizeof(C) ÷ sizeof(T)

## T->Color
# We have to distinguish two forms of call:
#   form 1: reinterpret(RGB{N0f8}, img)
#   form 2: reinterpret(RGB, img)
function Base.reinterpret{CV<:Colorant,T<:Number}(::Type{CV}, a::Array{T,1})
    CVT = ccolor_number(CV, T)
    l = (length(a)*sizeof(T))÷sizeof(CVT)
    l*sizeof(CVT) == length(a)*sizeof(T) || throw(ArgumentError("sizes are incommensurate"))
    reinterpret(CVT, a, (l,))
end
function Base.reinterpret{CV<:Colorant,T<:Number}(::Type{CV}, a::Array{T})
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
ccolor_number{CV<:Colorant,T<:Number}(::Type{CV}, ::Type{T}) =
    ccolor_number(CV, eltype(CV), T)
ccolor_number{CV,CVT<:Number,T}(::Type{CV}, ::Type{CVT}, ::Type{T}) = CV # form 1
ccolor_number{CV<:Colorant,T}(::Type{CV}, ::Type{Any}, ::Type{T}) = CV{T} # form 2


### convert
#
# The main contribution here is "concretizing" the colorant type: allow
#    convert(RGB, a)
# rather than requiring
#    convert(RGB{N0f8}, a)
# Where possible the raw element type of the source is retained.
Base.convert{C<:Color1,n}(::Type{Array{C}},   img::Array{C,n}) = img
Base.convert{C<:Color1,n}(::Type{Array{C,n}}, img::Array{C,n}) = img
Base.convert{C<:Colorant,n}(::Type{Array{C}},   img::Array{C,n}) = img
Base.convert{C<:Colorant,n}(::Type{Array{C,n}}, img::Array{C,n}) = img

function Base.convert{Cdest<:Colorant,n,Csrc<:Colorant}(::Type{Array{Cdest}},
                                                        img::AbstractArray{Csrc,n})
    convert(Array{Cdest,n}, img)
end

function Base.convert{Cdest<:Colorant,n,Csrc<:Colorant}(::Type{Array{Cdest,n}},
                                                        img::AbstractArray{Csrc,n})
    copy!(Array{ccolor(Cdest, Csrc)}(size(img)), img)
end

function Base.convert{Cdest<:Color1,n}(::Type{Array{Cdest}},
                                       img::BitArray{n})
    convert(Array{Cdest,n}, img)
end

function Base.convert{Cdest<:Color1,n,T<:Real}(::Type{Array{Cdest}},
                                               img::AbstractArray{T,n})
    convert(Array{Cdest,n}, img)
end

function Base.convert{Cdest<:Color1,n}(::Type{Array{Cdest,n}},
                                       img::BitArray{n})
    copy!(Array{ccolor(Cdest, Gray{Bool})}(size(img)), img)
end

function Base.convert{Cdest<:Color1,n,T<:Real}(::Type{Array{Cdest,n}},
                                               img::AbstractArray{T,n})
    copy!(Array{ccolor(Cdest, Gray{T})}(size(img)), img)
end

# for docstrings in the operations below
shortname{T<:FixedPoint}(::Type{T}) = (io = IOBuffer(); FixedPointNumbers.showtype(io, T); String(take!(io)))
shortname{T}(::Type{T}) = string(T)

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
        ($fn){C<:Colorant}(::Type{C}) = base_colorant_type(C){$T}
        ($fn){S<:Number  }(::Type{S}) = $T
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
