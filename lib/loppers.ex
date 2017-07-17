defmodule Loppers do
  @type error ::
    {:not_in_whitelist, ast :: term} |
    {:in_blacklist, ast :: term}

  @doc """
  Validates a syntax tree against the given whitelist.

  Use `Code.string_to_quoted/2` to get the syntax tree out of source code.
  """
  @spec validate_whitelist(quoted :: term, whitelist :: list) ::
    :ok |
    {:error, [error]}
  def validate_whitelist(quoted, whitelist) do
    acc = Loppers.Validate.validate(quoted, [], fn ast, acc ->
      # IO.inspect ast
      if Loppers.Match.is_fn?(ast) do
        if Loppers.List.in_list?(ast, whitelist) do
          acc
        else
          IO.inspect ast, label: "Not in whitelist"
          [{:not_in_whitelist, ast} | acc]
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
  Validates a syntax tree against the given whitelist.

  Use `Code.string_to_quoted/2` to get the syntax tree out of source code.
  """
  def validate_blacklist(quoted, blacklist) do

  end

  def operators do
    [
      {Kernel, :+},
      {Kernel, :*},
      {Kernel, :/},
      {Kernel, :-},
    ]
  end

  def module_support do
    [
      {Kernel, :defmodule},
      {Kernel, :def}
    ]
  end

  def special_forms do
    [:functions, :macros]
    |> Enum.flat_map(&Kernel.SpecialForms.__info__/1)
    |> Keyword.keys()
  end
end
