"""
    pixelspacing(img) -> (sx, sy, ...)

Return a tuple representing the separation between adjacent pixels
along each axis of the image.  Defaults to (1,1,...).  Use
ImagesAxes for images with anisotropic spacing or to encode the
spacing using physical units.
"""
pixelspacing{T,N}(img::AbstractArray{T,N}) = ntuple(d->1, Val{N})

"""
    spacedirections(img) -> (axis1, axis2, ...)

Return a tuple-of-tuples, each `axis[i]` representing the displacement
vector between adjacent pixels along spatial axis `i` of the image
array, relative to some external coordinate system ("physical
coordinates").

By default this is computed from `pixelspacing`, but you can set this
manually using ImagesMeta.
"""
spacedirections(img::AbstractArray) = _spacedirections(pixelspacing(img))
function _spacedirections{N}(ps::NTuple{N})
    ntuple(i->ntuple(d->d==i ? ps[d] : zero(ps[d]), Val{N}), Val{N})
end

"""
    sdims(img)

Return the number of spatial dimensions in the image. Defaults to the
same as `ndims`, but with ImagesAxes you can specify that some axes
correspond to other quantities (e.g., time) and thus not included by
`sdims`.
"""
sdims(img::AbstractArray) = length(coords_spatial(img))

"""
   coords_spatial(img)

Return a tuple listing the spatial dimensions of `img`.

Note that a better strategy may be to use ImagesAxes and take slices along the time axis.
"""
coords_spatial{T,N}(img::AbstractArray{T,N}) = ntuple(identity, Val{N})

"""
    nimages(img)

Return the number of time-points in the image array. Defaults to
1. Use ImagesAxes if you want to use an explicit time dimension.
"""
nimages(img::AbstractArray) = 1

"""
    size_spatial(img)

Return a tuple listing the sizes of the spatial dimensions of the
image. Defaults to the same as `size`, but using ImagesAxes you can
mark some axes as being non-spatial.
"""
size_spatial(img) = size(img)

"""
    indices_spatial(img)

Return a tuple with the indices of the spatial dimensions of the
image. Defaults to the same as `indices`, but using ImagesAxes you can
mark some axes as being non-spatial.
"""
indices_spatial(img) = indices(img)

#### Utilities for writing "simple algorithms" safely ####
# If you don't feel like supporting multiple representations, call these

"""
    assert_timedim_last(img)

Throw an error if the image has a time dimension that is not the last
dimension.
"""
assert_timedim_last(img::AbstractArray) = nothing

#### Permutations over dimensions ####

# TODO: decide about the default storage order!!
widthheight(img::AbstractArray) = size(img,1), size(img,2)

width(img::AbstractArray) = widthheight(img)[1]
height(img::AbstractArray) = widthheight(img)[2]

#### Low-level utilities ####
"""
    permutation(to, from) -> p

Calculate the permutation of labels in `from` to produce the order in
`to`. Any entries in `to` that are missing in `from` will receive an
index of 0. Any entries in `from` that are missing in `to` will have
their indices appended to the end of the permutation. Consequently,
the length of `p` is equal to the longer of `to` and `from`.
"""
function permutation(to, from)
    n = length(to)
    nf = length(from)
    li = linearindices(from)
    d = Dict(from[i]=>i for i in li)
    covered = similar(dims->falses(length(li)), li)
    ind = Array(Int, max(n, nf))
    for (i,toi) in enumerate(to)
        j = get(d, toi, 0)
        ind[i] = j
        if j != 0
            covered[j] = true
        end
    end
    k = n
    for i in li
        if !covered[i]
            d[from[i]] != i && throw(ArgumentError("no duplicates in from allowed"))
            k += 1
            k > nf && throw(ArgumentError("no incomplete containment allowed in $to and $from"))
            ind[k] = i
        end
    end
    ind
end
