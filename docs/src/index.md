```@meta
CurrentModule = PhasePlots
```

# PhasePlots.jl

Makie-based plotting helpers for phase maps and other 2D arrays, used throughout the
[Phase.jl](https://github.com/JuliaPhase/Phase.jl) packages.

## What it does

- **Shows 2D arrays the right way up.** Makie's `heatmap(A)` draws the first array index along
  the horizontal axis, so every matrix appears rotated. [`showarray`](@ref) and all other
  functions here draw `x` to the right and `y` up, both for images (row 1 at the top) and for
  functions sampled on a grid (`A[j, i] = f(x[i], y[j])`), optionally with the physical
  coordinates of a domain. See [Array orientation](examples/Orientation.md).
- **Shows phase as phase.** [`showphase`](@ref), [`showphase!`](@ref) and
  [`showphasetight`](@ref) wrap the phase to ``(-π, π]`` and use the cyclic colormap
  [`phasemap`](@ref), so that the wrapping produces no false edges.
  See [Phase maps](examples/PhaseMaps.md).
- **Shows many arrays at once.** [`plot_heatmaps_table`](@ref) puts a vector of arrays (modes,
  iterations, interferograms, …) in a grid with a common colour scale.
  See [Tables of heatmaps](examples/HeatmapTables.md).
- **Lets you draw an aperture.** With `using GLMakie`, [`draw_ellipse`](@ref) and
  [`draw_or_load_ellipse`](@ref) let you outline the pupil on an image with the mouse.
  See [Interactive aperture](interactive.md).

## Quick start

```julia
using PhasePlots
using CairoMakie

xr = range(-1, 1; length=201)
phase = [x^2 + y^2 <= 1 ? 20(x^2 + y^2) + 10x : NaN for y in xr, x in xr]

showarray(phase; frame=:domain)       # any 2D array, x to the right and y up
showphase(phase; frame=:domain)       # wrapped phase with a cyclic colormap and a colorbar
showphasetight(phase; frame=:domain)  # cropped to the pupil, no decorations
```

## Index

```@index
```

## Funding

This work is part of the 14AMI project (grant agreement No 101111948). The project is supported by the Chips Joint Undertaking and its members including the top-up funding by RVO (The Netherlands Enterprise Agency).

```@raw html
<img src="assets/funding/Chips-JU.png" alt="Chips Joint Undertaking, co-funded by the European Union" height="60" style="height: 60px; width: auto; margin-right: 1em;">
```
