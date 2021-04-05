using SlowMacro
using Documenter

DocMeta.setdocmeta!(SlowMacro, :DocTestSetup, :(using SlowMacro); recursive=true)

makedocs(;
    modules=[SlowMacro],
    authors="Zack Li",
    repo="https://github.com/xzackli/SlowMacro.jl/blob/{commit}{path}#{line}",
    sitename="SlowMacro.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://xzackli.github.io/SlowMacro.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/xzackli/SlowMacro.jl",
    devbranch = "main"
)
