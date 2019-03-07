defmodule DefDo do
  def foo(), do: :ok
  def profile_name(), do: :zri_device

  def bar() do
    foo()
  end

  def baz() do
    vifs = 1
    [{profile_name(), vifs}]
    [{vifs, profile_name()}]
  end

  def preloads() do
    [device: [profile_data: [profile_name()]]]
  end
end
