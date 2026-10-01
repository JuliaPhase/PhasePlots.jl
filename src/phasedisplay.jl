"""
    phasemap

The cyclic colormap used for phase maps (`:cyclic_mygbm_30_95_c78_n256` from ColorSchemes):
its colours at both ends coincide, so wrapping of the phase at ``±π`` produces no visible
edges. Use it with any Makie plot, e.g. `heatmap(A; colormap=phasemap, colorrange=(-π, π))`.
"""
phasemap = :cyclic_mygbm_30_95_c78_n256

"""
    orient(arr; frame=:image, rot=1)

Reorient a 2D array so that `heatmap` shows it with `x` to the right and `y` up.

Two array conventions are supported, selected by `frame`:

- `:image` (default) — the array comes from an image file or is otherwise indexed
  `A[row, col]` with row 1 at the **top** (`y = -row`). The array is rotated by `rot`
  times 90° clockwise (`rotr90(arr, rot)`).
- `:domain` — the array is sampled on a grid with ascending coordinates,
  `A[j, i] = f(x[i], y[j])` (as for `SampledDomains.CartesianDomain2D`), so row 1 is the
  **smallest** `y`. The array is transposed (`rot` is ignored).

See the *About* page of `PhaseBases` and the `SampledDomains` documentation for details.
"""
function orient(arr; frame::Symbol=:image, rot=1)
    if frame === :image
        return rotr90(arr, rot)
    elseif frame === :domain
        return permutedims(arr)
    else
        throw(ArgumentError("`frame` must be :image or :domain, got :$frame"))
    end
end

# xrange, yrange of a domain-like object (e.g. `SampledDomains.CartesianDomain2D`)
function _domain_ranges(dom, arr)
    xr, yr = dom.xrange, dom.yrange
    size(arr) == (length(yr), length(xr)) || throw(
        DimensionMismatch(
            "array of size $(size(arr)) does not match the domain, expected " *
            "(length(yrange), length(xrange)) = ($(length(yr)), $(length(xr)))",
        ),
    )
    return xr, yr
end

# axis options for a plot over a domain: x/y labels, user options win
_domain_axis(args) = merge((xlabel="x", ylabel="y"), get(args, :axis, (;)))
_without_axis(args) = (; (k => v for (k, v) in pairs(args) if k !== :axis)...)

"""
    showarray(arr; colormap=:viridis, frame=:image, rot=1, kwargs...)
    showarray(dom, arr; colormap=:viridis, kwargs...)
    showarray(x, y, arr; colormap=:viridis, frame=:image, rot=1, kwargs...)

Show a 2D array as a heatmap with `x` to the right and `y` up, and equal aspect ratio.

- `showarray(arr)` treats `arr` as an image (row 1 at the top), see [`orient`](@ref).
  Use `frame=:domain` for an array sampled on a grid with ascending `y`
  (`A[j, i] = f(x[i], y[j])`).
- `showarray(dom, arr)` takes the coordinates from a domain such as
  `SampledDomains.CartesianDomain2D` (any object with `xrange` and `yrange` fields), so the axes
  show the physical coordinates and are labelled `x` and `y`. Override with
  `axis=(xlabel=..., ylabel=...)`. The array must have size
  `(length(dom.yrange), length(dom.xrange))`.
- `showarray(x, y, arr)` uses explicit coordinate vectors.

Returns `(fig, ax, hm)`. `showarray!` draws into an existing axis instead.

# Example
```julia
dom = CartesianDomain2D(-1:0.05:1, -0.5:0.05:0.5)
A = [x + 2y for y in dom.yrange, x in dom.xrange]   # increases to the right and upward
fig, ax, hm = showarray(dom, A)
```
"""
function showarray(arr; colormap=:viridis, frame=:image, rot=1, args...)
    return heatmap(
        orient(arr; frame, rot);
        colormap=colormap,
        args...,
        axis=merge(get(args, :axis, (;)), (aspect=DataAspect(),)),
    )
end

function showarray(x, y, arr; colormap=:viridis, frame=:image, rot=1, args...)
    return heatmap(
        x,
        y,
        orient(arr; frame, rot);
        colormap=colormap,
        args...,
        axis=merge(get(args, :axis, (;)), (aspect=DataAspect(),)),
    )
end

function showarray(dom, arr; colormap=:viridis, args...)
    xr, yr = _domain_ranges(dom, arr)
    return showarray(
        xr,
        yr,
        arr;
        colormap=colormap,
        frame=:domain,
        _without_axis(args)...,
        axis=_domain_axis(args),
    )
