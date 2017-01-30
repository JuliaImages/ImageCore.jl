using Documenter, ImageCore

makedocs(modules  = [ImageCore],
         format   = :html,
         sitename = "ImageCore",
         pages    = ["index.md", "views.md", "map.md", "traits.md", "reference.md"])

deploydocs(repo   = "github.com/JuliaImages/ImageCore.jl.git",
           julia  = "0.5",
           target = "build",
           deps   = nothing,
           make   = nothing)
