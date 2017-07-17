defmodule ImportTestModule do
  def fun_function() do
    import Enum, only: [sum: 1, map: 2]

    ~w[1 2 3]
    |> map(&String.to_integer/1)
    |> sum
  end
end
