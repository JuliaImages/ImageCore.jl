### reinterpret

@pure samesize(::Type{T}, ::Type{S}) where {T,S} = sizeof(T) == sizeof(S)

if VERSION >= v"1.6.0-DEV.1083"
    reinterpretc(::Type{T}, a::AbstractArray) where T = reinterpret(reshape, ccolor_number(T, eltype(a)), a)
    reinterpretc(::Type{T}, a::Base.ReinterpretArray{S,N,T,AA,true}) where {T,S,N,AA<:AbstractArray{T}} = parent(a)
else
    # Color->Color
    function reinterpretc(::Type{CV1}, a::Array{CV2,1}) where {CV1<:Colorant,CV2<:Colorant}
        CV = ccolor(CV1, CV2)
        l = (length(a)*sizeof(CV2))÷sizeof(CV1)
        l*sizeof(CV1) == length(a)*sizeof(CV2) || throw(ArgumentError("sizes are incommensurate"))
        reshape(reinterpret(CV, a), (l,))
    end
    function reinterpretc(::Type{CV1}, a::AbstractArray{CV2}) where {CV1<:Colorant,CV2<:Colorant}
        CV = ccolor(CV1, CV2)
        if samesize(CV, CV2)
            return reshape(reinterpret(CV, a), size(a))
        end
        throw(ArgumentError("result shape not specified"))
    end

    # Color->T
    function reinterpretc(::Type{T}, a::AbstractArray{CV}) where {T<:Number,CV<:Colorant}
        if samesize(T, CV)
            return reinterpret(T, a)
        end
        axs = axes(a)
        if sizeof(CV) == sizeof(T)*_len(CV)
            return reinterpret(T, reshape(a, Base.OneTo(1), axs...))
        end
        throw(ArgumentError("result shape not specified"))
    end
    reinterpretc(::Type{T}, a::AbstractArray{CV,0}) where {T<:Number,CV<:Colorant} =
        reinterpret(T, reshape(a, 1))

    _len(::Type{C}) where {C} = _len(C, eltype(C))
    _len(::Type{C}, ::Type{Any}) where {C} = error("indeterminate type")
    _len(::Type{C}, ::Type{T}) where {C,T} = sizeof(C) ÷ sizeof(T)

    ## T->Color
    # We have to distinguish two forms of call:
    #   form 1: reinterpretc(RGB{N0f8}, img)
    #   form 2: reinterpretc(RGB, img)
    function reinterpretc(CV::Type{<:Colorant}, a::AbstractArray{T}) where T<:Number # {CV<:Colorant,T<:Number}
        @noinline throwdm(C::Type, ind1) =
            throw(DimensionMismatch("indices $ind1 are not consistent with color type $C"))
        CVT = ccolor_number(CV, T)
        if samesize(CVT, T)
            return reinterpret(CVT, a)
        end
        axs = axes(a)
        if axs[1] == Base.OneTo(sizeof(CVT) ÷ sizeof(eltype(CVT)))
            return reshape(reinterpret(CVT, a), tail(axs))
        end
        throwdm(CV, axs[1])
    end
end

# ccolor_number converts form 2 calls to form 1 calls
ccolor_number(::Type{T}, ::Any) where T<:Number = T
ccolor_number(::Type{CV}, ::Type{T}) where {CV<:Colorant,T} =
    ccolor_number(CV, eltype(CV), T)
ccolor_number(::Type{CV}, ::Type{CVT}, ::Type{T}) where {CV,CVT<:Number,T} = CV  # form 1
ccolor_number(::Type{CV}, ::Type{Any}, ::Type{T}) where {CV<:Colorant,T} = CV{T} # form 2

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
        fname = $(Expr(:quote, fn))
        Tname = shortname($T)
@doc """
    $fname.(img)

converts the raw storage type of `img` to `$Tname`, without changing the color space.
""" $fn

    end
end

"""
    float(x::Colorant)
    float(T::Type{<:Colorant})

convert the storage type of pixel `x` to a floating point data type while
preserving the `Colorant` information.

If the input is Type `T`, then it is equivalent to [`floattype`](@ref).
"""
float(x::Colorant) = floattype(typeof(x))(x)
float(::Type{T}) where T <: Colorant = floattype(T)
