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

function ShowItLikeYouBuildIt.showarg{T,N,perm}(io::IO, A::Base.PermutedDimsArrays.PermutedDimsArray{T,N,perm})
    print(io, "permuteddimsview(")
    showarg(io, parent(A))
    print(io, ", ", perm, ')')
end

Base.summary(A::Base.PermutedDimsArrays.PermutedDimsArray) = summary_build(A)

# rawview
typealias AAFixed{T<:FixedPoint,N} AbstractArray{T,N}
function ShowItLikeYouBuildIt.showarg{T<:Integer,N,AA<:AAFixed}(io::IO, A::MappedArray{T,N,AA,typeof(reinterpret)})
    print(io, "rawview(")
    showarg(io, parent(A))
    print(io, ')')
end

Base.summary{T<:Integer,N,AA}(A::MappedArray{T,N,AA,typeof(reinterpret)}) = summary_build(A)

# normedview
typealias AAInteger{T<:Integer,N} AbstractArray{T,N}
function ShowItLikeYouBuildIt.showarg{T<:FixedPoint,N,AA<:AAInteger,F}(io::IO, A::MappedArray{T,N,AA,F,typeof(reinterpret)})
    print(io, "normedview(")
    showcoloranttype(io, T)
    print(io, ", ")
    showarg(io, parent(A))
    print(io, ')')
end

Base.summary{T<:FixedPoint,N,AA,F}(A::MappedArray{T,N,AA,F,typeof(reinterpret)}) = summary_build(A)

## Specializations of other containers based on a color or fixed-point eltype
# These may be going too far, but let's see how it works out
function ShowItLikeYouBuildIt.showarg{T<:Union{FixedPoint,Colorant},N}(io::IO, A::Array{T,N})
    print(io, "::")
    _showarg_type(io, A)
end
function _showarg_type(io::IO, A::Array)
    print(io, "Array{")
    showcoloranttype(io, eltype(A))
    print(io, ',', ndims(A), '}')
end

function Base.summary{T<:Union{FixedPoint,Colorant}}(A::Array{T})
    io = IOBuffer()
    print(io, ShowItLikeYouBuildIt.dimstring(indices(A)), ' ')
    _showarg_type(io, A)
    String(io)
end

function ShowItLikeYouBuildIt.showarg{T<:Union{FixedPoint,Colorant},N,AA<:Array}(io::IO, A::OffsetArray{T,N,AA})
    print(io, "::")
    _showarg_type(io, A)
end
function _showarg_type{T,N,AA<:Array}(io::IO, A::OffsetArray{T,N,AA})
    print(io, "OffsetArray{")
    showcoloranttype(io, T)
    print(io, ',', ndims(A), '}')
end

function Base.summary{T<:Union{FixedPoint,Colorant}}(A::OffsetArray{T})
    io = IOBuffer()
    print(io, ShowItLikeYouBuildIt.dimstring(indices(A)), ' ')
    _showarg_type(io, A)
    String(io)
end

function showcoloranttype{C<:Colorant}(io, ::Type{C})
    print(io, ColorTypes.colorant_string(C), '{')
    showcoloranttype(io, eltype(C))
    print(io, '}')
end
showcoloranttype{T<:FixedPoint}(io, ::Type{T}) = FixedPointNumbers.showtype(io, T)
showcoloranttype{T}(io, ::Type{T}) = show(io, T)
