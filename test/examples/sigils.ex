defmodule Sigils do

  def foo() do
    [
      ~c(foo),
      ~C(foo),

      ~s(foo),
      ~S(foo),

      ~w(foo #{:bar} baz),
      ~W(foo #{bar} baz),

      ~D[2015-01-13],
      ~T[13:00:07],
      ~N[2015-01-13 13:00:07],
      ~U[2015-01-13T13:00:07.123+00:00],

      ~r/abc/,
      ~R(f#{1,3}o),
    ]
  end

end
