module PhasePlotsGLMakieExt

# Interactive tools (drawing an aperture, recording GIFs) that need an interactive Makie
# backend. Loaded automatically after `using GLMakie`.

using PhasePlots
using PhasePlots:
    fit_ellipse,
    mask_ellipse,
    _pos_to_elpoints,
    draw_filled_polygon_on_ranges,
    convex_hull,
    transform_marker
using PhaseUtils: ap2mask
using GLMakie
using GLMakie: Gray, N0f8
using CairoMakie: CairoMakie
using JLD2

function PhasePlots.draw_ellipse(img)
    ready = false
    displayhelp = Observable(true)
    state = Observable(:pass)

    helpmessage = """
    Controls :
    a to switch to "add a point" mode
    d to switch to "delete a point" mode
    p to switch to passive mode
    e to toggle ellipse/polygon mode
    h to show/hide this message
    mouse wheel or left mouse press and draw to zoom
    right mouse to pan
    Ctrl+click to reset zoom
    Esc or q to quit
    """

    isbig = size(img)[1] > 128 && size(img)[2] > 128

    fig, ax, implot = image(rotr90(img); axis=(aspect=DataAspect(),), interpolate=isbig)

    mode = :ellipse
    positions = Observable(Point2f[])
    current_el = lift(fit_ellipse, positions)
    el_points = map(_pos_to_elpoints, positions)
    overlay = lift(current_el) do current_el
        mask = mask_ellipse(rotr90(img), current_el)
        ap2mask(1 .- mask)
    end

    image!(overlay; colormap=(:Blues, 0.4))

    p = scatter!(ax, positions)
    c = lines!(ax, el_points)

    text!(
        0.1,
        0.9;
        text=helpmessage,
        space=:relative,
        color=:white,
        font=:bold,
        align=(:left, :top),
        visible=displayhelp,
        glowwidth=1,
        fontsize=24,
    )

    on(events(fig).mousebutton; priority=2) do event
        if event.button == Mouse.left && event.action == Mouse.press
            if state[] == :delete
                # Delete marker
                plt, i = pick(fig)
                if plt == p
                    deleteat!(positions[], i)
                    notify(positions)
                    return Consume(true)
                end
            elseif state[] == :add
                # Add marker
                push!(positions[], mouseposition(ax))
                notify(positions)
                return Consume(true)
            end
        end
        return Consume(false)
    end

    screen = display(fig)

    on(events(fig).keyboardbutton) do event
        if event.action == Keyboard.press || event.action == Keyboard.repeat
            if event.key == Keyboard.q || event.key == Keyboard.escape
                println("q/esc is pressed, the data are saved")
                println("$(fit_ellipse(to_value(positions)))")
                ready = true
                close(screen)
                # return el .= current_el[]
            elseif event.key == Keyboard.h
                displayhelp[] = !displayhelp[]
            elseif event.key == Keyboard.a
                state[] = :add
            elseif event.key == Keyboard.d
                state[] = :delete
            elseif event.key == Keyboard.p
                state[] = :pass
            end

        end
    end
    wait(screen)
    return to_value(current_el), rotr90(mask_ellipse(rotr90(img), to_value(current_el)), 3)
end  # function draw_ellipse

function PhasePlots.draw_or_load_ellipse(elfile, img, apfile=""; saveap=false)
    if apfile == ""
        apfile = joinpath(dirname(elfile), "ap.tif")
    end

    return try
        el = load(elfile, "el")
        @info "Aperture loaded"
        el
    catch
        @info "Aperture not found, please draw it"
        GLMakie.activate!()
        el, ap = draw_ellipse(img)
        saveap && (save(apfile, Gray{N0f8}.(ap));
        @info "$apfile is saved")
        jldsave(elfile; el)
        CairoMakie.activate!(; type="png")
        el
    end
end

