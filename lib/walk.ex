defmodule Loppers.Walk do
  import Loppers.Match, only: [list_to_module: 1]

  def walk({_, _, _} = ast, acc, walker) do
    {{fun, meta, args}, acc} = walker.(ast, acc)
    {args, _acc} = reduce_args(args, acc, walker)
    {fun, _acc} = walk(fun, acc, walker)
    ast = {fun, meta, args}
    {ast, acc}
  end

  def walk([{key, {_, _, _} = call}], acc, walker) do
    {call, acc} = walk(call, acc, walker)
    {[{key, call}], acc}
  end

  def walk(primitive, acc, _walker)
    when is_atom(primitive) or
         is_number(primitive) or
         is_binary(primitive) or
         is_integer(primitive) do
    {primitive, acc}
  end

  def walk({key, value}, acc, walker) do
    {key, _} = walk(key, acc, walker)
    {value, _} = walk(value, acc, walker)
    {{key, value}, acc}
  end

  def walk(list, acc, walker) when is_list(list) do
    reduce_args(list, acc, walker)
  end

  def reduce_args(nil, acc, _) do
    {nil, acc}
  end
  def reduce_args(args, acc, walker) do
    Enum.map_reduce(args, acc, &walk(&1, &2, walker))
  end

  def gen_meta({:alias, _, args} = ast, {aliases, imports}) do
    {aka, opts} = case args do
      [aka, opts] -> {aka, opts}
      [aka] -> {aka, []}
    end
    aliases = case {aka, Keyword.get(opts, :as)} do
      {{:__aliases__, _, old_name}, {:__aliases__, _, new_name}} ->
        Map.put(aliases, new_name, list_to_module(old_name))
      {{:__aliases__, _, full_name}, nil} ->
        new_name = [List.last(full_name)]
        old_name = list_to_module(full_name)
        Map.put(aliases, new_name, old_name)
    end

    {ast, {aliases, imports}}
  end
  def gen_meta({:import, _, args} = ast, {aliases, imports}) do
    imported = case args do
      [{:__aliases__, _, mod}] -> {list_to_module(mod), []}
      [{:__aliases__, _, mod}, opts] -> {list_to_module(mod), opts}
    end
    {ast, {aliases, [imported | imports]}}
  end
  def gen_meta({:__aliases__, meta, new_name}, {aliases, _} = acc) do
    meta = if old_name = Map.get(aliases, new_name, nil) do
      Keyword.put(meta, :alias, old_name)
    else
      meta
    end

    {{:__aliases__, meta, new_name}, acc}
  end
  def gen_meta({fun, meta, args} = ast, {_, imports} = acc) when is_list(args) do
    imported_module = Enum.find(imports, &function_imported?(&1, fun, length(args)))
    case imported_module do
      nil ->
        {ast, acc}
      {module, _} ->
        meta = Keyword.put(meta, :import, module)
        {{fun, meta, args}, acc}
    end
  end
  def gen_meta(ast, {aliases, imports}) do
    {ast, {aliases, imports}}
  end

  def function_imported?({module, opts}, function, arity) do
    excluded = {function, arity} in Keyword.get(opts, :except, [])
    included = case Keyword.get(opts, :only) do
      nil -> true
      list -> {function, arity} in list
    end
    [:functions, :macros]
    |> Enum.flat_map(&module.__info__/1)
    |> Enum.any?(fn
      {^function, ^arity} -> included and not excluded
      _ -> false
    end)
  end
end
