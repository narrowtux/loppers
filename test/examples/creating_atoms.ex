defmodule CreatingAtoms do

  # We try handle the internal erlang.binary_to_atom
  def to_atom(string) do
    :"#{string}"
  end

end
