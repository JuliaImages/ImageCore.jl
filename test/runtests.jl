module ImageCoreTests

using ImageCore
using Test, ReferenceTests
using Aqua, Documenter # for meta quality checks

@testset "Project meta quality checks" begin
    # Not checking compat section for test-only dependencies
    Aqua.test_all(ImageCore;
                  project_extras=true,
                  deps_compat=true,
                  stale_deps=true,
                  project_toml_formatting=true,
                  unbound_args=false, # FIXME: it fails when this is true
    )
    DocMeta.setdocmeta!(ImageCore, :DocTestSetup, :(using ImageCore); recursive=true)
end

# ReferenceTests uses ImageInTerminal as a default image rendering backend, we need to
# temporarily disable it when we do doctest.
# TODO: ReferenceTests doesn't yet support this switch. That's why we need ImageInTerminal dependency.
using ImageInTerminal
ImageInTerminal.disable_encoding()
doctest(ImageCore, manual = false)
ImageInTerminal.enable_encoding()

include("colorchannels.jl")
include("views.jl")
include("convert_reinterpret.jl")
include("traits.jl")
include("map.jl")
include("functions.jl")
include("show.jl")

# To ensure our deprecations work and don't break code
include("deprecations.jl")

# run these last
isCI = haskey(ENV, "CI") || get(ENV, "JULIA_PKGEVAL", false)
if Base.JLOptions().can_inline == 1 && !isCI
    @info "running benchmarks"
    include("benchmarks.jl")  # these fail if inlining is off
end

end
