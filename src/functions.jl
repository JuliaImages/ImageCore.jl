import FFTW: fft, rfft, plan_fft, plan_rfft

# It's better not to define fft on Colorant arrays, because keeping
# track of the color dimension and the fft-dims is prone to omissions
# or problems due to later operations. So we put the bookkeeping on
# the user, but we try to give helpful suggestions.

function throw_ffterror(f, x, dims=1:ndims(x))
    newdims = plus(dims, channelview_dims_offset(x))
    error("$f not defined for eltype $(eltype(x)). Use channelview, and likely $newdims for the dims in the fft.")
end

for f in (:fft, :rfft)
    pf = Symbol("plan_", f)
    @eval begin
        $f(x::AbstractArray{C}) where {C<:Colorant} = throw_ffterror($f, x)
        $f(x::AbstractArray{C}, dims) where {C<:Colorant} = throw_ffterror($f, x, dims)
        $pf(x::AbstractArray{C}; kws...) where {C<:Colorant} = throw_ffterror($pf, x)
    end
end
