defmodule BinaryMatch do
  def parse_all(events) do
    Enum.flat_map(events, fn {data, meta} -> parse(data, meta) end)
  end

  def parse(data, meta) do
    << temperature :: integer-size(2), humidity :: integer-size(2) >> = data
    %{
      temperature: temperature / 255 * 23,
      humidity: humidity / 255 * 100
    }
  end
end
