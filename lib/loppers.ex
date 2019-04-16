defmodule Loppers do
  alias Loppers.{Walk, Validate, Match, List}

  @type error ::
    {:not_allowed, ast :: term}
  @type function_ref ::
{module :: atom, :__all__} |
    {module :: atom, :__submodules_all__} |
    {module :: atom, function :: atom} |
    (function :: atom)

  @type validate_option ::
    {:whitelist, [function_ref]} |
    {:blacklist, [function_ref]}


  @moduledoc ~S"""
  A code validator for the Elixir-AST.

  It can operate on both white- and blacklists.

  ## Basic example:

      iex> quoted = quote do "hello" |> String.upcase |> String.pad_leading(4, "0") end
      iex> whitelist = Loppers.special_forms ++ [{Kernel, :|>}, {String, :upcase}, {String, :pad_leading}]
      iex> Loppers.validate(quoted, whitelist: whitelist)
      :ok

  """

  @doc ~S"""
  Validates a syntax tree against the given whitelist.

  Use `Code.string_to_quoted/2` to get the syntax tree out of source code.

  When no whitelist is defined, it is assumed that all function calls are ok,
  except when they exist in the blacklist.

  Supplying both a white- and a blacklist can be useful, for example when you
  want to allow all functions of a module, except a few that you don't want:

      iex> whitelist = Loppers.special_forms ++ [{Enum, :__all__}]
      iex> blacklist = [{Enum, :map_reduce}]
      iex> quoted = quote do Enum.map_reduce([], nil, &({&1, nil})) end
      iex> Loppers.validate(quoted, [whitelist: whitelist, blacklist: blacklist])
      {:error, [
        not_allowed: {{:., [parent_modules: []],
          [
            {:__aliases__, [parent_modules: [], alias: false], [:Enum]},
            :map_reduce
          ]}, [parent_modules: []],
         [
           [],
           nil,
           {:&, [parent_modules: []],
            [{{:&, [parent_modules: []], [1]}, nil}]}
         ]}
      ]}

  ## Options

   * `:whitelist` - a list of `function_ref`s that are allowed in the code
   * `:blacklist` - a list of `function_ref`s that are forbidden in the code
  """
  @spec validate(quoted :: term, opts :: [validate_option]) ::
    :ok |
    {:error, [error]}
  def validate(quoted, opts) do
    {quoted, _acc} = Walk.walk(quoted, {%{}, [{Kernel, []}]}, &Walk.gen_meta/2)
    {quoted, _acc} = Walk.walk(quoted, [], &Walk.module_functions/2)
    {quoted, _acc} = Walk.recurse(quoted, %{}, &Walk.track_parent_modules/2)
    whitelist = Keyword.get(opts, :whitelist, nil)
    blacklist = Keyword.get(opts, :blacklist, [])
    acc = Validate.validate(quoted, [], fn {_, meta, _} = ast, acc ->
      # IO.inspect ast
      if Match.is_fn?(ast) do
        if (Keyword.get(meta, :allow, false) or whitelist == nil or List.in_list?(ast, whitelist))
          and not List.in_list?(ast, blacklist) do
          acc
        else
          [{:not_allowed, ast} | acc]
        end
      else
        acc
      end
    end)

    case acc do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  @doc """
  Convenience list of commonly used operators
  """
  def operators do
    [
      {Kernel, :+},
      {Kernel, :*},
      {Kernel, :/},
      {Kernel, :-},
      {Kernel, :<<>>},
      {Kernel, :<>},
      :"->",
      :<-
    ]
  end

  @doc """
  All functions and macros needed to define modules, functions and set attributes
  """
  def module_support do
    [
      {Kernel, :@},
      {Kernel, :defmodule},
      {Kernel, :def},
      :when
    ]
  end

  @doc """
  A list of all macros contained in `Kernel.SpecialForms`.

  Without those it's going to be hard to write any elixir code.
  """
  def special_forms do
    special_forms =
      [:functions, :macros]
      |> Enum.flat_map(&Kernel.SpecialForms.__info__/1)
      |> Keyword.keys()
    special_forms ++ [
      :{},
      :doc,
      :->,
      {Kernel, :is_binary}
    ]
  end
end
