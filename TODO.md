# TODO

## reproducible builds of Mix deps

I want to build and cache the result of `mix deps.compile`, but the mechanism of `mix` and `rebar3` stops me from do doing that:

- `mix` writes `compile.elixir` files to `_build/` directry, and `compile.elixir` file changes between different builds.
- `rebar3` writes `source.dag` files to `deps/` directory, and `source.dag` file changes between different builds.

To cache the result, I have to make sure that `deps/` and `_build/` won't change between different builds.

To achieve that, I have to:

1. dig into rebar3's `source.dag` generating code: https://github.com/erlang/rebar3/blob/ec224b7921cda1f9a1ef4373e80e706c173bf75f/src/rebar_compiler.erl#L333
2. dig into mix's `compile.elixir` generating code: https://github.com/elixir-lang/elixir/blob/9daef619419a505391094d19ebb578b449dea8d8/lib/mix/lib/mix/compilers/elixir.ex#L34

Then, try to fix this problem.
