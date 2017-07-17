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

## Installation

The package can be installed by adding `loppers` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [{:loppers, "~> 0.1.0"}]
end
```
