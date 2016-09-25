var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "ImageCore.jl",
    "title": "ImageCore.jl",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#ImageCore.jl-1",
    "page": "ImageCore.jl",
    "title": "ImageCore.jl",
    "category": "section",
    "text": "ImageCore is the lowest-level component of the system of packages designed to support image processing and computer vision. Its main role is to simplify \"conversions\" between different image representations through different \"view\" types, and to provide some useful low-level \"traits\" that simplify the writing of algorithms.Pages = [\"views.md\", \"traits.md\", \"reference.md\"]"
},

{
    "location": "views.html#",
    "page": "Views",
    "title": "Views",
    "category": "page",
    "text": ""
},

{
    "location": "views.html#Views-1",
    "page": "Views",
    "title": "Views",
    "category": "section",
    "text": "ImageCore provides several different kinds of \"views.\" Generically, a view is an interpretation of array data, one that may change the apparent meaning of the array but which shares the same underlying storage: change an element of the view, and you also change the original array. Views allow one to process images of immense size without making copies, and write algorithms in the most convenient format often without having to worry about the potential cost of converting from one format to another.To illustrate views, it's helpful to begin with a very simple image:julia> using Colors\n\njulia> img = [RGB(1,0,0) RGB(0,1,0);\n              RGB(0,0,1) RGB(0,0,0)]\n2×2 Array{ColorTypes.RGB{FixedPointNumbers.UFixed{UInt8,8}},2}:\n RGB{U8}(1.0,0.0,0.0)  RGB{U8}(0.0,1.0,0.0)\n RGB{U8}(0.0,0.0,1.0)  RGB{U8}(0.0,0.0,0.0)DocTestSetup = quote\n    using Colors, ImageCore\n    img = [RGB(1,0,0) RGB(0,1,0);\n           RGB(0,0,1) RGB(0,0,0)]\n    v = channelview(img)\n    r = rawview(v)\nendRGB is described in the Colors package, and the image is just a plain 2×2 array containing red, green, blue, and black pixels.  In Julia's color package, \"1\" means \"saturated\" (e.g., \"full red\"), and \"0\" means \"black\".  In a moment you'll see that's true no matter how the information is represented internally.As with all of Julia's arrays, you can access individual elements:julia> img[1,2]\nRGB{U8}(0.0,1.0,0.0)One of the nice things about this representation of the image is that all of the indices in img[i,j,...] correspond to locations in the image: you don't need to worry about some dimensions of the array corresponding to \"color channels\" and other the spatial location, and you're guaranteed to get the entire pixel contents when you access that location.That said, occassionally there are reasons to want to treat RGB as a 3-component vector.  That's motivation for introducing our first view:julia> v = channelview(img)\n3×2×2 ImageCore.ChannelView{FixedPointNumbers.UFixed{UInt8,8},3,Array{ColorTypes.RGB{FixedPointNumbers.UFixed{UInt8,8}},2}}:\n[:, :, 1] =\n UFixed8(1.0)  UFixed8(0.0)\n UFixed8(0.0)  UFixed8(0.0)\n UFixed8(0.0)  UFixed8(1.0)\n\n[:, :, 2] =\n UFixed8(0.0)  UFixed8(0.0)\n UFixed8(1.0)  UFixed8(0.0)\n UFixed8(0.0)  UFixed8(0.0)v is a 3×2×2 array of numbers (UFixed8 is defined in FixedPointNumbers and can be abbreviated as U8), where the three elements of the first dimension correspond to the red, green, and blue color channels, respectively. channelview does exactly what the name suggests: provide a view of the array using separate channels for the color components.If you're not familiar with UFixed8, then you may find another view type, rawview, illuminating:julia> r = rawview(v)\n3×2×2 MappedArrays.MappedArray{UInt8,3,ImageCore.ChannelView{FixedPointNumbers.UFixed{UInt8,8},3,Array{ColorTypes.RGB{FixedPointNumbers.UFixed{UInt8,8}},2}},ImageCore.##11#13,ImageCore.##12#14{FixedPointNumbers.UFixed{UInt8,8}}}:\n[:, :, 1] =\n 0xff  0x00\n 0x00  0x00\n 0x00  0xff\n\n[:, :, 2] =\n 0x00  0x00\n 0xff  0x00\n 0x00  0x00This is an array of UInt8 numbers, with 0 printed as 0x00 and 255 printed as 0xff. Despite the apparent \"floating point\" representation of the image above, we see that it's actually represented using 8-bit unsigned integers.  The UFixed8 type presents such an integer as a fixed-point number ranging from 0 to 1.  As a consequence, there is no discrepancy in \"meaning\" between the encoding of images represented as floating point or 8-bit or 16-bit integers: 0 always means \"black\" and 1 always means \"white\" or \"saturated.\"Let's make a change in one of the entries:julia> r[3,1,1] = 128\n128\n\njulia> r\n3×2×2 MappedArrays.MappedArray{UInt8,3,ImageCore.ChannelView{FixedPointNumbers.UFixed{UInt8,8},3,Array{ColorTypes.RGB{FixedPointNumbers.UFixed{UInt8,8}},2}},ImageCore.##11#13,ImageCore.##12#14{FixedPointNumbers.UFixed{UInt8,8}}}:\n[:, :, 1] =\n 0xff  0x00\n 0x00  0x00\n 0x80  0xff\n\n[:, :, 2] =\n 0x00  0x00\n 0xff  0x00\n 0x00  0x00\n\njulia> v\n3×2×2 ImageCore.ChannelView{FixedPointNumbers.UFixed{UInt8,8},3,Array{ColorTypes.RGB{FixedPointNumbers.UFixed{UInt8,8}},2}}:\n[:, :, 1] =\n UFixed8(1.0)    UFixed8(0.0)\n UFixed8(0.0)    UFixed8(0.0)\n UFixed8(0.502)  UFixed8(1.0)\n\n[:, :, 2] =\n UFixed8(0.0)  UFixed8(0.0)\n UFixed8(1.0)  UFixed8(0.0)\n UFixed8(0.0)  UFixed8(0.0)\n\njulia> img\n2×2 Array{ColorTypes.RGB{FixedPointNumbers.UFixed{UInt8,8}},2}:\n RGB{U8}(1.0,0.0,0.502)  RGB{U8}(0.0,1.0,0.0)\n RGB{U8}(0.0,0.0,1.0)    RGB{U8}(0.0,0.0,0.0)The hexidecimal representation of 128 is 0x80; this is approximately halfway to 255, and as a consequence the UFixed8 representation is very near 0.5.  You can see the same change is reflected in r, v, and img: there is only one underlying array, img, and the two views simply reference it.Maybe you're used to having the color channel be the last dimension, rather than the first. We can achieve that using permuteddimsview:DocTestSetup = quote\n    using Colors, ImageCore\n    img = [RGB(1,0,0) RGB(0,1,0);\n           RGB(0,0,1) RGB(0,0,0)]\n    v = channelview(img)\n    r = rawview(v)\n    r[3,1,1] = 128\nendjulia> p = permuteddimsview(v, (2,3,1))\n2×2×3 Base.PermutedDimsArrays.PermutedDimsArray{FixedPointNumbers.UFixed{UInt8,8},3,(2,3,1),(3,1,2),ImageCore.ChannelView{FixedPointNumbers.UFixed{UInt8,8},3,Array{ColorTypes.RGB{FixedPointNumbers.UFixed{UInt8,8}},2}}}:\n[:, :, 1] =\n UFixed8(1.0)  UFixed8(0.0)\n UFixed8(0.0)  UFixed8(0.0)\n\n[:, :, 2] =\n UFixed8(0.0)  UFixed8(1.0)\n UFixed8(0.0)  UFixed8(0.0)\n\n[:, :, 3] =\n UFixed8(0.502)  UFixed8(0.0)\n UFixed8(1.0)    UFixed8(0.0)\n\njulia> p[1,2,:] = 0.25\n0.25\n\njulia> p\n2×2×3 Base.PermutedDimsArrays.PermutedDimsArray{FixedPointNumbers.UFixed{UInt8,8},3,(2,3,1),(3,1,2),ImageCore.ChannelView{FixedPointNumbers.UFixed{UInt8,8},3,Array{ColorTypes.RGB{FixedPointNumbers.UFixed{UInt8,8}},2}}}:\n[:, :, 1] =\n UFixed8(1.0)  UFixed8(0.251)\n UFixed8(0.0)  UFixed8(0.0)\n\n[:, :, 2] =\n UFixed8(0.0)  UFixed8(0.251)\n UFixed8(0.0)  UFixed8(0.0)\n\n[:, :, 3] =\n UFixed8(0.502)  UFixed8(0.251)\n UFixed8(1.0)    UFixed8(0.0)\n\njulia> v\n3×2×2 ImageCore.ChannelView{FixedPointNumbers.UFixed{UInt8,8},3,Array{ColorTypes.RGB{FixedPointNumbers.UFixed{UInt8,8}},2}}:\n[:, :, 1] =\n UFixed8(1.0)    UFixed8(0.0)\n UFixed8(0.0)    UFixed8(0.0)\n UFixed8(0.502)  UFixed8(1.0)\n\n[:, :, 2] =\n UFixed8(0.251)  UFixed8(0.0)\n UFixed8(0.251)  UFixed8(0.0)\n UFixed8(0.251)  UFixed8(0.0)\n\njulia> img\n2×2 Array{ColorTypes.RGB{FixedPointNumbers.UFixed{UInt8,8}},2}:\n RGB{U8}(1.0,0.0,0.502)  RGB{U8}(0.251,0.251,0.251)\n RGB{U8}(0.0,0.0,1.0)    RGB{U8}(0.0,0.0,0.0)Once again, p is a view, and as a consequence changing it leads to changes in all the coupled arrays and views."
},

