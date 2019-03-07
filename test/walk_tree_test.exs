defmodule LoppersTest.Walk do
  use ExUnit.Case
  doctest Loppers

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

  test "imports.ex blacklisted" do
    blacklist = [
      {String, :to_integer}
    ]

    quoted = get_file("imports.ex")

    assert {:error, [_]} = Loppers.validate(quoted, blacklist: blacklist)

  end

  test "binary_match.ex" do
    whitelist = @whitelist ++ [
      {Enum, :__all__}
    ]

    test_allow("binary_match.ex", whitelist)
  end

  test "import_all_macros.ex" do
    whitelist = @whitelist ++ [
      {Kernel, :__all__}
    ]

    test_allow("import_all_macros.ex", whitelist)
  end

  test "creating_atoms.ex" do
    quoted = get_file("creating_atoms.ex")

    # Blacklisting works
    blacklist = [
      {:erlang, :binary_to_atom}
    ]
    assert {:error, [not_allowed: {{:., _, [:erlang, :binary_to_atom]}, _, _}]} = Loppers.validate(quoted, blacklist: blacklist)

    # Whitelisting works.
    whitelist = @whitelist ++ [
      {Kernel, :__all__},
      {:erlang, :binary_to_atom}
    ]
    test_allow("creating_atoms.ex", whitelist)
  end

  test "submodules.ex" do
    whitelist = @whitelist ++ [
      {ParentModule, :__submodules_all__}, # Allow all functions in all submodules from that module.
    ]
    test_allow("submodules.ex", whitelist)

    whitelist = @whitelist ++ [
      {ParentModule.Submodule2, :__submodules_all__}, # Allow all functions in all submodules from that module.
    ]
    assert {:error,
     [
       not_allowed: {{:., [parent_modules: [:ParentModule], line: 38],
         [
           {:__aliases__, [parent_modules: [:ParentModule], line: 38],
             [:Submodule, :SubSubModule]},
           :lol
         ]}, [parent_modules: [:ParentModule], line: 38], []},
       not_allowed: {{:., [parent_modules: [:ParentModule], line: 38],
         [
           {:__aliases__, [parent_modules: [:ParentModule], line: 38],
             [:Submodule]},
           :question
         ]}, [parent_modules: [:ParentModule], line: 38], []}
     ]} = Loppers.validate(get_file("submodules.ex"), whitelist: whitelist)
  end

  test "when.ex" do
    whitelist = @whitelist

    test_allow("when.ex", whitelist)
  end

  test "defp.ex" do
    whitelist = @whitelist ++ [{Kernel, :defp}]

    test_allow("defp.ex", whitelist)
  end

  test "defdo.ex" do
    whitelist = @whitelist ++ [{Map, :new}]

    test_allow("defdo.ex", whitelist)
  end

  def get_file(file) do
    file = "#{@examples}#{file}"
    source = File.read!(file)
    {:ok, quoted} = Code.string_to_quoted(source, file: file)
    quoted
  end

  def test_allow(file, whitelist) do
    quoted = get_file(file)

    assert :ok = Loppers.validate(quoted, whitelist: whitelist)
  end
end
