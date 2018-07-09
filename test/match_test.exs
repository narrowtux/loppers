defmodule LoppersTest do
  use ExUnit.Case
  doctest Loppers
  alias Loppers.Match

  test "Kernel functions can be matched" do
    quoted = quote do 1 + 1 end
    assert Match.matches?(quoted, {Kernel, :+})
  end

  test "Imported functions are matched" do
    import String
    quoted = quote do downcase("HELLO") end
    assert Match.matches?(quoted, {String, :downcase})

    # test negative cases
    assert Match.matches?(quoted, {String, :upcase}) == false
    assert Match.matches?(quoted, {MyString, :downcase}) == false
  end

  test "Functions in modules are matched" do
    quoted = quote do String.pad_leading("13 cm", 10, " ") end
    assert Match.matches?(quoted, {String, :pad_leading})

    # test negative cases
    assert Match.matches?(quoted, {String, :upcase}) == false
    assert Match.matches?(quoted, {MyString, :pad_leading}) == false
  end

  test "erlang modules are matched" do
    quoted = quote do :erlang.term_to_binary(:abc) end
    assert Match.matches?(quoted, {:erlang, :term_to_binary})

    # test negative cases
    assert Match.matches?(quoted, {:ets, :term_to_binary}) == false
    assert Match.matches?(quoted, {:erlang, :binary_to_term}) == false
  end

  test "aliased modules are matched" do
    alias Module.Sub.A
    quoted = quote do A.foo(1, 2, 3) end
    assert Match.matches?(quoted, {Module.Sub.A, :foo})

    # test negative cases
    assert Match.matches?(quoted, {Module.Sub.B, :foo}) == false
    assert Match.matches?(quoted, {Module.Sub.A, :foo_bar}) == false
  end

  test "dynamic modules are not allowed" do
    quoted = quote do mod.foo(1) end
    assert Match.matches?(quoted, {Module, :foo}) == false
  end

  test "submodules are recursive allowed" do
    quoted = quote do Module.Child.foo(1) end
    assert Match.matches?(quoted, {Module, :__submodules_all__}) == true

    quoted = quote do Module.Child.Sub.foo(1) end
    assert Match.matches?(quoted, {Module.Child, :__submodules_all__}) == true

    quoted = quote do Module.foo(1) end
    assert Match.matches?(quoted, {Module2, :__submodules_all__}) == false
  end

end
