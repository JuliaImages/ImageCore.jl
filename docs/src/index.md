# ImageCore.jl

ImageCore is the lowest-level component of the system of packages
designed to support image processing and computer vision. Its main
role is to simplify "conversions" between different image
representations through different "view" types, and to provide some
useful low-level functions (including "traits") that simplify image
display, input/output, and the writing of algorithms.

If you're just getting started with images in Julia, it's recommended
that you see the
[introductory documentation](http://juliaimages.github.io/latest/). In
particular, this document assumes that you understand how Julia
represents color through the used of fixed-point numbers.

```@contents
Pages = ["views.md", "map.md", "traits.md", "reference.md"]
```
