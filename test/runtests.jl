module ImagesCoreTests

using Base.Test

include("colorchannels.jl")
include("rawview.jl")

# run these last
include("benchmarks.jl")

end
