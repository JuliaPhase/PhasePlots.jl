# TODO

- [ ] `phaseplot` / `phaseplot!` (the `PhasePlot` recipe): finish it. It is meant to be a
  Makie recipe for phase maps (cyclic colormap, wrapped colour range, crop to the aperture,
  `phasetheme`), but it does not work as intended. It prints `@info "cropped array"` on every
  call. Not documented until fixed.
- [ ] `picsize` keyword of `showphase`, `showphase!` and `showphasetight` is not used: the
  downscaling of large arrays (`imresize`) is commented out. Either implement or remove.
- [ ] Ellipse geometry in `src/ellipse.jl` (`fit_ellipse`, `conic_to_axes`, `Ellipse`, …)
  duplicates EllipseGeometry.jl: take it from there (separate branch).
- [ ] `FFTViews` is loaded but not used.
- [ ] `draw_aperture2`: an experimental refactor of `draw_aperture` (in the GLMakie
  extension); merge or remove.
