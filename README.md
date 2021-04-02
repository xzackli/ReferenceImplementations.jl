# Slow.jl

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://xzackli.github.io/Slow.jl/stable) -->
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://xzackli.github.io/Slow.jl/dev)
[![Build Status](https://github.com/xzackli/Slow.jl/workflows/CI/badge.svg)](https://github.com/xzackli/Slow.jl/actions)
[![codecov](https://codecov.io/gh/xzackli/Slow.jl/branch/main/graph/badge.svg?token=rM1AU0MQ38)](https://codecov.io/gh/xzackli/Slow.jl)

This package exports `@slowdef` and `@slow` macros to help you write fast scientific code. For instructions, please consult the [documentation](https://xzackli.github.io/Slow.jl/dev).

```julia
using Slow

# fake naive implementation
@slowdef function f(x)
    sleep(1)  
    return sin(x)
end

# fake fast implementation
f(x) = sin(x)

@time @slow f(1.0)
@time f(1.0)
```
