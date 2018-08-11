using ImageCore, Colors, ColorVectorSpace
using Test, Statistics

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

# Rather than using BenchmarkTools (and thus run one test repeatedly,
# accumulating timings), we run the same test interleaving the two
# array types. This is designed to reduce the risk of spurious
# failure, particularly on shared machines like Travis where they may
# get "distracted" by other tasks
function test_getindex(f, ar, cv, n)
    t_ar = Array{Float64}(undef, n)
    t_cv = Array{Float64}(undef, n)
    f_ar = Ref(f(ar))
    f_cv = Ref(f(cv))
    for i = 1:n
        t_ar[i] = (tstart = time(); f_ar[] = f(ar); time()-tstart)
        t_cv[i] = (tstart = time(); f_cv[] = f(cv); time()-tstart)
    end
    median(t_ar), median(t_cv), f_ar
end
function test_setindex(f, ar, cv, n)
    t_ar = Array{Float64}(undef, n)
    t_cv = Array{Float64}(undef, n)
    for i = 1:n
        t_ar[i] = @elapsed f(ar, zero(eltype(ar)))
        t_cv[i] = @elapsed f(cv, zero(eltype(cv)))
    end
    median(t_ar), median(t_cv)
end

ssz = (1000,1000)
c = rand(RGB{Float64}, ssz...)
a = copy(reinterpretc(Float64, c))
vchan = channelview(c)
vcol = colorview(RGB, a)
cc_getindex_funcs = (mysum_elt_boundscheck,
                     mysum_index_boundscheck,
                     mysum_elt_inbounds,
                     mysum_index_inbounds_simd)
cc_setindex_funcs = (myfill1!,
                     myfill2!)
chanvtol = Dict(mysum_index_inbounds_simd => 20,   # @simd doesn't work for ChannelView :(
                mysum_elt_boundscheck => 20,
                myfill1! => 20,                    # crappy setindex! performance
                myfill2! => 20)
chanvdefault = 10
colvtol = Dict(mysum_elt_boundscheck=>5,
               mysum_index_boundscheck=>5)
colvdefault = 3

@info "Benchmark tests are warnings for now"
# @testset "benchmarks" begin
for (suite, testf) in ((cc_getindex_funcs, test_getindex),
                       (cc_setindex_funcs, test_setindex))
    for f in suite
        # Channelview
        t_ar, t_cv = testf(f, a, vchan, 10^2)
        tol = haskey(chanvtol, f) ? chanvtol[f] : chanvdefault
        if t_cv >= tol*t_ar
            @warn "ChannelView: failed on $f, time ratio $(t_cv/t_ar), tol $tol"
        end
        # @test t_cv < tol*t_ar
        # ColorView
        t_ar, t_cv = testf(f, c, vcol, 10^2)
        tol = haskey(colvtol, f) ? colvtol[f] : colvdefault
        if t_cv >= tol*t_ar
            @warn "ColorView: failed on $f, time ratio $(t_cv/t_ar), tol $tol"
        end
        # @test t_cv < tol*t_ar
    end
end
# end
