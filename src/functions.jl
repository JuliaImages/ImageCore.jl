import Base: fft, rfft, plan_fft, plan_rfft

# It's better not to define fft on Colorant arrays, because keeping
# track of the color dimension and the fft-dims is prone to omissions
# or problems due to later operations. So we put the bookkeeping on
# the user, but we try to give helpful suggestions.

function throw_ffterror(f, x, dims=1:ndims(x))
    error("$f not defined for eltype $(eltype(x)). Use channelview, and likely $(dims+channelview_dims_offset(x)) for the dims in the fft.")
end

for f in (:fft, :rfft)
    pf = Symbol("plan_", f)
    @eval begin
        $f{C<:Colorant}(x::AbstractArray{C}) = throw_ffterror($f, x)
        $f{C<:Colorant}(x::AbstractArray{C}, dims) = throw_ffterror($f, x, dims)
        $pf{C<:Colorant}(x::AbstractArray{C}; kws...) = throw_ffterror($pf, x)
    end
end
