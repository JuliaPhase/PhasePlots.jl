using PhasePlots
using Test
using PhaseUtils
using CairoMakie

@testset "PhasePlots.jl" begin
    # Write your tests here.
    s = (110,100)
    arr = zeros(s)
    y = range(-1.21,1.21,s[1])
    x = range(-1.1,1.1,s[2])
    
    arr[[x.^2 + y.^2 .<= 1 for y in y, x in x]] .= 1 
    showarray(arr)
    phaseplot(arr, axis = (aspect = DataAspect(),))

    mask = ap2mask(arr)
    phaseplot(arr .* mask,axis = (aspect = DataAspect(),))
    
    phase = copy(arr)
    phase = [-x^3 + 3x.^2 + y.^2 - 10y for y in y, x in x]
    phaseplot(phase .* mask,axis = (aspect = DataAspect(),))
    fig,ax, hm = phaseplot(phwrap(phase .* mask),axis = (aspect = DataAspect(),))
    ax.title = "Using `crop = true` option"
    hidedecorations!(ax, grid=false)
    fig |> display
    fig, ax, hm = phaseplot(phwrap(phase .* mask), crop = false,axis = (aspect = DataAspect(),))
    ax.title = "Using `crop = false` option"
    fig |> display
    fig, ax,hm = showphasetight(phase .* mask, hidedec = false)
    ax.title = "Using function `showphasetight`"
    ax.subtitle = "`hidedec` = false"
    fig |> display
    fig, ax,hm = showphasetight(phase .* mask, hidedec = true)
    ax.title = "Using function `showphasetight`"
    ax.subtitle = "`hidedec` = true"
    fig |> display
    
    

    fig, ax,hm = with_theme(phasetheme) do 
       heatmap(bboxview(phwrap(rotr90(phase .* mask)) )) 
    end
    ax.title = "Using phasetheme"
    fig |> display

    fig, ax,hm = with_theme(phasetheme) do 
        phaseplot(phwrap(phase .* mask)) 
     end
     ax.title = "Using phasetheme and `phaseplot`"
     fig |> display
    

end

# A minimal stand-in for `SampledDomains.CartesianDomain2D` (anything with xrange/yrange works)
struct _TestDomain
    xrange::AbstractRange
    yrange::AbstractRange
end

@testset "array orientation (frame / domain)" begin
    dom = _TestDomain(-1:0.5:1, 0:1.0:2)             # 5 samples in x, 3 in y
    A = [x + 10y for y in dom.yrange, x in dom.xrange]  # A[j, i] = f(x[i], y[j])
    @test size(A) == (3, 5)

    # `:domain` is the transpose: first heatmap index runs along x
    @test PhasePlots.orient(A; frame=:domain) == permutedims(A)
    # `:image` keeps the previous behaviour
    @test PhasePlots.orient(A) == rotr90(A)
    @test PhasePlots.orient(A; rot=2) == rotr90(A, 2)
    @test_throws ArgumentError PhasePlots.orient(A; frame=:bogus)

    # showarray(dom, A): x to the right, y up, coordinates and labels from the domain
    fig, ax, hm = showarray(dom, A)
    @test hm[3][] == permutedims(A)
    @test ax.xlabel[] == "x" && ax.ylabel[] == "y"
    # the plotted value grows with x (rows of the plot) and with y (columns of the plot)
    @test all(diff(hm[3][]; dims=1) .> 0)
    @test all(diff(hm[3][]; dims=2) .> 0)

    # user axis options win
    fig, ax, hm = showarray(dom, A; axis=(xlabel="u [mm]",))
    @test ax.xlabel[] == "u [mm]" && ax.ylabel[] == "y"

    # array size must match the domain
    @test_throws DimensionMismatch showarray(dom, permutedims(A))

    # other entry points accept `frame`
    fig, ax, hm = showarray(A; frame=:domain)
    @test hm[3][] == permutedims(A)
    fig, ax, hm = showphasetight(A; frame=:domain)
    fig2 = Figure()
    ax2 = Axis(fig2[1, 1])
    hm2 = showarray!(ax2, dom, A)
    @test hm2[3][] == permutedims(A)
end

@testset "interactive tools need GLMakie" begin
    # without GLMakie the functions exist (documented) but have no methods
    @test isempty(methods(draw_ellipse))
    err = try
        draw_ellipse(zeros(3, 3))
    catch e
        e
    end
    @test err isa MethodError
    @test occursin("using GLMakie", sprint(showerror, err))
end

using GLMakie

@testset "GLMakie extension" begin
    @test Base.get_extension(PhasePlots, :PhasePlotsGLMakieExt) !== nothing
    for f in (draw_ellipse, draw_or_load_ellipse, PhasePlots.draw_aperture, save_figs_as_gif)
        @test !isempty(methods(f))
    end
end
