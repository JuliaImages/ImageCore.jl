var documenterSearchIndex = {"docs":
[{"location":"traits/#Traits-1","page":"Traits","title":"Traits","text":"","category":"section"},{"location":"traits/#","page":"Traits","title":"Traits","text":"ImageCore supports several \"traits\" that are sometimes useful in viewing or analyzing images. Many of these traits become much more powerful if you are using add-on packages like ImagesAxes, which allows you to give \"physical meaning\" to the different axes of your image.  Readers are encouraged to view the documentation for ImageAxes to gain a better appreciation of how to exploit these traits.  When using plain arrays to represent images, most of the traits default to \"trivial\" outcomes.","category":"page"},{"location":"traits/#","page":"Traits","title":"Traits","text":"Let's illustrate with a couple of examples:","category":"page"},{"location":"traits/#","page":"Traits","title":"Traits","text":"julia> using Colors, ImageCore\n\njulia> img = rand(RGB{N0f8}, 680, 480);\n\njulia> pixelspacing(img)\n(1,1)","category":"page"},{"location":"traits/#","page":"Traits","title":"Traits","text":"pixelspacing returns the spacing between adjacent pixels along each axis. Using ImagesAxes, you can even use physical units to encode this information, which might be important for microscopy or biomedical imaging.","category":"page"},{"location":"traits/#","page":"Traits","title":"Traits","text":"DocTestSetup = quote\n    using Colors, ImageCore\n    img = rand(RGB{N0f8}, 680, 480);\nend","category":"page"},{"location":"traits/#","page":"Traits","title":"Traits","text":"Another simple trait is coords_spatial:","category":"page"},{"location":"traits/#","page":"Traits","title":"Traits","text":"julia> coords_spatial(img)\n(1,2)","category":"page"},{"location":"traits/#","page":"Traits","title":"Traits","text":"This trait indicates that both dimensions 1 and 2 are \"spatial dimensions,\" meaning they correspond to physical space. This trait again becomes more interesting with ImagesAxes, where you can denote that some axes correspond to time (e.g., for a movie).","category":"page"},{"location":"traits/#","page":"Traits","title":"Traits","text":"A full list of traits is presented in the reference section.","category":"page"},{"location":"map/#Lazy-transformation-of-values-1","page":"Lazy transformation of values","title":"Lazy transformation of values","text":"","category":"section"},{"location":"map/#","page":"Lazy transformation of values","title":"Lazy transformation of values","text":"In image display and input/output, it is sometimes necessary to transform the value (or the type) of individual pixels.  For example, if you want to view an image with an unconventional range (e.g., -1000 to 1000, for which the normal range 0=black to 1=white will not be very useful), then those values might need to be transformed before display. Likewise, if try to save an image to disk that contains some out-of-range or NaN values, you are likely to experience an error unless the values are put in a range that makes sense for the specific file format.","category":"page"},{"location":"map/#","page":"Lazy transformation of values","title":"Lazy transformation of values","text":"There are several approaches to handling this problem. One is to compute a new image with scaled values, and for many users this may be the simplest option.  However, particularly with large images (or movies) this can present a performance problem.  In such cases, it's better to separate the concept of the \"map\" (transformation) function from the image (array) itself. (Here it's worth mentioning the MappedArrays package, which allows you to express lazy transformations on values for an entire array.)","category":"page"},{"location":"map/#","page":"Lazy transformation of values","title":"Lazy transformation of values","text":"ImageCore contains several such transformation functions that are frequently useful when working with images. Some of these functions operate directly on values:","category":"page"},{"location":"map/#","page":"Lazy transformation of values","title":"Lazy transformation of values","text":"clamp01\nclamp01nan","category":"page"},{"location":"map/#","page":"Lazy transformation of values","title":"Lazy transformation of values","text":"These two functions force the returned value to lie between 0 and 1, or each color channel to lie between 0 and 1 for color images. (clamp01nan forces NaN to 0, whereas clamp01 does not handle NaN.)","category":"page"},{"location":"map/#","page":"Lazy transformation of values","title":"Lazy transformation of values","text":"A simple application of these functions is in saving images, where you may have some out-of-range values but don't care if they get truncated:","category":"page"},{"location":"map/#","page":"Lazy transformation of values","title":"Lazy transformation of values","text":"img01 = clamp01nan.(img)","category":"page"},{"location":"map/#","page":"Lazy transformation of values","title":"Lazy transformation of values","text":"img01 is safe to save to an image file, whereas trying to save img might possibly result in an error (depending on the contents of img).","category":"page"},{"location":"map/#","page":"Lazy transformation of values","title":"Lazy transformation of values","text":"Other functions require parameters:","category":"page"},{"location":"map/#","page":"Lazy transformation of values","title":"Lazy transformation of values","text":"scaleminmax\nscalesigned\ncolorsigned","category":"page"},{"location":"map/#","page":"Lazy transformation of values","title":"Lazy transformation of values","text":"These return a function rather than a value; that function can then be applied to pixels of the image.  For example:","category":"page"},{"location":"map/#","page":"Lazy transformation of values","title":"Lazy transformation of values","text":"julia> f = scaleminmax(-10, 10)\n(::#9) (generic function with 1 method)\n\njulia> f(10)\n1.0\n\njulia> f(-10)\n0.0\n\njulia> f(5)\n0.75","category":"page"},{"location":"map/#","page":"Lazy transformation of values","title":"Lazy transformation of values","text":"It's worth noting that you can combine these: for example, you can combine scalesigned and colorsigned to map real values to linear colormaps. For example, suppose we want to visualize some data, mapping negative values to green hues and positive values to magenta hues. Let's say the negative values are a bit more compressed, so we're going to map -5 to pure green and +20 to pure magenta. We can achieve this easily with the following:","category":"page"},{"location":"map/#","page":"Lazy transformation of values","title":"Lazy transformation of values","text":"julia> sc = scalesigned(-5, 0, 20)  # maps [-5, 0, 20] -> [-1, 0, 1]\n(::#15) (generic function with 1 method)\n\njulia> col = colorsigned()          # maps -1 -> green, +1->magenta\n(::#17) (generic function with 1 method)\n\njulia> f = x->col(sc(x))            # combine the two\n(::#1) (generic function with 1 method)\n\njulia> f(-5)\nRGB{N0f8}(0.0,1.0,0.0)\n\njulia> f(20)\nRGB{N0f8}(1.0,0.0,1.0)\n\njulia> f(0)\nRGB{N0f8}(1.0,1.0,1.0)\n\njulia> f(10)\nRGB{N0f8}(1.0,0.502,1.0)","category":"page"},{"location":"map/#","page":"Lazy transformation of values","title":"Lazy transformation of values","text":"Finally, takemap exists to automatically set the parameters of certain functions from the image itself.  For example,","category":"page"},{"location":"map/#","page":"Lazy transformation of values","title":"Lazy transformation of values","text":"takemap(scaleminmax, A)","category":"page"},{"location":"map/#","page":"Lazy transformation of values","title":"Lazy transformation of values","text":"will return a function that scales the minimum value of A to 0 and the maximum value of A to 1.","category":"page"},{"location":"LICENSE/#","page":"-","title":"-","text":"The ImageCore.jl package is licensed under the MIT \"Expat\" License:","category":"page"},{"location":"LICENSE/#","page":"-","title":"-","text":"Copyright (c) 2015: Tim Holy.Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.","category":"page"},{"location":"reference/#Reference-1","page":"Reference","title":"Reference","text":"","category":"section"},{"location":"reference/#List-of-view-types-1","page":"Reference","title":"List of view types","text":"","category":"section"},{"location":"reference/#","page":"Reference","title":"Reference","text":"With that as an introduction, let's list all the view types supported by this package.  channelview and colorview are opposite transformations, as are rawview and normedview. channelview and colorview typically create objects of type ChannelView and ColorView, respectively, unless they are \"undoing\" a previous view of the opposite type.","category":"page"},{"location":"reference/#","page":"Reference","title":"Reference","text":"channelview\ncolorview\nrawview\nnormedview\nStackedView","category":"page"},{"location":"reference/#ImageCore.channelview","page":"Reference","title":"ImageCore.channelview","text":"channelview(A)\n\nreturns a view of A, splitting out (if necessary) the color channels of A into a new first dimension.\n\nOf relevance for types like RGB and BGR, the channels of the returned array will be in constructor-argument order, not memory order (see reinterpretc if you want to use memory order).\n\nExample\n\nimg = rand(RGB{N0f8}, 10, 10)\nA = channelview(img)   # a 3×10×10 array\n\nSee also: colorview\n\n\n\n\n\n","category":"function"},{"location":"reference/#ImageCore.colorview","page":"Reference","title":"ImageCore.colorview","text":"colorview(C, A)\n\nreturns a view of the numeric array A, interpreting successive elements of A as if they were channels of Colorant C.\n\nOf relevance for types like RGB and BGR, the elements of A are interpreted in constructor-argument order, not memory order (see reinterpretc if you want to use memory order).\n\nExample\n\nA = rand(3, 10, 10)\nimg = colorview(RGB, A)\n\nSee also: channelview\n\n\n\n\n\ncolorview(C, gray1, gray2, ...) -> imgC\n\nCombine numeric/grayscale images gray1, gray2, etc., into the separate color channels of an array imgC with element type C<:Colorant.\n\nAs a convenience, the constant zeroarray fills in an array of matched size with all zeros.\n\nExample\n\nimgC = colorview(RGB, r, zeroarray, b)\n\ncreates an image with r in the red chanel, b in the blue channel, and nothing in the green channel.\n\nSee also: StackedView.\n\n\n\n\n\ncolorview(C)\n\nCreate a function that is equivalent to (As...) -> colorview(C, Ax...).\n\nExamples\n\njulia> ones(Float32, 2, 2) |> colorview(Gray)\n2×2 reinterpret(reshape, Gray{Float32}, ::Matrix{Float32}) with eltype Gray{Float32}:\n Gray{Float32}(1.0)  Gray{Float32}(1.0)\n Gray{Float32}(1.0)  Gray{Float32}(1.0)\n\nThis can be slightly convenient when you want to convert a batch of channel data, for example:\n\njulia> Rs, Gs, Bs = ntuple( i -> [randn(2, 2) for _ in 1:4], 3)\n\njulia> map(colorview(RGB), Rs, Gs, Bs)\n\n\n\n\n\n","category":"function"},{"location":"reference/#ImageCore.rawview","page":"Reference","title":"ImageCore.rawview","text":"rawview(img::AbstractArray{FixedPoint})\n\nreturns a \"view\" of img where the values are interpreted in terms of their raw underlying storage. For example, if img is an Array{N0f8}, the view will act like an Array{UInt8}.\n\nSee also: normedview\n\n\n\n\n\n","category":"function"},{"location":"reference/#ImageCore.normedview","page":"Reference","title":"ImageCore.normedview","text":"normedview([T], img::AbstractArray{Unsigned})\n\nreturns a \"view\" of img where the values are interpreted in terms of Normed number types. For example, if img is an Array{UInt8}, the view will act like an Array{N0f8}.  Supply T if the element type of img is UInt16, to specify whether you want a N6f10, N4f12, N2f14, or N0f16 result.\n\nSee also: rawview\n\n\n\n\n\n","category":"function"},{"location":"reference/#ImageCore.StackedView","page":"Reference","title":"ImageCore.StackedView","text":"StackedView(B, C, ...) -> A\n\nPresent arrays B, C, etc, as if they are separate channels along the first dimension of A. In particular,\n\nB == A[1,:,:...]\nC == A[2,:,:...]\n\nand so on. Combined with colorview, this allows one to combine two or more grayscale images into a single color image.\n\nSee also: colorview.\n\n\n\n\n\n","category":"type"},{"location":"reference/#List-of-value-transformations-(map-functions)-1","page":"Reference","title":"List of value-transformations (map functions)","text":"","category":"section"},{"location":"reference/#","page":"Reference","title":"Reference","text":"clamp01\nclamp01!\nclamp01nan\nclamp01nan!\nscaleminmax\nscalesigned\ncolorsigned\ntakemap","category":"page"},{"location":"reference/#ImageCore.clamp01","page":"Reference","title":"ImageCore.clamp01","text":"clamp01(x) -> y\n\nProduce a value y that lies between 0 and 1, and equal to x when x is already in this range. Equivalent to clamp(x, 0, 1) for numeric values. For colors, this function is applied to each color channel separately.\n\nSee also: clamp01!, clamp01nan.\n\n\n\n\n\n","category":"function"},{"location":"reference/#ImageCore.clamp01!","page":"Reference","title":"ImageCore.clamp01!","text":"clamp01!(array::AbstractArray)\n\nRestrict values in array to [0, 1], in-place. See also clamp01.\n\n\n\n\n\n","category":"function"},{"location":"reference/#ImageCore.clamp01nan","page":"Reference","title":"ImageCore.clamp01nan","text":"clamp01nan(x) -> y\n\nSimilar to clamp01, except that any NaN values are changed to 0.\n\nSee also: clamp01nan!, clamp01.\n\n\n\n\n\n","category":"function"},{"location":"reference/#ImageCore.clamp01nan!","page":"Reference","title":"ImageCore.clamp01nan!","text":"clamp01nan!(array::AbstractArray)\n\nSimilar to clamp01!, except that any NaN values are changed to 0.\n\nSee also: clamp01!, clamp01nan\n\n\n\n\n\n","category":"function"},{"location":"reference/#ImageCore.scaleminmax","page":"Reference","title":"ImageCore.scaleminmax","text":"scaleminmax(min, max) -> f\nscaleminmax(T, min, max) -> f\n\nReturn a function f which maps values less than or equal to min to 0, values greater than or equal to max to 1, and uses a linear scale in between. min and max should be real values.\n\nOptionally specify the return type T. If T is a colorant (e.g., RGB), then scaling is applied to each color channel.\n\nExamples\n\nExample 1\n\njulia> f = scaleminmax(-10, 10)\n(::#9) (generic function with 1 method)\n\njulia> f(10)\n1.0\n\njulia> f(-10)\n0.0\n\njulia> f(5)\n0.75\n\nExample 2\n\njulia> c = RGB(255.0,128.0,0.0)\nRGB{Float64}(255.0,128.0,0.0)\n\njulia> f = scaleminmax(RGB, 0, 255)\n(::#13) (generic function with 1 method)\n\njulia> f(c)\nRGB{Float64}(1.0,0.5019607843137255,0.0)\n\nSee also: takemap.\n\n\n\n\n\n","category":"function"},{"location":"reference/#ImageCore.scalesigned","page":"Reference","title":"ImageCore.scalesigned","text":"scalesigned(maxabs) -> f\n\nReturn a function f which scales values in the range [-maxabs, maxabs] (clamping values that lie outside this range) to the range [-1, 1].\n\nSee also: colorsigned.\n\n\n\n\n\nscalesigned(min, center, max) -> f\n\nReturn a function f which scales values in the range [min, center] to [-1,0] and [center,max] to [0,1]. Values smaller than min/max get clamped to min/max, respectively.\n\nSee also: colorsigned.\n\n\n\n\n\n","category":"function"},{"location":"reference/#ImageCore.colorsigned","page":"Reference","title":"ImageCore.colorsigned","text":"colorsigned()\ncolorsigned(colorneg, colorpos) -> f\ncolorsigned(colorneg, colorcenter, colorpos) -> f\n\nDefine a function that maps negative values (in the range [-1,0]) to the linear colormap between colorneg and colorcenter, and positive values (in the range [0,1]) to the linear colormap between colorcenter and colorpos.\n\nThe default colors are:\n\ncolorcenter: white\ncolorneg: green1\ncolorpos: magenta\n\nSee also: scalesigned.\n\n\n\n\n\n","category":"function"},{"location":"reference/#ImageCore.takemap","page":"Reference","title":"ImageCore.takemap","text":"takemap(f, A) -> fnew\ntakemap(f, T, A) -> fnew\n\nGiven a value-mapping function f and an array A, return a \"concrete\" mapping function fnew. When applied to elements of A, fnew should return valid values for storage or display, for example in the range from 0 to 1 (for grayscale) or valid colorants. fnew may be adapted to the actual values present in A, and may not produce valid values for any inputs not in A.\n\nOptionally one can specify the output type T that fnew should produce.\n\nExample:\n\njulia> A = [0, 1, 1000];\n\njulia> f = takemap(scaleminmax, A)\n(::#7) (generic function with 1 method)\n\njulia> f.(A)\n3-element Array{Float64,1}:\n 0.0\n 0.001\n 1.0\n\n\n\n\n\n","category":"function"},{"location":"reference/#List-of-storage-type-transformations-1","page":"Reference","title":"List of storage-type transformations","text":"","category":"section"},{"location":"reference/#","page":"Reference","title":"Reference","text":"float32\nfloat64\nn0f8\nn6f10\nn4f12\nn2f14\nn0f16","category":"page"},{"location":"reference/#ImageCore.float32","page":"Reference","title":"ImageCore.float32","text":"float32.(img)\n\nconverts the raw storage type of img to Float32, without changing the color space.\n\n\n\n\n\n","category":"function"},{"location":"reference/#ImageCore.float64","page":"Reference","title":"ImageCore.float64","text":"float64.(img)\n\nconverts the raw storage type of img to Float64, without changing the color space.\n\n\n\n\n\n","category":"function"},{"location":"reference/#ImageCore.n0f8","page":"Reference","title":"ImageCore.n0f8","text":"n0f8.(img)\n\nconverts the raw storage type of img to N0f8, without changing the color space.\n\n\n\n\n\n","category":"function"},{"location":"reference/#ImageCore.n6f10","page":"Reference","title":"ImageCore.n6f10","text":"n6f10.(img)\n\nconverts the raw storage type of img to N6f10, without changing the color space.\n\n\n\n\n\n","category":"function"},{"location":"reference/#ImageCore.n4f12","page":"Reference","title":"ImageCore.n4f12","text":"n4f12.(img)\n\nconverts the raw storage type of img to N4f12, without changing the color space.\n\n\n\n\n\n","category":"function"},{"location":"reference/#ImageCore.n2f14","page":"Reference","title":"ImageCore.n2f14","text":"n2f14.(img)\n\nconverts the raw storage type of img to N2f14, without changing the color space.\n\n\n\n\n\n","category":"function"},{"location":"reference/#ImageCore.n0f16","page":"Reference","title":"ImageCore.n0f16","text":"n0f16.(img)\n\nconverts the raw storage type of img to N0f16, without changing the color space.\n\n\n\n\n\n","category":"function"},{"location":"reference/#List-of-traits-1","page":"Reference","title":"List of traits","text":"","category":"section"},{"location":"reference/#","page":"Reference","title":"Reference","text":"pixelspacing\nspacedirections\nsdims\ncoords_spatial\nsize_spatial\nindices_spatial\nnimages\nassert_timedim_last","category":"page"},{"location":"reference/#ImageCore.pixelspacing","page":"Reference","title":"ImageCore.pixelspacing","text":"pixelspacing(img) -> (sx, sy, ...)\n\nReturn a tuple representing the separation between adjacent pixels along each axis of the image.  Defaults to (1,1,...).  Use ImagesAxes for images with anisotropic spacing or to encode the spacing using physical units.\n\n\n\n\n\n","category":"function"},{"location":"reference/#ImageCore.spacedirections","page":"Reference","title":"ImageCore.spacedirections","text":"spacedirections(img) -> (axis1, axis2, ...)\n\nReturn a tuple-of-tuples, each axis[i] representing the displacement vector between adjacent pixels along spatial axis i of the image array, relative to some external coordinate system (\"physical coordinates\").\n\nBy default this is computed from pixelspacing, but you can set this manually using ImagesMeta.\n\n\n\n\n\n","category":"function"},{"location":"reference/#ImageCore.sdims","page":"Reference","title":"ImageCore.sdims","text":"sdims(img)\n\nReturn the number of spatial dimensions in the image. Defaults to the same as ndims, but with ImagesAxes you can specify that some axes correspond to other quantities (e.g., time) and thus not included by sdims.\n\n\n\n\n\n","category":"function"},{"location":"reference/#ImageCore.coords_spatial","page":"Reference","title":"ImageCore.coords_spatial","text":"coords_spatial(img)\n\nReturn a tuple listing the spatial dimensions of img.\n\nNote that a better strategy may be to use ImagesAxes and take slices along the time axis.\n\n\n\n\n\n","category":"function"},{"location":"reference/#ImageCore.size_spatial","page":"Reference","title":"ImageCore.size_spatial","text":"size_spatial(img)\n\nReturn a tuple listing the sizes of the spatial dimensions of the image. Defaults to the same as size, but using ImagesAxes you can mark some axes as being non-spatial.\n\n\n\n\n\n","category":"function"},{"location":"reference/#ImageCore.indices_spatial","page":"Reference","title":"ImageCore.indices_spatial","text":"indices_spatial(img)\n\nReturn a tuple with the indices of the spatial dimensions of the image. Defaults to the same as indices, but using ImagesAxes you can mark some axes as being non-spatial.\n\n\n\n\n\n","category":"function"},{"location":"reference/#ImageCore.nimages","page":"Reference","title":"ImageCore.nimages","text":"nimages(img)\n\nReturn the number of time-points in the image array. Defaults to\n\nUse ImagesAxes if you want to use an explicit time dimension.\n\n\n\n\n\n","category":"function"},{"location":"reference/#ImageCore.assert_timedim_last","page":"Reference","title":"ImageCore.assert_timedim_last","text":"assert_timedim_last(img)\n\nThrow an error if the image has a time dimension that is not the last dimension.\n\n\n\n\n\n","category":"function"},{"location":"#ImageCore.jl-1","page":"ImageCore.jl","title":"ImageCore.jl","text":"","category":"section"},{"location":"#","page":"ImageCore.jl","title":"ImageCore.jl","text":"ImageCore is the lowest-level component of the system of packages designed to support image processing and computer vision. Its main role is to simplify \"conversions\" between different image representations through different \"view\" types, and to provide some useful low-level functions (including \"traits\") that simplify image display, input/output, and the writing of algorithms.","category":"page"},{"location":"#","page":"ImageCore.jl","title":"ImageCore.jl","text":"If you're just getting started with images in Julia, it's recommended that you see the introductory documentation. In particular, this document assumes that you understand how Julia represents color through the used of fixed-point numbers.","category":"page"},{"location":"#","page":"ImageCore.jl","title":"ImageCore.jl","text":"Pages = [\"views.md\", \"map.md\", \"traits.md\", \"reference.md\"]","category":"page"},{"location":"views/#Views-1","page":"Views","title":"Views","text":"","category":"section"},{"location":"views/#View-types-defined-in-ImageCore-1","page":"Views","title":"View types defined in ImageCore","text":"","category":"section"},{"location":"views/#","page":"Views","title":"Views","text":"It is quite possible that the default representation of images will satisfy most or all of your needs. However, to enhance flexibility in working with image data, it is possible to leverage several different kinds of \"views.\" Generically, a view is an interpretation of array data, one that may change the apparent meaning of the array but which shares the same underlying storage: change an element of the view, and you also change the original array. Views can facilitate processing images of immense size without making copies, and writing algorithms in the most convenient format often without having to worry about the potential cost of converting from one format to another.","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"To illustrate views, it's helpful to begin with a very simple image:","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"julia> using Colors\n\njulia> img = [RGB(1,0,0) RGB(0,1,0);\n              RGB(0,0,1) RGB(0,0,0)]\n2×2 Array{RGB{N0f8},2} with eltype RGB{FixedPointNumbers.Normed{UInt8,8}}:\n RGB{N0f8}(1.0,0.0,0.0)  RGB{N0f8}(0.0,1.0,0.0)\n RGB{N0f8}(0.0,0.0,1.0)  RGB{N0f8}(0.0,0.0,0.0)","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"which displays as","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"(Image: rgbk)","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"DocTestSetup = quote\n    using Colors, ImageCore\n    img = [RGB(1,0,0) RGB(0,1,0);\n           RGB(0,0,1) RGB(0,0,0)]\n    v = channelview(img)\n    r = rawview(v)\nend","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"Most commonly, it's convenient that all dimensions of this array correspond to pixel indices: you don't need to worry about some dimensions of the array corresponding to \"color channels\" and other the spatial location, and you're guaranteed to get the entire pixel contents when you access that location.","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"That said, occasionally there are reasons to want to treat RGB as a 3-component vector.  That's motivation for introducing our first view:","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"julia> v = channelview(img)\n3×2×2 reinterpret(N0f8, ::Array{RGB{N0f8},3}):\n[:, :, 1] =\n 1.0  0.0\n 0.0  0.0\n 0.0  1.0\n\n[:, :, 2] =\n 0.0  0.0\n 1.0  0.0\n 0.0  0.0","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"channelview does exactly what the name suggests: provide a view of the array using separate channels for the color components.","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"To access the underlying representation of the N0f8 numbers, there's another view called rawview:","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"julia> r = rawview(v)\n3×2×2 rawview(reinterpret(N0f8, ::Array{RGB{N0f8},3})) with eltype UInt8:\n[:, :, 1] =\n 0xff  0x00\n 0x00  0x00\n 0x00  0xff\n\n[:, :, 2] =\n 0x00  0x00\n 0xff  0x00\n 0x00  0x00","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"Let's make a change in one of the entries:","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"julia> r[3,1,1] = 128\n128","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"If we display img, now we get this:","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"(Image: mgbk)","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"You can see that the first pixel has taken on a magenta hue, which is a mixture of red and blue.  Why does this happen? Let's look at the array values themselves:","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"DocTestSetup = quote\n    using Colors, ImageCore\n    img = [RGB(1,0,0) RGB(0,1,0);\n           RGB(0,0,1) RGB(0,0,0)]\n    v = channelview(img)\n    r = rawview(v)\n    r[3,1,1] = 128\nend","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"julia> r\n3×2×2 rawview(reinterpret(N0f8, ::Array{RGB{N0f8},3})) with eltype UInt8:\n[:, :, 1] =\n 0xff  0x00\n 0x00  0x00\n 0x80  0xff\n\n[:, :, 2] =\n 0x00  0x00\n 0xff  0x00\n 0x00  0x00\n\njulia> v\n3×2×2 reinterpret(N0f8, ::Array{RGB{N0f8},3}):\n[:, :, 1] =\n 1.0    0.0\n 0.0    0.0\n 0.502  1.0\n\n[:, :, 2] =\n 0.0  0.0\n 1.0  0.0\n 0.0  0.0\n\njulia> img\n2×2 Array{RGB{N0f8},2} with eltype RGB{Normed{UInt8,8}}:\n RGB{N0f8}(1.0,0.0,0.502)  RGB{N0f8}(0.0,1.0,0.0)\n RGB{N0f8}(0.0,0.0,1.0)    RGB{N0f8}(0.0,0.0,0.0)","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"The hexidecimal representation of 128 is 0x80; this is approximately halfway to 255, and as a consequence the N0f8 representation is very near 0.5.  You can see the same change is reflected in r, v, and img: there is only one underlying array, img, and the two views simply reference it.","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"Maybe you're used to having the color channel be the last dimension, rather than the first. We can achieve that using PermutedDimsArray:","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"julia> p = PermutedDimsArray(v, (2,3,1))\n2×2×3 PermutedDimsArray(reinterpret(N0f8, ::Array{RGB{N0f8},3}), (2, 3, 1)) with eltype Normed{UInt8,8}:\n[:, :, 1] =\n 1.0  0.0\n 0.0  0.0\n\n[:, :, 2] =\n 0.0  1.0\n 0.0  0.0\n\n[:, :, 3] =\n 0.502  0.0\n 1.0    0.0\n\njulia> p[1,2,:] .= 0.25\n3-element view(PermutedDimsArray(reinterpret(N0f8, ::Array{RGB{N0f8},3}), (2, 3, 1)), 1, 2, :) with eltype Normed{UInt8,8}:\n 0.251N0f8\n 0.251N0f8\n 0.251N0f8\n\njulia> p\n2×2×3 PermutedDimsArray(reinterpret(N0f8, ::Array{RGB{N0f8},3}), (2, 3, 1)) with eltype Normed{UInt8,8}:\n[:, :, 1] =\n 1.0  0.251\n 0.0  0.0\n\n[:, :, 2] =\n 0.0  0.251\n 0.0  0.0\n\n[:, :, 3] =\n 0.502  0.251\n 1.0    0.0\n\njulia> v\n3×2×2 reinterpret(N0f8, ::Array{RGB{N0f8},3}):\n[:, :, 1] =\n 1.0    0.0\n 0.0    0.0\n 0.502  1.0\n\n[:, :, 2] =\n 0.251  0.0\n 0.251  0.0\n 0.251  0.0\n\njulia> img\n2×2 Array{RGB{N0f8},2} with eltype RGB{Normed{UInt8,8}}:\n RGB{N0f8}(1.0,0.0,0.502)  RGB{N0f8}(0.251,0.251,0.251)\n RGB{N0f8}(0.0,0.0,1.0)    RGB{N0f8}(0.0,0.0,0.0)","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"Once again, p is a view, and as a consequence changing it leads to changes in all the coupled arrays and views.","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"Finally, you can combine multiple arrays into a \"virtual\" multichannel array. We'll use the lighthouse image:","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"using ImageCore, TestImages, Colors\nimg = testimage(\"lighthouse\")\n# Split out into separate channels\ncv = channelview(img)\n# Recombine the channels, filling in 0 for the middle (green) channel\nrb = colorview(RGB, cv[1,:,:], zeroarray, cv[3,:,:])","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"zeroarray is a constant which serves as a placeholder to create a (virtual) all-zeros array of size that matches the other arguments.","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"rb looks like this:","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"(Image: redblue)","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"In this case, we could have done the same thing somewhat more simply with cv[2,:,:] .= 0 and then visualize img. However, more generally you can apply this to independent arrays which may not allow you to set values to 0. In IJulia,","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"(Image: linspace1)","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"The error comes from the fact that img1d does not store values separately from the LinSpace objects used to create it, and LinSpace (which uses a compact representation of a range, storing just the endpoints and the number of values) does not allow you to set specific values. However, if you need to set individual values, you can make a copy:","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"(Image: linspace2)","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"The fact that no storage is allocated by colorview is very convenient in certain situations, particularly when processing large images.","category":"page"},{"location":"views/#","page":"Views","title":"Views","text":"colorview's ability to combine multiple grayscale images is based on another view, StackedView, which you can also use directly.","category":"page"}]
}