# Interactive aperture

Before processing an interferogram or a pupil image, one needs to know where the pupil is.
[`draw_ellipse`](@ref) shows the image in a GLMakie window and lets you click points on the
boundary of the pupil. An ellipse is fitted to the points (from five points on) and its
interior is highlighted on top of the image, so you can add or remove points until the fit
is good.

These functions need an interactive backend and are loaded with GLMakie:

```julia
using PhasePlots
using GLMakie

img = load("interferogram.png")    # any 2D array, row 1 at the top
el, ap = draw_ellipse(img)         # conic coefficients and the aperture mask
```

## Controls

| Key / mouse | Action |
|---|---|
| `a`, then click | add a point |
| `d`, then click on a point | delete the point |
| `p` | passive mode (clicks do nothing) |
| `h` | show/hide the help message |
| mouse wheel, or left button drag | zoom |
| right button drag | pan |
| `Ctrl` + click | reset the zoom |
| `Esc` or `q` | close the window and return the result |

The result `el` is the vector of coefficients `[A, B, C, D, E, F]` of the ellipse
``A x^2 + B xy + C y^2 + D x + E y + F = 0`` and `ap` is the boolean mask of its interior,
of the same size as `img`.

## Drawing once, loading afterwards

In a processing script it is convenient to draw the aperture only the first time and reuse it
afterwards. [`draw_or_load_ellipse`](@ref) loads the ellipse from a JLD2 file and, if the file
does not exist yet, asks you to draw it and saves it:

```julia
el = draw_or_load_ellipse("data/aperture.jld2", img; saveap=true)  # also saves data/ap.tif
```

## Other shapes

[`PhasePlots.draw_aperture`](@ref) works the same way, and the key `e` switches between three
shapes of the aperture: the fitted ellipse, the polygon through the points and their convex
hull.
