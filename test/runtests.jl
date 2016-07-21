module ImagesCoreTests

include("colorchannels.jl")
include("views.jl")
include("convert_reinterpret.jl")

# run these last
@test isempty(detect_ambiguities(ImagesCore,Base,Core))
include("benchmarks.jl")

end
