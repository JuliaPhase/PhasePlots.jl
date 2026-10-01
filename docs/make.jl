using PhasePlots
using Documenter, Literate

DocMeta.setdocmeta!(PhasePlots, :DocTestSetup, :(using PhasePlots); recursive=true)

# ---- Convert example scripts to Markdown via Literate.jl ----
@info "Current dir = $(@__DIR__)"
tutorials_src = joinpath(@__DIR__, "..", "examples")
tutorials_dst = joinpath(@__DIR__, "src", "examples")
mkpath(tutorials_dst)
for f in readdir(tutorials_src; join=true)
    endswith(f, ".jl") || continue
    Literate.markdown(f, tutorials_dst)
end

makedocs(;
    sitename="PhasePlots.jl",
    modules=[PhasePlots],
    authors="Oleg Soloviev",
    repo=Remotes.GitHub("JuliaPhase", "PhasePlots.jl"),
    checkdocs=:exports,
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://juliaphase.github.io/PhasePlots.jl/stable/",
        assets=String[],
    ),
    clean=false,
    pages=[
        "Home" => "index.md",
        "About" => "about.md",
        "Examples" => [
            "Array orientation" => "examples/Orientation.md",
            "Phase maps" => "examples/PhaseMaps.md",
            "Tables of heatmaps" => "examples/HeatmapTables.md",
        ],
        "Interactive aperture" => "interactive.md",
        "Reference" => ["API" => "api.md"],
    ],
)

deploydocs(; repo="github.com/JuliaPhase/PhasePlots.jl", target="build", devbranch="main")
