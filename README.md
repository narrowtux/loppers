# Loppers

A code validator for the Elixir-AST.

It can operate on both white- and blacklists.

## Basic example:
```elixir
quoted = quote do
  "hello"
  |> String.upcase
  |> String.pad_leading(4, "0")
end
whitelist = Loppers.special_forms ++ [
  {Kernel, :|>},
  {String, :upcase},
  {String, :pad_leading}
]
:ok = Loppers.validate(quoted, whitelist: whitelist)
```

## Features

 * Ideally used in combination with `Code.string_to_quoted/2` to check for
   nasty things in untrusted code.
 * Operate against a whitelist, blacklist or a mix of both (blacklist > whitelist)
 * Works with `alias` and `import` in the code (special handling for that in
   the `Loppers.Walk` module)
 * Returns the AST-Fragment (including the line number if your compiler provides it)
   so you can add squiggly lines to the editor at the right place.

## Installation

The package can be installed by adding `loppers` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [{:loppers, "~> 0.1.0"}]
end
```
