using Slow
using Documenter

DocMeta.setdocmeta!(Slow, :DocTestSetup, :(using Slow); recursive=true)

makedocs(;
    modules=[Slow],
    authors="Zack Li",
    repo="https://github.com/xzackli/Slow.jl/blob/{commit}{path}#{line}",
    sitename="Slow.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://xzackli.github.io/Slow.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/xzackli/Slow.jl",
    devbranch = "main"
)
