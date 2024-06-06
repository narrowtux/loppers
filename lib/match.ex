defmodule Loppers.Match do
  def matches?({function, context, _args}, function) do
    !Keyword.has_key?(context, :import) and !Keyword.has_key?(context, :alias)
  end

  # alias Enum, as: E
  # E.map(:a, :b)
  # {
  #   {:., [], [{:__aliases__, [alias: Enum], [:E]}, :map]},
  #   [],
  #   [:a, :b]}

  # ABC.fun(1, 2, 3)
  # {{:., [], [{:__aliases__, [alias: false], [:ABC]}, :fun]}, [], [1, 2, 3]}

  # Handling :__submodules_all__
  def matches?({{:., _dot_meta, [{:__aliases__, aliases, called_as}, _called_fn]}, fn_meta, _arguments}, {mod, :__submodules_all__}) do

    called_module = case Keyword.get(aliases, :alias, false) do
      false ->
        parent_modules = Keyword.get(fn_meta, :parent_modules, [])
        list_to_module(parent_modules ++ called_as)

      aliased_module ->
        aliased_module
    end

    # Check if "Module.Child" has the Prefix for "Module."
    String.starts_with?("#{called_module}", "#{mod}.")
  end


  def matches?({{:., _dot_meta, [{:__aliases__, aliases, called_as}, called_fn]}, _fn_meta, _arguments}, {mod, list_fn})
  when called_fn == list_fn or list_fn == :__all__ do
    called_module = case Keyword.get(aliases, :alias, false) do
      false -> list_to_module(called_as)
      aliased_module -> aliased_module
    end

    mod == called_module
  end

  # special case for calling erlang module functions
  def matches?({{:., _dot_context, [erlang_module, called_fn]}, _fn_context, _arguments}, {mod, list_fn})
    when (called_fn == list_fn or list_fn == :__all__)
    and erlang_module == mod do
    true
  end

  # import Enum
  # map(:a, :b)
  # {:map, [context: Elixir, import: Enum], [:a, :b]}

  def matches?({called_fn, context, _arguments}, {mod, list_fn}) do
    module_candidates =
      cond do
        Keyword.has_key?(context, :import) ->
          [Keyword.get(context, :import)]

        Keyword.has_key?(context, :imports) ->
          context
          |> Keyword.get(:imports, [])
          |> Enum.map(&elem(&1, 1))
          |> Enum.uniq()

        true ->
          []
      end

    called_module = List.first(module_candidates)

    cond do
      length(module_candidates) > 1 -> false
      length(module_candidates) == 0 -> false
      true ->
        mod == called_module && (list_fn == called_fn || list_fn == :__all__)
    end


  end

  def matches?(_, _) do
    false
  end

  def is_fn?(ast) when not is_tuple(ast), do: false
  def is_fn?({:__aliases__, _, _}), do: false
  def is_fn?({_variable, context, nil}) do
    Keyword.has_key?(context, :alias) or Keyword.has_key?(context, :import)
  end
  def is_fn?({:__ENV__, _, _}), do: false
  def is_fn?({:__block__, _, _}), do: false
  def is_fn?({:do, _}), do: false
  def is_fn?(_), do: true

  def list_to_module([:erlang, mod]), do: mod
  def list_to_module(list) do
    [:Elixir | list]
    |> Enum.map(&Atom.to_string/1)
    |> Enum.join(".")
    |> String.to_atom
  end
end
