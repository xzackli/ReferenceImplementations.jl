using ReferenceImplementations
using Documenter

DocMeta.setdocmeta!(ReferenceImplementations, :DocTestSetup, :(using ReferenceImplementations); recursive=true)

makedocs(;
    modules=[ReferenceImplementations],
    authors="Zack Li",
    repo="https://github.com/xzackli/ReferenceImplementations.jl/blob/{commit}{path}#{line}",
    sitename="ReferenceImplementations.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://xzackli.github.io/ReferenceImplementations.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/xzackli/ReferenceImplementations.jl",
    devbranch = "main"
)
