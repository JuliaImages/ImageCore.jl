# Usage:
#     julia benchmark/run_benchmarks.jl

using BenchmarkTools
using Random
using ImageCore, ColorVectorSpace

# Showing a benchmark table of everything doesn't make much sense, hence we need to make
# some general and mild rules on how benchmark groups
#
# Operations are seperated into two basic groups:
#   * baseline: operations on plain array data
#   * imagecore: operations on data types introduced in Images type systems
#
# Trails are organized in the "what-how-property" way, for example, a trail on
# `colorview` is placed in Bsuite["colorview"]["getindex"]["RGB"]["(256, 256)"], one can
# reads it as:
#    benchmark the performance of `colorview` for method `getindex` on `RGB` image
#    of size `(256, 256)`
#
# The goals are:
#   * minimize the performance overhead for operations that has trivial baseline
#     implementation
#   * avoid unexpected performance regression

const SUITE = BenchmarkGroup(
    "baseline" => BenchmarkGroup(),
    "imagecore" => BenchmarkGroup()
)
const Bsuite = SUITE["baseline"]
const Csuite = SUITE["imagecore"]

include("views.jl")
