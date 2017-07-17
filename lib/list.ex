defmodule Loppers.List do
  def in_list?(ast, list) do
    Enum.any?(list, &Loppers.Match.matches?(ast, &1))
  end
end
