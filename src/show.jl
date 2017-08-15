function ShowItLikeYouBuildIt.showarg(io::IO, cv::ChannelView)
    T, P = eltype(cv), parent(cv)
    print(io, "ChannelView(")
    showarg(io, P)
    print(io, ')')
end

Base.summary(A::ChannelView) = summary_build(A)

function ShowItLikeYouBuildIt.showarg(io::IO, cv::ColorView)
    C, P = eltype(cv), parent(cv)
    print(io, "ColorView{", ColorTypes.colorant_string(C), "}(")
    showarg(io, P)
    print(io, ')')
end

Base.summary(A::ColorView) = summary_build(A)

function ShowItLikeYouBuildIt.showarg(io::IO, A::Base.PermutedDimsArrays.PermutedDimsArray{T,N,perm}) where {T,N,perm}
    print(io, "permuteddimsview(")
    showarg(io, parent(A))
    print(io, ", ", perm, ')')
end

Base.summary(A::Base.PermutedDimsArrays.PermutedDimsArray) = summary_build(A)

# rawview
AAFixed{T<:FixedPoint,N} = AbstractArray{T,N}
function ShowItLikeYouBuildIt.showarg(io::IO, A::MappedArray{T,N,AA,typeof(reinterpret)}) where {T<:Integer,N,AA<:AAFixed}
    print(io, "rawview(")
    showarg(io, parent(A))
    print(io, ')')
end

Base.summary(A::MappedArray{T,N,AA,typeof(reinterpret)}) where {T<:Integer,N,AA} = summary_build(A)

# normedview
AAInteger{T<:Integer,N} = AbstractArray{T,N}
function ShowItLikeYouBuildIt.showarg(io::IO, A::MappedArray{T,N,AA,F,typeof(reinterpret)}) where {T<:FixedPoint,N,AA<:AAInteger,F}
    print(io, "normedview(")
    showcoloranttype(io, T)
    print(io, ", ")
    showarg(io, parent(A))
    print(io, ')')
end

Base.summary(A::MappedArray{T,N,AA,F,typeof(reinterpret)}) where {T<:FixedPoint,N,AA,F} = summary_build(A)

# SubArray of Colorant

_showindices(io, indices) = print(io, indices)
_showindices(io, ::Base.Slice) = print(io, ':')
function ShowItLikeYouBuildIt.showarg(io::IO, A::SubArray{T,N}) where {T<:Colorant,N}
    print(io, "view(")
    showarg(io, parent(A))
    print(io, ", ")
    for (i, indices) in enumerate(A.indexes)
        _showindices(io, indices)
        i < length(A.indexes) && print(io, ", ")
    end
    print(io, ')')
end

Base.summary(A::SubArray{T,N}) where {T<:Colorant,N} = summary_build(A)


## Specializations of other containers based on a color or fixed-point eltype
# These may be going too far, but let's see how it works out
function ShowItLikeYouBuildIt.showarg(io::IO, A::Array{T,N}) where {T<:Union{FixedPoint,Colorant},N}
    print(io, "::")
    _showarg_type(io, A)
end
function _showarg_type(io::IO, A::Array)
    print(io, "Array{")
    showcoloranttype(io, eltype(A))
    print(io, ',', ndims(A), '}')
end

function Base.summary(A::Array{T}) where T<:Union{FixedPoint,Colorant}
    io = IOBuffer()
    print(io, ShowItLikeYouBuildIt.dimstring(indices(A)), ' ')
    _showarg_type(io, A)
    String(io)
end

function ShowItLikeYouBuildIt.showarg(io::IO, A::OffsetArray{T,N,AA}) where {T<:Union{FixedPoint,Colorant},N,AA<:Array}
    print(io, "::")
    _showarg_type(io, A)
end
function _showarg_type(io::IO, A::OffsetArray{T,N,AA}) where {T,N,AA<:Array}
    print(io, "OffsetArray{")
    showcoloranttype(io, T)
    print(io, ',', ndims(A), '}')
end
function _showarg_type(io::IO, A::OffsetArray{T,N}) where {T,N}
    print(io, "OffsetArray{")
    showcoloranttype(io, T)
    print(io, ',', ndims(A), ',')
    _showarg_type(io, parent(A))
    print(io, '}')
end

function Base.summary(A::OffsetArray{T}) where T<:Union{FixedPoint,Colorant}
    io = IOBuffer()
    print(io, ShowItLikeYouBuildIt.dimstring(indices(A)), ' ')
    _showarg_type(io, A)
    String(io)
end

function _showarg_type(io::IO, A)
    print(io, typeof(A))
end

function showcoloranttype(io, ::Type{C}) where C<:Colorant
    print(io, ColorTypes.colorant_string(C), '{')
    showcoloranttype(io, eltype(C))
    print(io, '}')
end
showcoloranttype(io, ::Type{T}) where {T<:FixedPoint} = FixedPointNumbers.showtype(io, T)
showcoloranttype(io, ::Type{Union{}}) = show(io, Union{})
showcoloranttype(io, ::Type{T}) where {T} = show(io, T)
