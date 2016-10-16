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

# ufixedview
typealias AAInteger{T<:Integer,N} AbstractArray{T,N}
function ShowItLikeYouBuildIt.showarg{T<:FixedPoint,N,AA<:AAInteger,F}(io::IO, A::MappedArray{T,N,AA,F,typeof(reinterpret)})
    print(io, "ufixedview(")
    showfptype(io, T)
    print(io, ", ")
    showarg(io, parent(A))
    print(io, ')')
end

Base.summary{T<:FixedPoint,N,AA,F}(A::MappedArray{T,N,AA,F,typeof(reinterpret)}) = summary_build(A)

# These are a little scary
function ShowItLikeYouBuildIt.showarg{T<:FixedPoint,N}(io::IO, A::Array{T,N})
    print(io, "::Array{")
    showfptype(io, T)
    print(io, ',', N, '}')
end
# Base.summary{T<:FixedPoint,N}(A::Array{T,N}) = summary_build(A)

function ShowItLikeYouBuildIt.showarg{C<:Colorant,N}(io::IO, A::Array{C,N})
    print(io, "::Array{")
    showcoloranttype(io, C)
    print(io, ',', N, '}')
end
# Base.summary{C<:Colorant,N}(A::Array{C,N}) = summary_build(A)

function showcoloranttype{C<:Colorant}(io, ::Type{C})
    print(io, ColorTypes.colorant_string(C), '{')
    _showcoloranttype(io, eltype(C))
    print(io, '}')
end
_showcoloranttype{T<:FixedPoint}(io, ::Type{T}) = showfptype(io, T)
_showcoloranttype{T}(io, ::Type{T}) = show(io, T)

showfptype(io, ::Type{U8}) = print(io, "U8")
showfptype{T<:FixedPoint}(io, ::Type{T}) = print(io, T)
