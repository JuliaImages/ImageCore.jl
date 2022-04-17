# Convenient utilities for MATLAB image layout: the color channel is stored as the last dimension.
#
# These function do not intent to cover all use cases
# because numerical arrays do not contain colorspace information.


"""
    im_from_matlab([CT], X::AbstractArray) -> AbstractArray{CT}
    im_from_matlab([CT], index::AbstractArray, values::AbstractArray)

Convert numerical array image `X` to colorant array, using the MATLAB image layout
convention. The image can also be an indexed image by passing the `index`, `values` pair.

By default, the input image `X` is assumed to be either grayscale image or RGB image. For
other colorspaces, explicit colorspace `CT` must be specified. Note that `CT` is only used
to interpret the values without numerical changes, thus using it incorrectly would produce
unexpected results, e.g., `im_from_matlab(Lab, rgb_values)` would be terribly wrong.

```julia
im_from_matlab(rand(4, 4)) # 4×4 Gray image
im_from_matlab(rand(4, 4, 3)) # 4×4 RGB image

im_from_matlab(GrayA, rand(4, 4, 2)) # 4×4 Gray image with alpha channel
im_from_matlab(HSV, rand(4, 4, 3)) # 4×4 HSV image
```

Except for special types `UInt8` and `UInt16`, the value range is typically \$[0, 1]\$. Thus
integer values must be converted to float point numbers or fixed point numbers first. For
instance:

```julia
img = rand(1:255, 16, 16) # 16×16 Int array

im_from_matlab(img ./ 255) # convert to Float64
im_from_matlab(UInt8.(img)) # convert to UInt8
```

Indexd image in MATLAB convention consists of the `index`-`values` pair. `values` is a
two-dimensional N×3 numerical array, and `index` is a integer-valued array in range \$[1,
N]\$.

```julia
# a 4×4 random indexed image using five colors
index = rand(1:5, 4, 4)
values = [0.0 0.0 0.0  # black
          1.0 0.0 0.0  # red
          0.0 1.0 0.0  # green
          0.0 0.0 1.0  # blue
          1.0 1.0 1.0] # white

# 4×4 matrix with eltype RGB{Float64}
im_from_matlab(index, values)
```

!!! tip "eager conversion"
    To save memory allocation, the conversion is done in lazy mode. In some cases, this
    could introduce performance overhead due to the repeat computation. This can be easily
    solved by converting eagerly via, e.g., `collect(im_from_matlab(...))`.

See also: [`im_to_matlab`](@ref).
"""
function im_from_matlab end

# Step 1: convenient conventions
# - 1d numerical vector is Gray image
# - 2d numerical array is Gray image
# - 3d numerical array of size (m, n, 3) is RGB image
# For other cases, users must specify `CT` explicitly; otherwise it is not type-stable
im_from_matlab(X::AbstractVector) = vec(im_from_matlab(reshape(X, (length(X), 1))))
im_from_matlab(X::AbstractMatrix{T}) where {T<:Real} = im_from_matlab(Gray, X)
function im_from_matlab(X::AbstractArray{T,3}) where {T<:Real}
    if size(X, 3) != 3
        msg = "Unrecognized MATLAB image layout."
        hint = size(X, 3) == 1 ? "Do you mean `im_from_matlab(reshape(X, ($(size(X)[1:2]...))))`?" : ""
        msg = isempty(hint) ? msg : "$msg $hint"
        throw(ArgumentError(msg))
    end
    return im_from_matlab(RGB, X)
end
im_from_matlab(X::AbstractArray) = throw(ArgumentError("Unrecognized MATLAB image layout."))

# Step 2: storage type conversion
function im_from_matlab(::Type{CT}, X::AbstractArray{T}) where {CT,T}
    if T <: Union{Normed,AbstractFloat}
        return _im_from_matlab(CT, X)
    else
        msg = "Unrecognized element type $T, manual conversion to float point number or fixed point number is needed."
        hint = _matlab_type_hint(X)
        msg = isempty(hint) ? msg : "$msg $hint"
        throw(ArgumentError(msg))
    end
end
im_from_matlab(::Type{CT}, X::AbstractArray{UInt8}) where {CT} = _im_from_matlab(CT, reinterpret(N0f8, X))
im_from_matlab(::Type{CT}, X::AbstractArray{UInt16}) where {CT} = _im_from_matlab(CT, reinterpret(N0f16, X))
function im_from_matlab(::Type{CT}, X::AbstractArray{Int16}) where {CT}
    # MALTAB compat
    _im2double(x) = (Float64(x) + Float64(32768)) / Float64(65535)
    return _im_from_matlab(CT, mappedarray(_im2double, X))
