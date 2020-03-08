using BenchmarkTools
using Random
using Logging
using TerminalLoggers
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

results = nothing
with_logger(TerminalLogger()) do
    global results

    include("views.jl")


    tune!(SUITE; verbose=true)
    results = run(SUITE; verbose=true)
end


# TODO: export benchmark results
results

judgement = median(results)