# Updated draw_aperture with an additional convex hull mode.
function PhasePlots.draw_aperture(img)
    ready = false
    displayhelp = Observable(true)
    state = Observable(:pass)

    helpmessage = """
    Controls :
    a to switch to "add a point" mode
    d to switch to "delete a point" mode
    p to switch to passive mode
    e to toggle through ellipse, polygon, and convex hull modes
    h to show/hide this message
    mouse wheel or left mouse press & drag: Zoom
    Right mouse: Pan
    Ctrl+click: Reset zoom
    Esc or q: Quit and save the data
    """

    rotated = rotr90(img)
    # sim = size(img)
    xrange, yrange = Base.axes(img)
    fig, ax, implot = image(rotated; axis=(aspect=DataAspect(),))

    # Observable mode can be :ellipse, :polygon or :hull.
    mode = Observable(:ellipse)
    positions = Observable(Point2f[])

    current_el = lift(fit_ellipse, positions)
    # Compute mask for user-drawn polygon.
    current_poly = lift(positions) do pos
        if length(pos) ≥ 3
            return draw_filled_polygon_on_ranges(xrange, yrange, reverse.(pos); fill_value=1)
        else
            return zeros(Float32, size(rotated)...)
        end
    end
    # Compute mask for the convex hull of the positions.
    current_hull = lift(positions) do pos
        if length(pos) ≥ 3
            hull_pts = convex_hull(reverse.(pos))
            return draw_filled_polygon_on_ranges(xrange, yrange, hull_pts; fill_value=1)
        else
            return zeros(Float32, size(rotated)...)
        end
    end

    # The overlay is built depending on the selected mode.
    overlay = lift(current_el, current_poly, current_hull, mode) do el, poly, hull, m

        if m == :ellipse && any(el .!= 0)
            mask = mask_ellipse(rotated, el)
            return ap2mask(1 .- mask)
        elseif m == :polygon
            return ap2mask(1 .- poly)
        elseif m == :hull
            return ap2mask(1 .- hull)
        else
            return zeros(eltype(rotated), size(rotated)...)
        end
    end

    image!(overlay; colormap=(:Blues, 0.4))

    p = scatter!(ax, positions)
    c = lines!(ax, map(_pos_to_elpoints, positions))

    text!(
        0.1,
        0.9;
        text=helpmessage,
        space=:relative,
        color=:white,
        font=:bold,
        align=(:left, :top),
        visible=displayhelp,
        glowwidth=1,
        fontsize=24,
    )

    on(events(fig).mousebutton; priority=2) do event
        if event.button == Mouse.left && event.action == Mouse.press
            if state[] == :delete
                plt, i = pick(fig)
                if plt == p
                    deleteat!(positions[], i)
                    notify(positions)
                    return Consume(true)
                end
            elseif state[] == :add
                push!(positions[], mouseposition(ax))
                notify(positions)
                return Consume(true)
            end
        end
        return Consume(false)
    end

    screen = display(fig)

    on(events(fig).keyboardbutton) do event
        if event.action in (Keyboard.press, Keyboard.repeat)
            if event.key == Keyboard.q || event.key == Keyboard.escape
                println("q/esc is pressed, the data are saved")
                println("$(fit_ellipse(to_value(positions)))")
                ready = true
                close(screen)
            elseif event.key == Keyboard.h
                displayhelp[] = !displayhelp[]
            elseif event.key == Keyboard.a
                state[] = :add
            elseif event.key == Keyboard.d
                state[] = :delete
            elseif event.key == Keyboard.p
                state[] = :pass
            elseif event.key == Keyboard.e
                # Cycle the mode: ellipse -> polygon -> hull -> ellipse -> ...
                mode[] = (
                    mode[] == :ellipse ? :polygon : (mode[] == :polygon ? :hull : :ellipse)
                )
            end
        end
    end

    wait(screen)
    # Return different values based on the mode.
    if mode[] == :ellipse
        return to_value(current_el), rotr90(mask_ellipse(rotated, to_value(current_el)), 3)
    elseif mode[] == :polygon
        return reverse.(to_value(positions)), rotr90(to_value(current_poly), 3)
    else  # mode == :hull
        let pts = reverse.(to_value(positions))
            hull_pts = length(pts) ≥ 3 ? convex_hull(pts) : pts
            return hull_pts, rotr90(to_value(current_hull), 3)
        end
    end
end  # function draw_aperture

# When drawing filled polygons, we use ranges corresponding to the rotated image.
# (Rows: 1:nrows, Columns: 1:ncols)

