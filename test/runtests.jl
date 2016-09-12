module ImageCoreTests

include("colorchannels.jl")
include("views.jl")
include("convert_reinterpret.jl")
include("traits.jl")
include("deprecated.jl")

# run these last
@test isempty(detect_ambiguities(ImageCore,Base,Core))
if Base.JLOptions().can_inline == 1
    include("benchmarks.jl")  # these fail if inlining is off
end

end