end

function showarray!(arr; colormap=:viridis, frame=:image, rot=1, args...)
    return heatmap!(orient(arr; frame, rot); colormap=colormap, args...)
end

function showarray!(ax, arr; colormap=:viridis, frame=:image, rot=1, args...)
    return heatmap!(ax, orient(arr; frame, rot); colormap=colormap, args...)
end

"""
    showarray!(ax, dom, arr; colormap=:viridis, kwargs...)

Draw `arr` sampled on `dom` into the existing axis `ax`, using the domain coordinates.
See [`showarray`](@ref).
"""
function showarray!(ax, dom, arr; colormap=:viridis, args...)
    xr, yr = _domain_ranges(dom, arr)
    return heatmap!(ax, xr, yr, orient(arr; frame=:domain); colormap=colormap, args...)
end

"""
    showphase(inarr; rot=1, fig=Figure(), picsize=512, cm=phasemap)

Display a phase array as a heatmap with a colorbar.

# Arguments
- `inarr`: Input array representing the phase.
- `rot`: Number of 90° clockwise rotations to apply to the array (default: 1), see [`orient`](@ref).
- `frame`: `:image` (default) or `:domain` (array sampled on a grid with ascending `y`), see [`orient`](@ref).
- `fig`: Optional `Figure` object to plot on (default: new `Figure`).
- `picsize`: Maximum size of the plot (default: 512).
- `cm`: Colormap to use (default: `phasemap`).

# Returns
A tuple `(fig, ax, cb)` containing the figure, axis, and colorbar objects.

# Example
```julia
using CairoMakie
arr = rand(100, 100) * 2π - π
fig, ax, cb = showphase(arr)
fig
```
"""
function showphase(inarr; rot=1, frame=:image, fig=Figure(), picsize=512, cm=phasemap)
    # if max(size(rotr90(inarr))...) > picsize
    #     arr = imresize(inarr, picsize)
    # else
    arr = Array(inarr)
    # end

    ax = CairoMakie.Axis(fig[1, 1]; aspect=1)
    hm = heatmap!(ax, phwrap.(orient(arr; frame, rot)); colormap=cm, colorrange=(-π, π))
    cb = Colorbar(fig[1, 2], hm; width=10, tellheight=true)
    return fig, ax, cb
end

"""
    showphase!(ax, inarr; rot=1, frame=:image, cm=phasemap)

Draw the phase array `inarr` into the existing axis `ax`: the phase is wrapped to
``(-π, π]`` and shown with the cyclic colormap `cm` over the colour range `(-π, π)`.
Returns the heatmap, e.g. to make a `Colorbar`. See [`showphase`](@ref) and [`orient`](@ref).
"""
function showphase!(ax, inarr; rot=1, frame=:image, picsize=512, cm=phasemap)
    arr = Array(inarr)
    hm = heatmap!(ax, phwrap.(orient(arr; frame, rot)); colormap=cm, colorrange=(-π, π))
    return hm
end

"""
    showphasetight(inarr, fig=Figure(); picsize=512, cm=phasemap, hidedec=true, kwarg...)

Display a phase array as a heatmap with tight axis limits.

# Arguments
- `inarr`: Input array representing the phase.
- `fig`: Optional `Figure` object to plot on (default: new `Figure`).
- `picsize`: Maximum size of the plot (default: 512).
- `cm`: Colormap to use (default: `phasemap`).
- `hidedec`: Whether to hide axis decorations (default: true).
- `frame`: `:image` (default) or `:domain`, see [`orient`](@ref).
- `kwarg`: Additional keyword arguments for the heatmap.

# Returns
A tuple `(fig, ax, hm)` containing the figure, axis, and heatmap objects.

# Example
```julia
using CairoMakie
arr = rand(100, 100) * 2π - π
fig, ax, hm = showphasetight(arr)
fig
```
"""
function showphasetight(
    inarr, fig=Figure(); frame=:image, picsize=512, cm=phasemap, hidedec=true, kwarg...
)
    inarr = bboxview(Array(inarr))
    # if max(size(inarr)...) > picsize
    #     arr = imresize(inarr, picsize)
    # else
    arr = inarr
    # end

    if typeof(fig) == GridPosition
        pos = fig
    else
        pos = fig[1, 1]
    end
    ax = CairoMakie.Axis(pos; aspect=AxisAspect(1))
    hm = heatmap!(ax, phwrap.(orient(arr; frame)); colormap=cm, colorrange=(-π, π), kwarg...)
    if hidedec
        hidedecorations!(ax; grid=false)
    end
    return fig, ax, hm
