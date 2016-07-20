module ImagesCoreTests

using Base.Test

include("colorchannels.jl")
include("rawview.jl")
include("convert_reinterpret.jl")

# run these last
@test isempty(detect_ambiguities(ImagesCore,Base,Core))
include("benchmarks.jl")

end
