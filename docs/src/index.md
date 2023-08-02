# ImageCore.jl

ImageCore is the lowest-level component of the system of packages
designed to support image processing and computer vision. Its main
role is to simplify "conversions" between different image
representations through different "view" types, and to provide some
useful low-level functions (including "traits") that simplify image
display, input/output, and the writing of algorithms.

Some of the key features and functionalities provided by ImageCore.jl include:

1.Image I/O: Loading and saving images in various formats like PNG, JPEG, BMP, TIFF, etc.
2.Image data representation: It provides the Image type to store image data along with functions for basic image manipulation.
3.Resizing and scaling: Functions for resizing and scaling images.
4.Image rotation and flipping: Functions to rotate and flip images.
5.Basic image processing operations: Some simple image processing operations like converting images to grayscale, computing histograms, etc.

It is important to note that ImageCore.jl focuses on fundamental image processing operations and may not have the full range of advanced image processing capabilities found in more specialized libraries. For more complex image processing tasks, you might need to explore other Julia packages such as ImageMagick.jl or ImageFiltering.jl, or other external libraries.

If you want to use ImageCore.jl, you can add it to your Julia environment using the package manager. Open a Julia REPL and use the following command:

using Pkg
Pkg.add("ImageCore")


If you're just getting started with images in Julia, it's recommended
that you see the
[introductory documentation](http://juliaimages.github.io/latest/). In
particular, this document assumes that you understand how Julia
represents color through the used of fixed-point numbers.

```@contents
Pages = ["views.md", "map.md", "traits.md", "reference.md"]
```
