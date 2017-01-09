IO.puts "☆☆☆ SOME TESTS ARE SKIPPED ☆☆☆"
ExUnit.start(exclude: :skip)

defmodule Markright.Tester do
  defmacro __using__(_opts) do
    quote do
      defp purge(list) when is_list(list) do
        Enum.each list, &purge/1
      end

      defp purge(module) when is_atom(module) do
        :code.delete module
        :code.purge module
      end
    end
  end
end
