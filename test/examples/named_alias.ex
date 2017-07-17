defmodule ASimpleModule do
  alias String, as: S
  alias IO.ANSI

  def to_lowercase(string) do
    S.downcase(string)
  end

  def print_something do
    IO.puts ANSI.red <> "Hello World"
  end
end
