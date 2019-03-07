defmodule DefPrivate do
  def test do
    _test()
  end

  defp _test do
    :ok
  end
end
