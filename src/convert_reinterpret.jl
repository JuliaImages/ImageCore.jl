### reinterpret
#
## Color->T
Base.reinterpret{CV1<:Colorant,CV2<:Colorant}(::Type{CV1}, A::Array{CV2,1}) = _reinterpret_cvarray(CV1, A)
Base.reinterpret{CV1<:Colorant,CV2<:Colorant}(::Type{CV1}, A::Array{CV2})   = _reinterpret_cvarray(CV1, A)
Base.reinterpret{T<:Number,CV<:Colorant}(::Type{T}, A::Array{CV,1}) = _reinterpret_cvarray(T, A)
Base.reinterpret{T<:Number,CV<:Colorant}(::Type{T}, A::Array{CV})   = _reinterpret_cvarray(T, A)

function _reinterpret_cvarray{CV1<:Colorant,CV2}(::Type{CV1}, A::Array{CV2})
    reinterpret(CV1, A, size(A))
end
@inline function _reinterpret_cvarray{T<:Number,CV<:Colorant}(::Type{T}, A::Array{CV})
    reinterpret(T, A, (_len(CV), size(A)...))
end
if squeeze1
    function _reinterpret_cvarray{T<:Number,CV<:Color1}(::Type{T}, A::Array{CV})
        reinterpret(T, A, size(A))
    end
end
_len{C}(::Type{C}) = _len(C, eltype(C))
_len{C}(::Type{C}, ::Type{Any}) = error("indeterminate type")
_len{C,T}(::Type{C}, ::Type{T}) = sizeof(C) ÷ sizeof(T)

## T->Color
# We have to distinguish two forms of call:
#   form 1: reinterpret(RGB, img)
#   form 2: reinterpret(RGB{UFixed8}, img)
Base.reinterpret{T<:Number,CV<:Colorant}(::Type{CV}, A::Array{T,1}) = _reinterpret(CV, eltype(CV), A)
Base.reinterpret{T<:Number,CV<:Colorant}(::Type{CV}, A::Array{T})   = _reinterpret(CV, eltype(CV), A)

function _reinterpret{T,CV<:Colorant}(::Type{CV}, ::Type{Any}, A::Array{T})
    # form 1 (turn into a form 2 call by filling in the element type of the array)
    _reinterpret_array_cv(CV{T}, A)
end
function _reinterpret{T,CV<:Colorant}(::Type{CV}, TT::Type, A::Array{T})
    # form 2
    _reinterpret_array_cv(CV, A)
end

function _reinterpret_array_cv{T,CV<:Colorant}(::Type{CV}, A::Array{T})
    reinterpret(CV, A, tail(size(A)))
end
if squeeze1
    function _reinterpret_array_cv{T,CV<:Color1}(::Type{CV}, A::Array{T})
        reinterpret(CV, A, size(A))
    end
end

# This version is used by the deserializer to convert UInt8 buffers
# back to their original type. Fixes Images#287.
# _reinterpret_array_cv{CV<:Colorant}(::Type{CV}, A::Vector{UInt8}) =
#     reinterpret(CV, A, (div(length(A), sizeof(CV)),))


### convert
#
# The main contribution here is "concretizing" the colorant type: allow
#    convert(RGB, a)
# rather than requiring
#    convert(RGB{U8}, a)
# Where possible the raw element type of the source is retained.
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

# float32, float64, etc. Used for conversions like
#     Array{RGB{U8}} -> Array{RGB{Float32}},
# since
#    convert(Array{RGB{Float32}}, A)
# is annoyingly verbose for such a common operation.
for (fn,T) in (#(:float16, Float16),   # Float16 currently has promotion problems
               (:float32, Float32), (:float64, Float64),
               (:ufixed8, UFixed8), (:ufixed10, UFixed10),
               (:ufixed12, UFixed12), (:ufixed14, UFixed14), (:ufixed16, UFixed16))
    # Since ufixed8 et al are defined in FixedPointNumbers, we need to extend them
    fnscoped = T <: FixedPoint ? Expr(:., :FixedPointNumbers, QuoteNode(fn)) : fn
    @eval begin
        function ($fnscoped){C<:Colorant}(A::AbstractArray{C})
            newC = $fn(C)
            convert_toeltype(newC, A)
        end
        ($fnscoped){S<:Number}(A::AbstractArray{S}) = convert_toeltype($T, A)
        ($fnscoped){C<:Colorant}(::Type{C}) = base_colorant_type(C){$T}
        ($fnscoped){S<:Number  }(::Type{S}) = $T
        fname = $(Expr(:quote, fn))
        Tname = $(Expr(:quote, T))
@doc """
    $fname(img)

converts the raw storage type of `img` to `$Tname`, without changing the color space.
""" $fn

    end
end
const u8 = ufixed8
const u16 = ufixed16

convert_toeltype{T}(::Type{T}, A) = _convert_toeltype(T, indices(A), A)
_convert_toeltype{T,N}(::Type{T}, ::NTuple{N,Base.OneTo}, A::AbstractArray{T}) = A
_convert_toeltype{T,N}(::Type{T}, ::NTuple{N,Base.OneTo}, A::AbstractArray) = convert(Array{T}, A)
_convert_toeltype{T,N}(::Type{T}, ::NTuple{N}, A::AbstractArray{T}) = A
_convert_toeltype{T,N}(::Type{T}, inds::NTuple{N}, A::AbstractArray) = copy!(similar(Array{T}, inds), A)
