# Views

ImageCore provides several different kinds of "views." Generically, a
view is an *interpretation* of array data, one that may change the
apparent meaning of the array but which shares the same underlying
storage: change an element of the view, and you also change the
original array. Views allow one to process images of immense size
without making copies, and write algorithms in the most convenient
format often without having to worry about the potential cost of
converting from one format to another.

To illustrate views, it's helpful to begin with a very simple image:

```julia
julia> using Colors

julia> img = [RGB(1,0,0) RGB(0,1,0);
              RGB(0,0,1) RGB(0,0,0)]
2×2 Array{ColorTypes.RGB{FixedPointNumbers.UFixed{UInt8,8}},2}:
 RGB{U8}(1.0,0.0,0.0)  RGB{U8}(0.0,1.0,0.0)
 RGB{U8}(0.0,0.0,1.0)  RGB{U8}(0.0,0.0,0.0)
```

```@meta
DocTestSetup = quote
    using Colors, ImageCore
    img = [RGB(1,0,0) RGB(0,1,0);
           RGB(0,0,1) RGB(0,0,0)]
    v = channelview(img)
    r = rawview(v)
end
```

`RGB` is described in the
[Colors package](https://github.com/JuliaGraphics/Colors.jl), and the
image is just a plain 2×2 array containing red, green, blue, and black
pixels.  In Julia's color package, "1" means "saturated" (e.g., "full
red"), and "0" means "black".  In a moment you'll see that's true no
matter how the information is represented internally.

As with all of Julia's arrays, you can access individual elements:

```julia
julia> img[1,2]
RGB{U8}(0.0,1.0,0.0)
```

One of the nice things about this representation of the image is that
all of the indices in `img[i,j,...]` correspond to locations in the
image: you don't need to worry about some dimensions of the array
corresponding to "color channels" and other the spatial location, and
you're guaranteed to get the entire pixel contents when you access
that location.

That said, occassionally there are reasons to want to treat `RGB` as a
3-component vector.  That's motivation for introducing our first view:

```julia
julia> v = channelview(img)
3×2×2 ImageCore.ChannelView{FixedPointNumbers.UFixed{UInt8,8},3,Array{ColorTypes.RGB{FixedPointNumbers.UFixed{UInt8,8}},2}}:
[:, :, 1] =
 UFixed8(1.0)  UFixed8(0.0)
 UFixed8(0.0)  UFixed8(0.0)
 UFixed8(0.0)  UFixed8(1.0)

[:, :, 2] =
 UFixed8(0.0)  UFixed8(0.0)
 UFixed8(1.0)  UFixed8(0.0)
 UFixed8(0.0)  UFixed8(0.0)
```

`v` is a 3×2×2 array of numbers (`UFixed8` is defined in
[FixedPointNumbers](https://github.com/JeffBezanson/FixedPointNumbers.jl)
and can be abbreviated as `U8`), where the three elements of the first
dimension correspond to the red, green, and blue color channels,
respectively. `channelview` does exactly what the name suggests:
provide a view of the array using separate channels for the color
components.

If you're not familiar with `UFixed8`, then you may find another view
type, `rawview`, illuminating:

```julia
julia> r = rawview(v)
3×2×2 MappedArrays.MappedArray{UInt8,3,ImageCore.ChannelView{FixedPointNumbers.UFixed{UInt8,8},3,Array{ColorTypes.RGB{FixedPointNumbers.UFixed{UInt8,8}},2}},ImageCore.##11#13,ImageCore.##12#14{FixedPointNumbers.UFixed{UInt8,8}}}:
[:, :, 1] =
 0xff  0x00
 0x00  0x00
 0x00  0xff

[:, :, 2] =
 0x00  0x00
 0xff  0x00
 0x00  0x00
```

This is an array of `UInt8` numbers, with 0 printed as 0x00 and 255
printed as 0xff. Despite the apparent "floating point" representation
of the image above, we see that it's actually represented using 8-bit
unsigned integers.  The `UFixed8` type presents such an integer as a
fixed-point number ranging from 0 to 1.  As a consequence, there is no
discrepancy in "meaning" between the encoding of images represented as
floating point or 8-bit or 16-bit integers: 0 always means "black" and
1 always means "white" or "saturated."

Let's make a change in one of the entries:

```julia
julia> r[3,1,1] = 128
128

julia> r
3×2×2 MappedArrays.MappedArray{UInt8,3,ImageCore.ChannelView{FixedPointNumbers.UFixed{UInt8,8},3,Array{ColorTypes.RGB{FixedPointNumbers.UFixed{UInt8,8}},2}},ImageCore.##11#13,ImageCore.##12#14{FixedPointNumbers.UFixed{UInt8,8}}}:
[:, :, 1] =
 0xff  0x00
 0x00  0x00
 0x80  0xff

[:, :, 2] =
 0x00  0x00
 0xff  0x00
 0x00  0x00

julia> v
3×2×2 ImageCore.ChannelView{FixedPointNumbers.UFixed{UInt8,8},3,Array{ColorTypes.RGB{FixedPointNumbers.UFixed{UInt8,8}},2}}:
[:, :, 1] =
 UFixed8(1.0)    UFixed8(0.0)
 UFixed8(0.0)    UFixed8(0.0)
 UFixed8(0.502)  UFixed8(1.0)

[:, :, 2] =
 UFixed8(0.0)  UFixed8(0.0)
 UFixed8(1.0)  UFixed8(0.0)
 UFixed8(0.0)  UFixed8(0.0)

julia> img
2×2 Array{ColorTypes.RGB{FixedPointNumbers.UFixed{UInt8,8}},2}:
 RGB{U8}(1.0,0.0,0.502)  RGB{U8}(0.0,1.0,0.0)
 RGB{U8}(0.0,0.0,1.0)    RGB{U8}(0.0,0.0,0.0)
```

The hexidecimal representation of 128 is 0x80; this is approximately
halfway to 255, and as a consequence the `UFixed8` representation is
very near 0.5.  You can see the same change is reflected in `r`, `v`,
and `img`: there is only one underlying array, `img`, and the two
views simply reference it.

Maybe you're used to having the color channel be the last dimension,
rather than the first. We can achieve that using `permuteddimsview`:

```@meta
DocTestSetup = quote
    using Colors, ImageCore
    img = [RGB(1,0,0) RGB(0,1,0);
           RGB(0,0,1) RGB(0,0,0)]
    v = channelview(img)
    r = rawview(v)
    r[3,1,1] = 128
end
```

```julia
julia> p = permuteddimsview(v, (2,3,1))
2×2×3 Base.PermutedDimsArrays.PermutedDimsArray{FixedPointNumbers.UFixed{UInt8,8},3,(2,3,1),(3,1,2),ImageCore.ChannelView{FixedPointNumbers.UFixed{UInt8,8},3,Array{ColorTypes.RGB{FixedPointNumbers.UFixed{UInt8,8}},2}}}:
[:, :, 1] =
 UFixed8(1.0)  UFixed8(0.0)
 UFixed8(0.0)  UFixed8(0.0)

[:, :, 2] =
 UFixed8(0.0)  UFixed8(1.0)
 UFixed8(0.0)  UFixed8(0.0)

[:, :, 3] =
 UFixed8(0.502)  UFixed8(0.0)
 UFixed8(1.0)    UFixed8(0.0)

julia> p[1,2,:] = 0.25
0.25

julia> p
2×2×3 Base.PermutedDimsArrays.PermutedDimsArray{FixedPointNumbers.UFixed{UInt8,8},3,(2,3,1),(3,1,2),ImageCore.ChannelView{FixedPointNumbers.UFixed{UInt8,8},3,Array{ColorTypes.RGB{FixedPointNumbers.UFixed{UInt8,8}},2}}}:
[:, :, 1] =
 UFixed8(1.0)  UFixed8(0.251)
 UFixed8(0.0)  UFixed8(0.0)

[:, :, 2] =
 UFixed8(0.0)  UFixed8(0.251)
 UFixed8(0.0)  UFixed8(0.0)

[:, :, 3] =
 UFixed8(0.502)  UFixed8(0.251)
 UFixed8(1.0)    UFixed8(0.0)

julia> v
3×2×2 ImageCore.ChannelView{FixedPointNumbers.UFixed{UInt8,8},3,Array{ColorTypes.RGB{FixedPointNumbers.UFixed{UInt8,8}},2}}:
[:, :, 1] =
 UFixed8(1.0)    UFixed8(0.0)
 UFixed8(0.0)    UFixed8(0.0)
 UFixed8(0.502)  UFixed8(1.0)

[:, :, 2] =
 UFixed8(0.251)  UFixed8(0.0)
 UFixed8(0.251)  UFixed8(0.0)
 UFixed8(0.251)  UFixed8(0.0)

julia> img
2×2 Array{ColorTypes.RGB{FixedPointNumbers.UFixed{UInt8,8}},2}:
 RGB{U8}(1.0,0.0,0.502)  RGB{U8}(0.251,0.251,0.251)
 RGB{U8}(0.0,0.0,1.0)    RGB{U8}(0.0,0.0,0.0)
```

Once again, `p` is a view, and as a consequence changing it leads to
changes in all the coupled arrays and views.

Finally, you can combine multiple arrays into a "virtual" multichannel
array. In conjunction with `colorview`, this can be used to combine
two or three grayscale images into single color image. We'll use the
[lighthouse](http://juliaimages.github.io/TestImages.jl/images/lighthouse.png)
image:

```julia
using ImageCore, TestImages, Colors
img = testimage("lighthouse")
# Split out into separate channels
cv = channelview(img)
# Recombine the channels, filling in 0 for the middle (green) channel
s = StackedView(cv[1,:,:], zeroarray, cv[3,:,:])

julia> size(s)
(3,512,768)

sc = colorview(RGB, s)
```

Within the context of `StackedView`, `zeroarray` stands for an
all-zeros array of size that matches the other arguments of
`StackedView`.

`sc` looks like this:

![redblue](redblue.png)

In this case, we could have done the same thing somewhat more simply
with `cv[2,:,:] = 0` and then visualize `img`. However, more generally
`StackedView` lets you link two images that might have come from
different sources, "stacking" them along the first dimension (which is
readily reinterpreted as a color channel).
