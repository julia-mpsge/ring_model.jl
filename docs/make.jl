
using ring_model
using Documenter

DocMeta.setdocmeta!(ring_model, :DocTestSetup, :(using ring_model); recursive=true)


const _PAGES = [
    "Introduction" => ["index.md"],
    "API Reference" => ["api_reference.md"]
]


makedocs(;
    modules=[ring_model],
    authors="Mitch Phillipson",
    sitename="Ring Model",
    format=Documenter.HTML(;
        canonical="https://julia-mpsge.github.io/ring_model.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=_PAGES
)

deploydocs(;
    repo = "github.com/julia-mpsge/ring_model.jl",
    devbranch = "main",
    branch = "gh-pages"
)

