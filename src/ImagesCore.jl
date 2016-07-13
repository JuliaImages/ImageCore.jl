module ImagesCore

using Colors, FixedPointNumbers
using Colors: Fractional

using Base: tail

export
    ChannelView,
    ColorView

include("colorchannels.jl")

end ## module
