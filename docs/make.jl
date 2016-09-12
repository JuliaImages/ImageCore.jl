using Documenter, ImageCore

makedocs(modules  = [ImageCore],
         format   = Documenter.Formats.HTML,
         sitename = "ImageCore",
         pages    = ["index.md", "views.md", "traits.md", "reference.md"])

deploydocs(repo   = "github.com/JuliaImages/ImageCore.jl.git")
#           deps   = Deps.pip("mkdocs", "python-markdown-math"))
