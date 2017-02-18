### reinterpret
#
## Color->T
Base.reinterpret{CV1<:Colorant,CV2<:Colorant}(::Type{CV1}, A::Array{CV2,1}) = _reinterpret_cvarray(CV1, A)
Base.reinterpret{CV1<:Colorant,CV2<:Colorant}(::Type{CV1}, A::Array{CV2})   = _reinterpret_cvarray(CV1, A)
Base.reinterpret{T<:Number,CV<:Colorant}(::Type{T}, A::Array{CV,1}) = _reinterpret_cvarray(T, A)
Base.reinterpret{T<:Number,CV<:Colorant}(::Type{T}, A::Array{CV})   = _reinterpret_cvarray(T, A)
Base.reinterpret{CV<:NonparametricColors}(::Type{UInt32}, A::Array{CV,1}) = reinterpret(UInt32, A, size(A))
Base.reinterpret{CV<:NonparametricColors}(::Type{UInt32}, A::Array{CV})   = reinterpret(UInt32, A, size(A))

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
#   form 2: reinterpret(RGB{N0f8}, img)
Base.reinterpret{T<:Number,CV<:Colorant}(::Type{CV}, A::Array{T,1}) = _reinterpret(CV, eltype(CV), A)
Base.reinterpret{T<:Number,CV<:Colorant}(::Type{CV}, A::Array{T})   = _reinterpret(CV, eltype(CV), A)

function _reinterpret{T,CV<:Colorant}(::Type{CV}, ::Type{Any}, A::Array{T})
    # form 1 (turn into a form 2 call by filling in the element type of the array)
    _reinterpret_array_cv(CV{T}, A)
end
function _reinterpret{T<:Integer,CV<:Colorant}(::Type{CV}, ::Type{Any}, A::Array{T})
    # form 1, with an invalid type...
    throw_color_typeerror(CV, T, (:ColorView, :reinterpret))
end
function _reinterpret{CV<:Colorant}(::Type{CV}, ::Type{Any}, A::Array{Bool})
    # ...but Bools are OK
    _reinterpret_array_cv(CV{Bool}, A)
end
function _reinterpret{T,CV<:Colorant}(::Type{CV}, TT::Type, A::Array{T})
    # form 2
    _reinterpret_array_cv(CV, A)
end

function _reinterpret_array_cv{T,CV<:Colorant}(::Type{CV}, A::Array{T})
    reinterpret(CV, A, tail(size(A)))
end
function _reinterpret_array_cv{CV<:NonparametricColors}(::Type{CV}, A::Array{UInt32})
    reinterpret(CV, A, size(A))
end
if squeeze1
    function _reinterpret_array_cv{T,CV<:Color1}(::Type{CV}, A::Array{T})
        reinterpret(CV, A, size(A))
    end
end

function throw_color_typeerror{CV,T<:Unsigned}(::Type{CV}, ::Type{T}, funcs)
    funcstr = join(funcs, " or ")
    throw(ArgumentError("$(colorant_string(CV)){$T} is not an allowed type; for an array with element type $T,\n  before calling $funcstr consider calling normedview, or specify the Normed{$T,f} element type"))
end

function throw_color_typeerror{CV,T<:Integer}(::Type{CV}, ::Type{T}, funcs)
    funcstr = join(funcs, " or ")
    throw(ArgumentError("$(colorant_string(CV)){$T} is not an allowed type; before calling $funcstr, please specify the concrete\n   element type as a Fixed{$T,f} type"))
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
#    convert(RGB{N0f8}, a)
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
