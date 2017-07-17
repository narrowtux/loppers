defmodule Loppers.Validate do
  def validate({defs, _meta, [_fn_head, [{:do, dos}]]} = ast, acc, validator)
    when defs in [:def, :defp, :defmacro, :defmacrop] do
    acc = validator.(ast, acc)
    validate(dos, acc, validator)
  end

  def validate([{:do, dos}], acc, validator) do
    reduce_args(dos, acc, validator)
  end

  def validate({:alias, _meta, _args} = ast, acc, validator) do
    validator.(ast, acc)
  end

  def validate({:import, _meta, _args} = ast, acc, validator) do
    validator.(ast, acc)
  end

  def validate({fun, _meta, args} = ast, acc, validator) do
    acc = validator.(ast, acc)
    acc = validate(fun, acc, validator)
    reduce_args(args, acc, validator)
  end

  def validate({key, value}, acc, validator) do
    acc = validate(key, acc, validator)
    validate(value, acc, validator)
  end

  def validate(list, acc, validator) when is_list(list) do
    reduce_args(list, acc, validator)
  end

  def validate(primitive, acc, _)
    when is_atom(primitive) or
         is_number(primitive) or
         is_binary(primitive) or
         is_integer(primitive) do
    acc
  end

  def reduce_args(nil, acc, _), do: acc
  def reduce_args(args, acc, validator) when is_list(args) do
    Enum.reduce(args, acc, &validate(&1, &2, validator))
  end
  def reduce_args(arg, acc, validator) do
    validate(arg, acc, validator)
  end
end
