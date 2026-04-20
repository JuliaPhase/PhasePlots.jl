# PhasePlots.jl — Copilot Context

## What this package is

`PhasePlots` provides CairoMakie-based visualization utilities for phase maps, PSFs, and related optical data. It is a thin display layer used in analysis notebooks and scripts across the Phase ecosystem.

## Key exported functions

| Function | Purpose |
|---|---|
| `showphase` / `showphase!` | Display a phase map with colormap and colorbar |
| `phaseplot` / `phaseplot!` | Flexible phase/wavefront plot with aperture masking |
| `phasetheme` | Makie theme for publication-quality phase figures |
| `phasemap` | Generate a colormap suitable for wrapped phase display |
| `plot_heatmaps_table` / `plot_heatmaps_table!` | Grid of heatmaps (e.g. Zernike mode table) |
| `showphasetight` | Compact single-panel phase figure |
| `showarray` | Generic array heatmap display |
| `draw_ellipse` / `draw_or_load_ellipse` | Overlay ellipse on a plot (e.g. aperture boundary) |
| `dpng` | Save figure to PNG with standard DPI settings |
| `save_figs_as_gif` | Animate a sequence of figures as GIF |

## Usage notes

- All plot functions follow Makie's `plot` / `plot!` convention (mutating vs. new figure).
- Phase arrays follow the `PhaseBases` axis convention: `A[row, col]` = `f(x_col, y_row)`; transpose before `heatmap` if needed.
- Uses `JLD2` for figure caching (`draw_or_load_ellipse`).

## Relationships

- Depends on: `CairoMakie`, `PhaseUtils`, `FFTViews`, `JLD2`
- Used by: `Feedback14AMI` (via extension), analysis notebooks and scripts

## Source layout

```
src/
    PhasePlots.jl    ← module entry, exports
    phasedisplay.jl  ← showphase, phaseplot, plot_heatmaps_table
    ellipse.jl       ← ellipse drawing utilities
    fileutils.jl     ← dpng, save_figs_as_gif
```