end

# TODO: `phaseplot` does not work as intended yet (not documented until fixed), see TODO.md
@recipe(PhasePlot, arr) do scene
    Attributes(; colormap=phasemap, colorrange=(-π, π), crop=true, frame=:image)
    # Theme(
    #         Axis = (
    #             aspect = 1,
    #             leftspinevisible = false,
    #             rightspinevisible = false,
    #             bottomspinevisible = false,
    #             topspinevisible = false,
    #             yticksvisible = false,
    #             xticksvisible = false,
    #             yticklabelsvisible = false,
    #             xticklabelsvisible = false,
    #             xautolimitmargin = (0, 0),
    #             yautolimitmargin = (0, 0),
    #         ),
    # )
end

function Makie.plot!(p::PhasePlot{<:Tuple{<:AbstractArray}})
    arr = p[:arr][]
    # arr =p[:arr][] |> rotr90
    if p[:crop][]
        @info "cropped array"
        arr = bboxview(p[:arr][])
    end
    # hm = heatmap!(p, rotr90(arr); colormap = p[:colormap],
    # colorrange=p[:colorrange][],
    # axis = (aspect =  1,)
    # )
    with_theme(phasetheme) do
        heatmap!(p, orient(arr; frame=p[:frame][]))
    end

    # tightlimits!(p.plots.axis)
    # @info p.plots
    return p
end

"""
    phasetheme

A Makie `Theme` for phase maps: [`phasemap`](@ref) as the default colormap, equal aspect ratio,
and axes without spines, ticks, tick labels and margins. Use it as
`with_theme(phasetheme) do ... end`.
"""
phasetheme = Theme(;
    Axis=(
        aspect=1,
        leftspinevisible=false,
        rightspinevisible=false,
        bottomspinevisible=false,
        topspinevisible=false,
        yticksvisible=false,
        xticksvisible=false,
        yticklabelsvisible=false,
        xticklabelsvisible=false,
        xautolimitmargin=(0, 0),
        yautolimitmargin=(0, 0),
    ),
    colormap=phasemap,
)

# functions to show array of similar plots
#
#
"""
    plot_heatmaps_table(heatmaps_array; ncols=0, width=150, height=150, colormap=:viridis, limits=(0,0), hidedecorations=false, rot=1, aspect=DataAspect(), kwargs...)

Show a vector of 2D arrays as a matrix of heatmaps with a common colorbar below.

# Arguments
- `heatmaps_array`: Vector of 2D arrays to display as heatmaps.
- `ncols`: Number of columns in the grid (default: auto-calculated).
- `width`: Width of each heatmap (default: 150).
- `height`: Height of each heatmap (default: 150).
- `colormap`: Colormap to use (default: `:viridis`).
- `limits`: Common color range for all heatmaps (default: auto-calculated).
- `hidedecorations`: Whether to hide axis decorations (default: false).
- `rot`: Number of 90° clockwise rotations to apply to each array (default: 1).
- `frame`: `:image` (default) or `:domain`, see [`orient`](@ref).
- `aspect`: Aspect ratio for the axes (default: `DataAspect()`).
- `kwargs`: Additional keyword arguments for the heatmaps.

# Returns
A `Figure` object containing the heatmaps.

# Example
```julia
using CairoMakie
heatmaps = [rand(10, 10) for _ in 1:4]
fig = plot_heatmaps_table(heatmaps; ncols=2)
fig
```
"""
function plot_heatmaps_table(
    heatmaps_array;
    x=nothing,
    y=nothing,
    ncols::Int=0,
    width=150,
    height=150,
    colormap=:viridis,
    limits=(0, 0),
    hidedecorations=false,
    frame=:image,
    rot=1,
    titles="",
    title="",
    titlesize=20,
    aspect=DataAspect(),
    kwargs...,
)
    l = length(heatmaps_array)

    if titles == ""
        titles = fill("", l)
    end

    if ncols == 0
        ## Calculate the number of columns based on the number of heatmaps
        ncols = ceil(Int, sqrt(l))
    end
    ind(i) = divrem(i - 1 + ncols, ncols)

    _nrows = ceil(Int, l / ncols)
    fig = Figure(; size=(width * ncols, height * _nrows))

    ## Define a common color range for all heatmaps
    if limits == (0, 0)
        min_val = minimum([minimum(filter(!isnan, hm)) for hm in heatmaps_array])
        max_val = maximum([maximum(filter(!isnan, hm)) for hm in heatmaps_array])
    else
        min_val, max_val = limits
    end

    ## Generate heatmaps
    for (i, arr) in enumerate(heatmaps_array)
        ax = Axis(fig[ind(i)...]; width=width, height=height, aspect=aspect)
        ax.title = titles[i]
        if hidedecorations
            hidedecorations!(ax)
        end
        if !(x === nothing) && !(y === nothing)
            heatmap!(
                ax,
                x,
                y,
                orient(arr; frame, rot);
                colorrange=(min_val, max_val),
                colormap=colormap,
                kwargs...,
            )
        else

            heatmap!(
                ax,
                orient(arr; frame, rot);
                colorrange=(min_val, max_val),
                colormap=colormap,
                kwargs...,
            )
        end
    end

    ## Add a common colorbar
    Colorbar(fig[end + 1, :]; limits=(min_val, max_val), colormap=colormap, vertical=false)

    if title != ""
        Label(fig[0, :], title; fontsize=titlesize)
    end


    resize_to_layout!(fig)
    return fig
