module PhasePlots

using CairoMakie
using FFTViews
using PhaseUtils
using JLD2

include("fileutils.jl")
include("ellipse.jl")
include("phasedisplay.jl")

function __init__()
    Base.Experimental.register_error_hint(_glmakie_hint, MethodError)
end

export dpng,
    save_figs_as_gif,
    draw_ellipse,
    draw_or_load_ellipse,
    showarray,
    showphase,
    showphase!,
    plot_heatmaps_table
export plot_heatmaps_table!, showphasetight, phaseplot, phaseplot!, phasemap, phasetheme

end