{
    "location": "traits.html#",
    "page": "Traits",
    "title": "Traits",
    "category": "page",
    "text": ""
},

{
    "location": "traits.html#Traits-1",
    "page": "Traits",
    "title": "Traits",
    "category": "section",
    "text": "ImageCore supports several \"traits\" that are sometimes useful in viewing or analyzing images. Many of these traits become much more powerful if you are using add-on packages like ImagesAxes, which allows you to give \"physical meaning\" to the different axes of your image.  Readers are encouraged to view the documentation for ImageAxes to gain a better appreciation of how to exploit these traits.  When using plain arrays to represent images, most of the traits default to \"trivial\" outcomes.Let's illustrate with a couple of examples:julia> using Colors, ImageCore\n\njulia> img = rand(RGB{U8}, 680, 480);\n\njulia> pixelspacing(img)\n(1,1)pixelspacing returns the spacing between adjacent pixels along each axis. Using ImagesAxes, you can even use physical units to encode this information, for example for use in microscopy or biomedical imaging.DocTestSetup = quote\n    using Colors, ImageCore\n    img = rand(RGB{U8}, 680, 480);\nendjulia> coords_spatial(img)\n(1,2)This trait indicates that both dimensions 1 and 2 are \"spatial dimensions,\" meaning they correspond to physical space. This trait again becomes more interesting with ImagesAxes, where you can denote that some axes correspond to time (e.g., for a movie).A full list of traits is presented in the reference section."
},