end

"""
    plot_heatmaps_table!(parent_layout, heatmaps_array; show_colorbar=false, kwargs...)

Like [`plot_heatmaps_table`](@ref), but draws the table into `parent_layout` (a `GridLayout`
or a position in an existing figure, e.g. `GridLayout(fig[1, 1])`) instead of creating a new
figure. The common colorbar is drawn only with `show_colorbar=true`. Accepts the same keywords
as `plot_heatmaps_table`, except `x` and `y`.
"""
function plot_heatmaps_table!(
    parent_layout,
    heatmaps_array;
    ncols::Int=0,
    width=150,
    height=150,
    colormap=:viridis,
    limits=(0, 0),
    hidedecorations=false,
    frame=:image,
    rot=1,
    titles="",
    title="",
    titlesize=20,
    show_colorbar=false, # New keyword argument to control colorbar display
    aspect=DataAspect(),
    kwargs...,
)

    if titles == ""
        titles = fill("", length(heatmaps_array))
    end

    if ncols == 0
        ## Calculate the number of columns based on the number of heatmaps
        ncols = ceil(Int, sqrt(length(heatmaps_array)))
    end
    ind(i) = divrem(i - 1 + ncols, ncols)

    _nrows = ceil(Int, length(heatmaps_array) / ncols)

    ## Define a common color range for all heatmaps
    if limits == (0, 0)
        min_val = minimum([minimum(filter(!isnan, hm)) for hm in heatmaps_array])
        max_val = maximum([maximum(filter(!isnan, hm)) for hm in heatmaps_array])
    else
        min_val, max_val = limits
    end


    ## Generate heatmaps
    for (i, hm) in enumerate(heatmaps_array)
        row, col = ind(i)
        ax = Axis(parent_layout[row, col]; width=width, height=height, aspect=aspect)
        ax.title = titles[i]
        if hidedecorations
            hidedecorations!(ax)
        end
        heatmap!(
            ax, orient(hm; frame, rot); colorrange=(min_val, max_val), colormap=colormap, kwargs...
        )
    end

    ## Add a common colorbar
    show_colorbar && Colorbar(
        parent_layout[_nrows + 1, 1];
        limits=(min_val, max_val),
        colormap=colormap,
        vertical=false,
    )

    if title != ""
        Label(parent_layout[0, 1], title; fontsize=titlesize)
    end
end

"""
    circle_with_hole(r=0.9)

A ring-shaped marker (`BezierPath`): a unit circle with a hole of radius `r`. Useful to mark
points on top of an image without hiding the image beneath them.

# Example
```julia
fig, ax, hm = showarray(rand(50, 50))
scatter!(ax, [25], [25]; marker=circle_with_hole(), markersize=30, color=:red)
fig
```
"""
circle_with_hole(r=0.9) =BezierPath([
    MoveTo(Point(1, 0)),
    EllipticalArc(Point(0, 0), 1, 1, 0, 0, 2pi),
    EllipticalArc(Point(0, 0), r, r, 0, 0, -2pi),
    ClosePath(),
])

export showphase, showphasetight, showarray, phasemap, showarray!, phaseplot, phaseplot!
export phasetheme
export plot_heatmaps_table, plot_heatmaps_table!, circle_with_hole
