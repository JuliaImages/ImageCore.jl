# Convenient utilities for MATLAB image layout: the color channel is stored as the last dimension.
#
# These function do not intent to cover all use cases
# because numerical arrays do not contain colorspace information.


"""
    im_from_matlab([CT], X::AbstractArray) -> AbstractArray{CT}

Convert numerical array `X` to colorant array, using the MATLAB image layout convention.

The input image `X` is assumed to be either grayscale image or RGB image. For other
colorspaces, the input `X` must be converted to RGB colorspace first.

```julia
im_from_matlab(rand(4, 4)) # 4×4 Gray image
im_from_matlab(rand(4, 4, 3)) # 4×4 RGB image

im_from_matlab(GrayA, rand(4, 4, 2)) # 4×4 Gray-alpha image
im_from_matlab(HSV, rand(4, 4, 3)) # 4×4 HSV image
```

Integer values must be converted to float point numbers or fixed point numbers first. For
instance:

```julia
img = rand(1:255, 16, 16) # 16×16 Int array

im_from_matlab(img ./ 255) # convert to Float64 first
im_from_matlab(UInt8.(img)) # convert to UInt8 first
```

!!! tip "lazy conversion"
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
    if T<:Union{Normed, AbstractFloat}
        return _im_from_matlab(CT, X)
    else
        msg = "Unrecognized element type $T, manual conversion to float point number or fixed point number is needed."
        hint = _matlab_type_hint(X)
        msg = isempty(hint) ? msg : "$msg $hint"
        throw(ArgumentError(msg))
    end
end
im_from_matlab(::Type{CT}, X::AbstractArray{UInt8}) where CT = _im_from_matlab(CT, reinterpret(N0f8, X))
im_from_matlab(::Type{CT}, X::AbstractArray{UInt16}) where CT = _im_from_matlab(CT, reinterpret(N0f16, X))
function im_from_matlab(::Type{CT}, X::AbstractArray{Int16}) where CT
    # MALTAB compat
    _im2double(x) = (Float64(x)+Float64(32768))/Float64(65535)
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
_im_from_matlab(::Type{CT}, X::AbstractArray{CT}) where CT<:Colorant = X
function _im_from_matlab(::Type{CT}, X::AbstractArray{T}) where {CT<:Colorant, T<:Real}
    _CT = isconcretetype(CT) ? CT : base_colorant_type(CT){T}
    # FIXME(johnnychen94): not type inferrable here
    return StructArray{_CT}(X; dims=3)
end
_im_from_matlab(::Type{CT}, X::AbstractArray{T}) where {CT<:Gray, T<:Real} = of_eltype(CT, X)
