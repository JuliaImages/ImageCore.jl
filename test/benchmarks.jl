using ImagesCore, Colors, ColorVectorSpace
using Base.Test, BenchmarkTools, JLD

# Different access patterns (getindex)
function mysum_elt_boundscheck(A)
    s = zero(eltype(A))
    for a in A
        s += a
    end
    s
end
function mysum_index_boundscheck(A)
    s = zero(eltype(A))
    for I in eachindex(A)
        s += A[I]
    end
    s
end
function mysum_elt_inbounds(A)
    s = zero(eltype(A))
    @inbounds for a in A
        s += a
    end
    s
end
function mysum_index_inbounds_simd(A)
    s = zero(eltype(A))
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
vchan = ChannelView(c)
vcol = ColorView{RGB}(a)
suite["ChannelView"] = BenchmarkGroup()
channelviewfuncs = (mysum_elt_boundscheck,
                    mysum_index_boundscheck,
                    mysum_elt_inbounds,
                    mysum_index_inbounds_simd)
chanvtol = Dict(mysum_index_inbounds_simd=>20)  # @simd doesn't work for ChannelView :(
chanvdefault = 10
colvtol = Dict(mysum_elt_boundscheck=>5, mysum_index_boundscheck=>5)
colvdefault = 3

for f in channelviewfuncs
    for x in (a, vchan)
        suite["ChannelView"][string(f), string(typeof(x).name.name)] = @benchmarkable $(f)($x)
    end
end

suite["ColorView"] = BenchmarkGroup()
for f in channelviewfuncs
    for x in (c, vcol)
        suite["ColorView"][string(f), string(typeof(x).name.name)] = @benchmarkable $(f)($x)
    end
end


# tune!(suite)
# save("params.jld", "suite", params(suite))
loadparams!(suite, load("params.jld", "suite"), :evals, :samples, :seconds)
results = run(suite)

chanvr = results["ChannelView"]
for f in channelviewfuncs
    cv = chanvr[string(f), "ChannelView"]
    a =  chanvr[string(f), "Array"]
    tol = haskey(chanvtol, f) ? chanvtol[f] : chanvdefault
    @test time(median(cv)) < tol*time(median(a))
end
colvr = results["ColorView"]
for f in channelviewfuncs
    cv = colvr[string(f), "ColorView"]
    a =  colvr[string(f), "Array"]
    tol = haskey(colvtol, f) ? colvtol[f] : colvdefault
    @test time(median(cv)) < tol*time(median(a))
end
