using ImagesCore, Colors, Base.Test
using BenchmarkTools, JLD

# Different access patterns (getindex)
function mysum_elt_boundscheck(A)
    s = 0.0
    for a in A
        s += a
    end
    s
end
function mysum_index_boundscheck(A)
    s = 0.0
    for I in eachindex(A)
        s += A[I]
    end
    s
end
function mysum_elt_inbounds(A)
    s = 0.0
    @inbounds for a in A
        s += a
    end
    s
end
function mysum_index_inbounds_simd(A)
    s = 0.0
    @inbounds @simd for I in eachindex(A)
        s += A[I]
    end
    s
end
# setindex!
function myfill1!(A, val)
    f = convert(eltype(A), val)
    for I in eachindex(A)
        A[I] = f
    end
    A
end
function myfill2!(A, val)
    f = convert(eltype(A), val)
    @inbounds @simd for I in eachindex(A)
        A[I] = f
    end
    A
end

suite = BenchmarkGroup()
BenchmarkTools.DEFAULT_PARAMETERS.seconds = 0.1
ssz = (100,100)
a = rand(3,ssz...)
c = reinterpret(RGB{Float64}, a, ssz)
v = ChannelView(c)
suite["ChannelView"] = BenchmarkGroup()
channelviewfuncs = (mysum_elt_boundscheck,
                    mysum_index_boundscheck,
                    mysum_elt_inbounds,
                    mysum_index_inbounds_simd)
cvtol = Dict(mysum_index_inbounds_simd=>20)  # @simd doesn't work for ChannelView :(
cvdefault = 10
for f in channelviewfuncs
    for x in (a, v)
        suite["ChannelView"][string(f), string(typeof(x).name.name)] = @benchmarkable $(f)($x)
    end
end


# tune!(suite)
# save("params.jld", "suite", params(suite))
loadparams!(suite, load("params.jld", "suite"), :evals, :samples, :seconds)
results = run(suite)

cvr = results["ChannelView"]
for f in channelviewfuncs
    cv = cvr[string(f), "ChannelView"]
    a =  cvr[string(f), "Array"]
    tol = haskey(cvtol, f) ? cvtol[f] : cvdefault
    @test time(median(cv)) < tol*time(median(a))
end
