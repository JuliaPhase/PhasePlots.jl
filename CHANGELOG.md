# Changelog

All notable changes to PhasePlots.jl are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- `frame` keyword (`:image` default, `:domain`) for `showarray`, `showarray!`, `showphase`, `showphase!`, `showphasetight`, `phaseplot` and `plot_heatmaps_table(!)`: `:domain` displays arrays sampled on a grid with ascending `y` (`A[j, i] = f(x[i], y[j])`) correctly oriented
- `showarray(dom, A)` and `showarray!(ax, dom, A)`: take the coordinates from a domain (anything with `xrange` and `yrange`, e.g. `SampledDomains.CartesianDomain2D`), show real axis values and label the axes `x` and `y`
- `PhasePlots.orient` — the array reorientation used by all of the above
- `CHANGELOG.md` — started tracking changes following Keep a Changelog format
- `.github/copilot-instructions.md` — added project context for GitHub Copilot (key types, exported functions, relationships, source layout)
- Documentation (Documenter + Literate): overview, array orientation, phase maps, tables of heatmaps, interactive aperture, API reference
- Docstrings for `showphase!`, `plot_heatmaps_table!`, `phasemap`, `phasetheme`, `circle_with_hole`, `draw_aperture`, `save_figs_as_gif`
- A hint to run `using GLMakie` when an interactive function is called without it

### Changed
- GLMakie is now a weak dependency: the interactive tools (`draw_ellipse`, `draw_or_load_ellipse`, `draw_aperture`) and `save_figs_as_gif` live in the extension `PhasePlotsGLMakieExt` and need `using GLMakie`

### Removed
- `save2` (unused test helper)

