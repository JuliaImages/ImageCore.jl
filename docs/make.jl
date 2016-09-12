using Documenter, ImageCore

makedocs(modules = [ImageCore])

deploydocs(deps   = Deps.pip("mkdocs", "python-markdown-math"),
           repo   = "github.com/JuliaImages/ImageCore.jl.git")
