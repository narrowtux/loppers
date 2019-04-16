defmodule Case do
  # make sure special forms has ->
  def speak(animal) do
    case animal do
      :cat -> 
        "meow"
      :dog -> 
        "arf"
    end
  end
end