# Refactored draw_aperture function using the improved transform_marker.
function draw_aperture2(img)
    ready = false
    displayhelp = Observable(true)
    state = Observable(:pass)

    helpmessage = """
    Controls :
      a     to switch to "add a point" mode
      d     to switch to "delete a point" mode
      p     to switch to passive mode
      e     to toggle through ellipse, polygon, and convex hull modes
      h     to show/hide this message
      Mouse wheel or left mouse press & drag: Zoom
      Right mouse: Pan
      Ctrl+click: Reset zoom
      Esc or q: Quit and save the data
    """

    # Rotate the image once.
    rotated = rotr90(img)
    # Note: rotated now has size (nrows_rot, ncols_rot) and is displayed as-is.
    fig, ax, implot = image(rotated; axis=(aspect=DataAspect(),))

    # mode will be one of :ellipse, :polygon, or :hull.
    mode = Observable(:ellipse)
    # Positions are stored in the coordinate system for "rotated" image: (row, col)
    positions = Observable(Point2f[])

    # When adding a marker, immediately convert the raw marker from the displayed coordinate system
    # (traditional image space) into the rotated (matrix index) space.
    on(events(fig).mousebutton; priority=2) do event
        if event.button == Mouse.left && event.action == Mouse.press
            if state[] == :delete
                plt, i = pick(fig)
                if plt == p
                    deleteat!(positions[], i)
                    notify(positions)
                    return Consume(true)
                end
            elseif state[] == :add
                raw_pos = mouseposition(ax)
                mpos = transform_marker(raw_pos, img)
                push!(positions[], mpos)
                notify(positions)
                return Consume(true)
            end
        end
        return Consume(false)
    end

    # Build the ellipse, polygon and convex hull masks based on the rotated image coordinates.
    current_el = lift(fit_ellipse, positions)
    current_poly = lift(positions) do pos
        if length(pos) ≥ 3
            nrows, ncols = size(rotated)
            return draw_filled_polygon_on_ranges(1:ncols, 1:nrows, pos; fill_value=1)
        else
            return zeros(Float32, size(rotated)...)
        end
    end
    current_hull = lift(positions) do pos
        if length(pos) ≥ 3
            hull_pts = convex_hull(pos)
            nrows, ncols = size(rotated)
            return draw_filled_polygon_on_ranges(1:ncols, 1:nrows, hull_pts; fill_value=1)
        else
            return zeros(Float32, size(rotated)...)
        end
    end

    # Build overlay according to the current mode.
    overlay = lift(current_el, current_poly, current_hull, mode) do el, poly, hull, m
        if m == :ellipse && any(el .!= 0)
            mask = mask_ellipse(rotated, el)
            return ap2mask(1 .- mask)
        elseif m == :polygon
            return ap2mask(1 .- poly)
        elseif m == :hull
            return ap2mask(1 .- hull)
        else
            return zeros(eltype(rotated), size(rotated)...)
        end
    end

    image!(overlay; colormap=(:Blues, 0.4))
    p = scatter!(ax, positions)
    c = lines!(ax, map(_pos_to_elpoints, positions))

    text!(
        0.1,
        0.9;
        text=helpmessage,
        space=:relative,
        color=:white,
        font=:bold,
        align=(:left, :top),
        visible=displayhelp,
        glowwidth=1,
        fontsize=24,
    )

    on(events(fig).keyboardbutton) do event
        if event.action in (Keyboard.press, Keyboard.repeat)
            if event.key == Keyboard.q || event.key == Keyboard.escape
                println("q/esc is pressed, the data are saved")
                println("$(fit_ellipse(to_value(positions)))")
                ready = true
                close(screen)
            elseif event.key == Keyboard.h
                displayhelp[] = !displayhelp[]
            elseif event.key == Keyboard.a
                state[] = :add
            elseif event.key == Keyboard.d
                state[] = :delete
            elseif event.key == Keyboard.p
                state[] = :pass
            elseif event.key == Keyboard.e
                # Cycle through modes.
                mode[] = (
                    mode[] == :ellipse ? :polygon : (mode[] == :polygon ? :hull : :ellipse)
                )
            end
        end
    end

    screen = display(fig)
    wait(screen)
    # Rotate the mask back to the original orientation (using rotr90 with appropriate count)
    if mode[] == :ellipse
        return to_value(current_el), rotr90(mask_ellipse(rotated, to_value(current_el)), 3)
    elseif mode[] == :polygon
        return to_value(positions), rotr90(to_value(current_poly), 3)
    else  # mode == :hull
        let pts = to_value(positions)
            hull_pts = length(pts) ≥ 3 ? convex_hull(pts) : pts
            return hull_pts, rotr90(to_value(current_hull), 3)
        end
    end
end  # function draw_aperture2

function PhasePlots.save_figs_as_gif(figs, name, fps=2)
    cb = Makie.current_backend()
    GLMakie.activate!()
    figanim = Figure(; size=figs[1].figure.scene.camera.resolution[])
    record(figanim, name, figs; framerate=fps) do f
        figanim = f
        display(figanim)
    end
    return cb.activate!()
end

end # module
