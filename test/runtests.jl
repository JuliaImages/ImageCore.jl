module ImageCoreTests

include("colorchannels.jl")
include("views.jl")
include("convert_reinterpret.jl")
include("traits.jl")
include("functions.jl")
include("deprecated.jl")

# run these last
@test isempty(detect_ambiguities(ImageCore,Base,Core))
isCI = haskey(ENV, "CI") || get(ENV, "JULIA_PKGEVAL", false)
if Base.JLOptions().can_inline == 1 && !isCI
    include("benchmarks.jl")  # these fail if inlining is off
end

end
