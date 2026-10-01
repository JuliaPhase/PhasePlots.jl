# About PhasePlots.jl

## Why a separate package

Every package of Phase.jl produces the same kinds of pictures: phase maps in a pupil, point
spread functions, sets of basis modes, interferograms, results of successive iterations.
Plotting them with plain Makie calls means repeating the same few lines (rotate the array,
fix the aspect ratio, choose a colormap and a colour range, add a colorbar) and getting them
slightly different each time. PhasePlots collects these lines in one place, so that the
pictures look the same across the packages and the scripts that use them.

PhasePlots is deliberately thin: its functions return the usual Makie objects
(`Figure`, `Axis`, heatmap plots), which can be customised further with Makie itself.

## Array orientation

Makie's `heatmap(A)` puts the first array index on the horizontal axis. The plotting functions
here reorient the array so that `x` points to the right and `y` up. Two array conventions are
supported, selected with the keyword `frame`:

| Array | Row 1 is | `frame` | How it is shown |
|---|---|---|---|
| image from a file | top (`y = -row`) | `:image` (default) | rotated clockwise (`rotr90`) |
| sampled on a grid with ascending `y`, `A[j, i] = f(x[i], y[j])` | smallest `y` | `:domain` | transposed |

The second convention is the one of `SampledDomains.CartesianDomain2D` and of the other
Phase.jl packages (see the *About* page of PhaseBases). For arrays sampled on a domain (any
object with fields `xrange` and `yrange`), `showarray(dom, A)` also shows the physical
coordinates on the axes.

## Phase maps

Phase is defined modulo ``2π``. The phase functions wrap their input to ``(-π, π]`` and show
it with the cyclic colormap [`phasemap`](@ref) over the fixed colour range `(-π, π)`, so that
the colours of ``-π`` and ``π`` coincide and the same phase value always has the same colour.
Values outside the aperture are expected to be `NaN`: they are not drawn, and
[`showphasetight`](@ref) crops the picture to the bounding box of the non-`NaN` values.

## Backends

The static plotting functions work with any Makie backend; PhasePlots itself loads
CairoMakie. The interactive tools ([`draw_ellipse`](@ref), [`draw_or_load_ellipse`](@ref),
[`PhasePlots.draw_aperture`](@ref)) and [`save_figs_as_gif`](@ref) need GLMakie and become
available after `using GLMakie` (a package extension), so GLMakie and OpenGL are not required
for the rest of the package.
