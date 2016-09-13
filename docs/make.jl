using Documenter, ImageCore

makedocs(modules  = [ImageCore],
         format   = Documenter.Formats.HTML,
         sitename = "ImageCore",
         pages    = ["index.md", "views.md", "traits.md", "reference.md"])

deploydocs(repo   = "github.com/JuliaImages/ImageCore.jl.git",
           julia  = "0.5",
           target = "build",
           deps   = nothing,
           make   = nothing)
#           deps   = Deps.pip("mkdocs", "python-markdown-math"))