{
    "location": "reference.html#",
    "page": "Reference",
    "title": "Reference",
    "category": "page",
    "text": ""
},

{
    "location": "reference.html#Reference-1",
    "page": "Reference",
    "title": "Reference",
    "category": "section",
    "text": ""
},

{
    "location": "reference.html#List-of-view-types-1",
    "page": "Reference",
    "title": "List of view types",
    "category": "section",
    "text": "With that as an introduction, let's list all the view types supported by this package.  channelview and colorview are opposite transformations, as are rawview and ufixedview. channelview and colorview typically create objects of type ChannelView and ColorView, respectively, unless they are \"undoing\" a previous view of the opposite type.channelview\nChannelView\ncolorview\nColorView\nrawview\nufixedview\npermuteddimsview"
},

{
    "location": "reference.html#ImageCore.pixelspacing",
    "page": "Reference",
    "title": "ImageCore.pixelspacing",
    "category": "Function",
    "text": "pixelspacing(img) -> (sx, sy, ...)\n\nReturn a tuple representing the separation between adjacent pixels along each axis of the image.  Defaults to (1,1,...).  Use ImagesAxes for images with anisotropic spacing or to encode the spacing using physical units.\n\n\n\n"
},

{
    "location": "reference.html#ImageCore.spacedirections",
    "page": "Reference",
    "title": "ImageCore.spacedirections",
    "category": "Function",
    "text": "spacedirections(img) -> (axis1, axis2, ...)\n\nReturn a tuple-of-tuples, each axis[i] representing the displacement vector between adjacent pixels along spatial axis i of the image array, relative to some external coordinate system (\"physical coordinates\").\n\nBy default this is computed from pixelspacing, but you can set this manually using ImagesMeta.\n\n\n\n"
},

