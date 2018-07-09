defmodule Loppers.Walk do
  import Loppers.Match, only: [list_to_module: 1]

  @doc """
  Walking a given ast filling the accumulator using a walker-function.

  Walker signature needs to be `walker.(ast, acc)`
  """
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

  @doc "Helper to call walker callback for each args."
  def reduce_args(nil, acc, _) do
    {nil, acc}
  end
  def reduce_args(args, acc, walker) do
    Enum.map_reduce(args, acc, &walk(&1, &2, walker))
  end


  # Testing walk() or recurse()
  #def inspect(a, b), do: {a, b} |> IO.inspect(label: "inspect")



  def track_parent_modules({:defmodule, meta_defmodule, [{:__aliases__, aliases_meta, parent_modules} | rest]}, acc) do

    # Add defined module to parent_modules in acc for whole branch.

    ast = {:defmodule, meta_defmodule, [{:__aliases__, aliases_meta, parent_modules} | rest]}
    acc = Map.update(acc, :parent_modules, parent_modules, &(&1 ++ parent_modules))

    {ast, acc}
  end

  def track_parent_modules({fun, meta, args}, acc) do

    # Add parent_modules to meta of function call from acc.
    meta = Keyword.put(meta, :parent_modules, Map.get(acc, :parent_modules, []))

    {{fun, meta, args}, acc}
  end

  def track_parent_modules(ast, acc), do: {ast, acc}




  @doc """
  Recursing into the AST. Difference to walk() is that the accumulator will only be changed for current branch.
  """
  def recurse({_, _, _} = ast, acc, callback) do
    {{fun, meta, args}, acc} = callback.(ast, acc)

    {args, _acc} = recurse(args, acc, callback)
    {fun, _acc} = recurse(fun, acc, callback)

    {{fun, meta, args}, acc}
  end


  def recurse({key, value}, acc, callback) do
    {{key, value}, acc} = callback.({key, value}, acc)
    {key, _acc} = recurse(key, acc, callback)
    {value, _acc} = recurse(value, acc, callback)
    {{key, value}, acc}
  end


  def recurse(ast, acc, callback) when is_list(ast) do
    {Enum.map(ast, fn(ast_entry) ->
      ast_entry |> recurse(acc, callback) |> elem(0)
    end), acc}
  end

  def recurse(primitive, acc, callback) do
     callback.(primitive, acc)
  end








  @doc """
  Walk callback for collecting metadata like aliases and imports.
  """
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

  @defs ~w[def defp defmacro defmacrop]a

  @doc """
  Walk callback for collecting metadata like aliases and imports.
  """
  def module_functions({:defmodule, _, [_aliases, args]} = module, _current_functions) do
    contents = case Keyword.get(args, :do, {:__block__, [], []}) do
      {:__block__, _, contents} -> contents
      {defs, _, _} = content when defs in @defs -> [content]
    end
    functions =
      contents
      |> Enum.filter(fn
        {defs, _, _} when defs in @defs -> true
        _ -> false
      end)
      |> Enum.map(fn {_, _, [{name, _, _} | _]} -> name end)

    {module, functions}
  end

  def module_functions({fun, meta, args}, current_functions) do
    meta = if fun in current_functions and
      (!Keyword.get(meta, :alias) && !Keyword.get(meta, :import)) do
      Keyword.put(meta, :allow, true)
    else
      meta
    end

    {{fun, meta, args}, current_functions}
  end

  def module_functions(ast, acc), do: {ast, acc}


  @doc "Helper to check if a function is imported in a given module."
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
