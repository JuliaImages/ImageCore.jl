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

#############################
#   colorview/channelview   #
#############################

# image_sizes = ((128, 128), (1024, 1024))
# image_colors = (Gray{Bool}, Gray{N0f8}, Gray{Float32}, RGB{N0f8}, RGB{Float32})
image_sizes = ((128, 128), )
image_colors = (Gray{N0f8}, )

getindex_funcs = (("elt_boundscheck", mysum_elt_boundscheck),
                  ("index_boundscheck", mysum_index_boundscheck),
                  ("elt_inbounds", mysum_elt_inbounds),
                  ("index_inbounds_simd", mysum_index_inbounds_simd))
setindex_funcs = (("index_boundscheck", myfill1!),
                  ("index_inbounds_simd", myfill2!))


for s in (Bsuite, Csuite)
    s["colorview"] = BenchmarkGroup(["views", ])
    s["channelview"] = BenchmarkGroup(["views", ])
    s["channelview"]["getindex"] = BenchmarkGroup(["index", ])
    s["channelview"]["setindex"] = BenchmarkGroup(["index", ])
    s["colorview"]["setindex"] = BenchmarkGroup(["index", ])
    s["colorview"]["getindex"] = BenchmarkGroup(["index", ])
end


for (fname, f) in getindex_funcs
  for s in (Bsuite, Csuite)
    s["channelview"]["getindex"][fname] = BenchmarkGroup()
    s["colorview"]["getindex"][fname] = BenchmarkGroup()
  end

  for C in image_colors
    for s in (Bsuite, Csuite)
      s["channelview"]["getindex"][fname][C] = BenchmarkGroup([string(base_color_type(C)), ])
      s["colorview"]["getindex"][fname][C] = BenchmarkGroup([string(base_color_type(C)), ])
    end

    for sz in image_sizes
      Random.seed!(0)
      A = rand(C, sz)
      A_raw = copy(reinterpretc(eltype(C), A))
      A_color = colorview(base_color_type(C), A_raw)
      A_chan = channelview(A)

      # baseline
      Bsuite["channelview"]["getindex"][fname][C][sz] = @benchmarkable $(f)($A_raw)
      Bsuite["colorview"]["getindex"][fname][C][sz] = @benchmarkable $(f)($A)

      # imagecore
      Csuite["channelview"]["getindex"][fname][C][sz] = @benchmarkable $(f)($A_chan)
      Csuite["colorview"]["getindex"][fname][C][sz] = @benchmarkable $(f)($A_color)
    end
  end
end

for (fname, f) in setindex_funcs
  for s in (Bsuite, Csuite)
    s["channelview"]["setindex"][fname] = BenchmarkGroup()
    s["colorview"]["setindex"][fname] = BenchmarkGroup()
  end

  for C in image_colors
    for s in (Bsuite, Csuite)
      s["channelview"]["setindex"][fname][C] = BenchmarkGroup([string(base_color_type(C)), ])
      s["colorview"]["setindex"][fname][C] = BenchmarkGroup([string(base_color_type(C)), ])
    end

    for sz in image_sizes
      Random.seed!(0)
      A = rand(C, sz)
      A_raw = copy(reinterpretc(eltype(C), A))
      A_color = colorview(base_color_type(C), A_raw)
      A_chan = channelview(A)

      # baseline
      Bsuite["channelview"]["setindex"][fname][C][sz] = @benchmarkable $(f)($A_raw, $(zero(eltype(C))))
      Bsuite["colorview"]["setindex"][fname][C][sz] = @benchmarkable $(f)($A, $(zero(C)))

      # imagecore
      Csuite["channelview"]["setindex"][fname][C][sz] = @benchmarkable $(f)($A_chan, $(zero(eltype(C))))
      Csuite["colorview"]["setindex"][fname][C][sz] = @benchmarkable $(f)($A_color, $(zero(C)))
    end
  end
end
