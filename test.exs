file = "./test/examples/simple_module.ex"

source = File.read!(file)

source = "quote do\n#{source}\nend"

Code.eval_string(source) |> IO.inspect
