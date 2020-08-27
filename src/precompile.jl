function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    eltypes = (N0f8, N0f16, Float32, Float64)        # eltypes of parametric colors
    pctypes = (Gray, RGB, AGray, GrayA, ARGB, RGBA)  # parametric colors
    cctypes = (Gray24, AGray32, RGB24, ARGB32)       # non-parametric colors
    dims  = (1, 2, 3, 4)

    for T in eltypes
        @assert precompile(clamp01, (T,))
        @assert precompile(clamp01nan, (T,))
        @assert precompile(scaleminmax, (T, T))
        @assert precompile(scalesigned, (T,))
        @assert precompile(scalesigned, (T,T,T))
        for C in pctypes
            @assert precompile(clamp01, (C{T},))
            @assert precompile(clamp01nan, (C{T},))
            @assert precompile(colorsigned, (C{T},C{T}))
        end
    end
    for C in cctypes
        @assert precompile(clamp01, (C,))
        @assert precompile(clamp01nan, (C,))
        @assert precompile(colorsigned, (C,C))
end
    for n in dims
        for T in eltypes
            @assert precompile(rawview, (Array{T,n},))
        end
        @assert precompile(normedview, (Array{UInt8,n},))
        @assert precompile(normedview, (Type{N0f8}, Array{UInt8,n}))
        @assert precompile(normedview, (Type{N0f16}, Array{UInt16,n}))
    end
    for T in eltypes
        for n in dims
            for C in pctypes
                @assert precompile(colorview, (Type{C}, Array{T,n}))
                @assert precompile(colorview, (Type{C{T}}, Array{T,n}))
                if T<:FixedPoint
                    R = FixedPointNumbers.rawtype(T)
                    RA = Base.ReinterpretArray{T,n,R,Array{R,n}}
                    precompile(colorview, (Type{C}, RA))
                    precompile(colorview, (Type{C{T}}, RA))
                    precompile(reinterpretc, (Type{C{T}}, RA))
                end
                @assert precompile(channelview, (Array{C{T},n},))
            end
            for C in cctypes
                @assert precompile(colorview, (Type{C}, Array{T,n}))
                if T<:FixedPoint
                    R = FixedPointNumbers.rawtype(T)
                    RA = Base.ReinterpretArray{T,n,R,Array{R,n}}
                    precompile(colorview, (Type{C}, RA))
                end
                @assert precompile(channelview, (Array{C,n},))
            end
        end
    end
end
