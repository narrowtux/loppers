defmodule When do
  def foo(i) when is_integer(i) do
    i + 3
  end
  def foo(i) do
    case i do
      i when is_binary(i) -> i <> "abc"
      _ -> :error
    end
  end
end