{
    "location": "reference.html#ImageCore.sdims",
    "page": "Reference",
    "title": "ImageCore.sdims",
    "category": "Function",
    "text": "sdims(img)\n\nReturn the number of spatial dimensions in the image. Defaults to the same as ndims, but with ImagesAxes you can specify that some axes correspond to other quantities (e.g., time) and thus not included by sdims.\n\n\n\n"
},

{
    "location": "reference.html#ImageCore.coords_spatial",
    "page": "Reference",
    "title": "ImageCore.coords_spatial",
    "category": "Function",
    "text": "coords_spatial(img)\n\nReturn a tuple listing the spatial dimensions of img.\n\nNote that a better strategy may be to use ImagesAxes and take slices along the time axis.\n\n\n\n"
},

{
    "location": "reference.html#ImageCore.size_spatial",
    "page": "Reference",
    "title": "ImageCore.size_spatial",
    "category": "Function",
    "text": "size_spatial(img)\n\nReturn a tuple listing the sizes of the spatial dimensions of the image. Defaults to the same as size, but using ImagesAxes you can mark some axes as being non-spatial.\n\n\n\n"
},

{
    "location": "reference.html#ImageCore.indices_spatial",
    "page": "Reference",
    "title": "ImageCore.indices_spatial",
    "category": "Function",
    "text": "indices_spatial(img)\n\nReturn a tuple with the indices of the spatial dimensions of the image. Defaults to the same as indices, but using ImagesAxes you can mark some axes as being non-spatial.\n\n\n\n"
},

{
    "location": "reference.html#ImageCore.nimages",
    "page": "Reference",
    "title": "ImageCore.nimages",
    "category": "Function",
    "text": "nimages(img)\n\nReturn the number of time-points in the image array. Defaults to\n\nUse ImagesAxes if you want to use an explicit time dimension.\n\n\n\n"
},

{
    "location": "reference.html#ImageCore.assert_timedim_last",
    "page": "Reference",
    "title": "ImageCore.assert_timedim_last",
    "category": "Function",
    "text": "assert_timedim_last(img)\n\nThrow an error if the image has a time dimension that is not the last dimension.\n\n\n\n"
},

{
    "location": "reference.html#List-of-traits-1",
    "page": "Reference",
    "title": "List of traits",
    "category": "section",
    "text": "pixelspacing\nspacedirections\nsdims\ncoords_spatial\nsize_spatial\nindices_spatial\nnimages\nassert_timedim_last"
},

]}
