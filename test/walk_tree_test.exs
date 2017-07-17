defmodule LoppersTest.Walk do
  use ExUnit.Case
  doctest Loppers
  alias Loppers.{Walk}

  @examples "./test/examples/"
  @whitelist Loppers.module_support() ++ Loppers.special_forms() ++ Loppers.operators()

  test "named_alias.ex" do
    whitelist = @whitelist ++ [
      {String, :downcase},
      {IO, :puts},
      {IO.ANSI, :__all__},
      {Kernel, :<>}
    ]
    test_allow("named_alias.ex", whitelist)
  end

  test "imports.ex" do
    whitelist = @whitelist ++ [
      {Enum, :sum},
      {Kernel, :sigil_w},
      {Kernel, :|>},
      {String, :__all__},
      :map,
    ]
    test_allow("imports.ex", whitelist)
  end

  def test_allow(file, whitelist) do
    file = "#{@examples}#{file}"
    source = File.read!(file)
    {:ok, quoted} = Code.string_to_quoted(source, file: file)

    # add alias info
    {quoted, _acc} = Walk.walk(quoted, {%{}, [{Kernel, []}]}, &Walk.gen_meta/2)

    assert :ok = Loppers.validate_whitelist(quoted, whitelist)
  end
end