end

function _matlab_type_hint(@nospecialize X)
    mn, mx = extrema(X)
    if mn >= typemin(UInt8) && mx <= typemax(UInt8)
        return "For instance: `UInt8.(X)` or `X./$(typemax(UInt8))`"
    elseif mn >= typemin(UInt16) && mx <= typemax(UInt16)
        return "For instance: `UInt16.(X)` or `X./$(typemax(UInt16))`"
    else
        return ""
    end
end

# Step 3: colorspace conversion
_im_from_matlab(::Type{CT}, X::AbstractArray{CT}) where {CT<:Colorant} = X
@static if VERSION >= v"1.3"
    # use StructArray to inform that this is a struct of array layout
    function _im_from_matlab(::Type{CT}, X::AbstractArray{T}) where {CT<:Colorant,T<:Real}
        _CT = isconcretetype(CT) ? CT : base_colorant_type(CT){T}
        # FIXME(johnnychen94): not type inferrable here
        return StructArray{_CT}(X; dims=ndims(X))
    end
else
    function _im_from_matlab(::Type{CT}, X::AbstractArray{T,3}) where {CT<:Colorant,T<:Real}
        _CT = isconcretetype(CT) ? CT : base_colorant_type(CT){T}
        # FIXME(johnnychen94): not type inferrable here
        return colorview(_CT, PermutedDimsArray(X, (3, 1, 2)))
    end
    function _im_from_matlab(::Type{CT}, X::AbstractArray{T}) where {CT<:Colorant,T<:Real}
        throw(ArgumentError("For $(ndims(X)) dimensional numerical array, manual conversion from MATLAB layout is required."))
    end
end
_im_from_matlab(::Type{CT}, X::AbstractArray{T}) where {CT<:Gray,T<:Real} = colorview(CT, X)
_im_from_matlab(::Type{CT}, X::AbstractArray{T,3}) where {CT<:Gray,T<:Real} = colorview(CT, X)

# index image support
im_from_matlab(index::AbstractArray, values::AbstractMatrix{T}) where T<:Real = im_from_matlab(RGB{T}, index, values)
@static if VERSION >= v"1.3"
    function im_from_matlab(::Type{CT}, index::AbstractArray, values::AbstractMatrix{T}) where {CT<:Colorant, T<:Real}
        return IndirectArray(index, im_from_matlab(CT, values))
    end
else
    function im_from_matlab(::Type{CT}, index::AbstractArray, values::AbstractMatrix{T}) where {CT<:Colorant, T<:Real}
        return IndirectArray(index, colorview(CT, PermutedDimsArray(values, (2, 1))))
    end
end


"""
    I = im_to_matlab([T], X::AbstractArray)
    (index, values) = im_to_matlab([T], X::IndirectArray)

Convert colorant array `X` to numerical array, using MATLAB's image layout convention. If
`X` is an indexed image `IndirectArray`, then the output is a tuple of `index`-`values`
pair.

```julia
img = rand(Gray{N0f8}, 4, 4)
im_to_matlab(img) # 4×4 array with element type N0f8
im_to_matlab(Float64, img) # 4×4 array with element type Float64

img = rand(RGB{N0f8}, 4, 4)
im_to_matlab(img) # 4×4×3 array with element type N0f8
im_to_matlab(Float64, img) # 4×4×3 array with element type Float64
```

For color image `X`, it will be converted to RGB colorspace first. The alpha channel, if
presented, will be removed.

```jldoctest; setup = :(using ImageCore, Random; Random.seed!(1234))
julia> img = Lab.(rand(RGB, 4, 4));

julia> im_to_matlab(img) ≈ im_to_matlab(RGB.(img))
true

julia> img = rand(AGray{N0f8}, 4, 4);

julia> im_to_matlab(img) ≈ im_to_matlab(gray.(img))
true
```

For indexed image represented as `IndirectArray` provided by
[IndirectArrays.jl](https://github.com/JuliaArrays/IndirectArrays.jl), a tuple of
`index`-`values` pair will be returned:

```julia
# 4×4 indexed image with 5 color
jl_index = rand(1:5, 4, 4)
jl_values = [
    RGB(0.0,0.0,0.0), # black
    RGB(1.0,0.0,0.0), # red
    RGB(0.0,1.0,0.0), # green
    RGB(0.0,0.0,1.0), # blue
    RGB(1.0,1.0,1.0)  # white
]
jl_img = IndirectArray(jl_index, jl_values)

# m_values is 5×3 matrix with eltype Float64
m_index, m_values = im_to_matlab(jl_img)
```

!!! tip "eager conversion"
    To save memory allocation, the conversion is done in lazy mode. In some cases, this
    could introduce performance overhead due to the repeat computation. This can be easily
    solved by converting eagerly via, e.g., `collect(im_to_matlab(...))`.

!!! info "value range"
    The output value is always in range \$[0, 1]\$. Thus the equality `data ≈
    im_to_matlab(im_from_matlab(data))` only holds when `data` is in also range \$[0, 1]\$.
    For example, if `eltype(data) == UInt8`, this equality will not hold.

See also: [`im_from_matlab`](@ref).
"""
function im_to_matlab end

