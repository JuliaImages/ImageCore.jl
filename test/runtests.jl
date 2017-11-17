module ImageCoreTests

using ImageCore, Test

# If we've run the tests previously, there might be ambiguities from other packages
if :StatsBase ∉ map(x->Symbol(string(x)), values(Base.loaded_modules))
    @test isempty(detect_ambiguities(ImageCore, Base, Core))
end

include("colorchannels.jl")
include("views.jl")
include("convert_reinterpret.jl")
include("traits.jl")
include("map.jl")
include("functions.jl")
include("show.jl")

# run these last
isCI = haskey(ENV, "CI") || get(ENV, "JULIA_PKGEVAL", false)
if Base.JLOptions().can_inline == 1 && !isCI
    @info "running benchmarks"
    include("benchmarks.jl")  # these fail if inlining is off
end

end
