using Documenter, ImagesCore

makedocs(modules = [ImagesCore])

deploydocs(deps   = Deps.pip("mkdocs", "python-markdown-math"),
           repo   = "github.com/JuliaImages/ImagesCore.jl.git")