im_to_matlab(X::AbstractArray{<:Number}) = no_offset_view(X)
im_to_matlab(img::AbstractArray{CT}) where {CT<:Colorant} = im_to_matlab(eltype(CT), img)

im_to_matlab(::Type{T}, img::AbstractArray{CT}) where {T,CT<:TransparentColor} =
    im_to_matlab(T, of_eltype(base_color_type(CT), img))
im_to_matlab(::Type{T}, img::AbstractArray{<:Color}) where {T} =
    im_to_matlab(T, of_eltype(RGB{T}, img))
im_to_matlab(::Type{T}, img::AbstractArray{CT}) where {T,CT<:Union{Gray,RGB,Number}} =
    _im_to_matlab_try_reinterpret(T, img)

# eltype conversion doesn't work in general, e.g., `UInt8(N0f8(0.3))` would fail. For special
# types that we know solution, directly reinterpret them via `rawview`.
function _im_to_matlab_try_reinterpret(::Type{T}, img::AbstractArray{CT}) where {T,CT<:Union{Gray,Real}}
    throw(ArgumentError("Can not convert to MATLAB format: invalid conversion from `$(CT)` to `$T`."))
end
function _im_to_matlab_try_reinterpret(::Type{T}, img::AbstractArray{CT}) where {T<:Union{AbstractFloat, Normed},CT<:Union{Gray,Real}}
    return no_offset_view(of_eltype(T, channelview(img)))
end
for (T, NT) in ((:UInt8, :N0f8), (:UInt16, :N0f16))
    @eval function _im_to_matlab_try_reinterpret(::Type{$T}, img::AbstractArray{CT}) where {CT<:Union{Gray,Real}}
        if eltype(CT) != $NT
            nt_str = string($NT)
            throw(ArgumentError("Can not convert to MATLAB format: invalid conversion from `$(CT)` to `$nt_str`."))
        end
        return no_offset_view(rawview(channelview(img)))
    end
end
# for RGB, unroll the color channel in the last dimension
_im_to_matlab_try_reinterpret(::Type{T}, img::AbstractArray{CT}) where {T,CT<:RGB} =
    throw(ArgumentError("Can not convert to MATLAB format: invalid conversion from `$(CT)` to `$T`."))
function _im_to_matlab_try_reinterpret(::Type{T}, img::AbstractArray{<:RGB,N}) where {T<:Union{AbstractFloat, Normed},N}
    v = no_offset_view(of_eltype(T, channelview(img)))
    perm = (ntuple(i -> i + 1, N)..., 1)
    return PermutedDimsArray(v, perm)
end
for (T, NT) in ((:UInt8, :N0f8), (:UInt16, :N0f16))
    @eval function _im_to_matlab_try_reinterpret(::Type{$T}, img::AbstractArray{CT,N}) where {CT<:RGB,N}
        if eltype(CT) != $NT
            nt_str = string($NT)
            throw(ArgumentError("Can not convert to MATLAB format: invalid conversion from `$(CT)` to `$nt_str`."))
        end
        v = no_offset_view(rawview(channelview(img)))
        perm = (ntuple(i -> i + 1, N)..., 1)
        return PermutedDimsArray(v, perm)
    end
end

# indexed image
function im_to_matlab(::Type{T}, img::IndirectArray{CT}) where {T<:Real,CT<:Colorant}
    return no_offset_view(img.index), im_to_matlab(T, img.values)
end


if VERSION >= v"1.6.0-DEV.1083"
    # this method allows `data === im_to_matlab(im_from_matlab(data))` for gray image
    im_to_matlab(::Type{T}, img::Base.ReinterpretArray{CT,N,T,<:AbstractArray{T,N},true}) where {CT,N,T} =
        no_offset_view(img.parent)
else
    im_to_matlab(::Type{T}, img::Base.ReinterpretArray{CT,N,T,<:AbstractArray{T,N}}) where {CT,N,T} =
        no_offset_view(img.parent)
end
