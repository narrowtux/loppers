defmodule ParentModule do

  defmodule Submodule do

    def test() do
      true
    end

    defmodule SubSubModule do
      def lol() do
        1337
      end
    end

    def question() do
      42
    end
  end

  defmodule Submodule2 do

    def test() do
      false
    end

    defmodule SubSubModule2 do
      def lol() do
        13372
      end
    end

    def question() do
      422
    end
  end

  def ask(string) do
    Submodule.question() + Submodule.SubSubModule.lol()
  end

end
