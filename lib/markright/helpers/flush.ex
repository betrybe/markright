defmodule Markright.Helpers.Flush do
  @moduledoc ~S"""
  Generic handler for flushes. Use as:

  ```elixir
  defmodule Markright.Parsers.Maillink do
    use Markright.Helpers.Flush tag: :br

    # the below code is redundant, this functions is generated by `use`,
    #   the snippet is here to provide a how-to, since `to_ast/3` is overridable
    def to_ast(input, fun \\ nil, opts \\ %{}) \
      when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts),
    do: astify(input, fun)
  end
  ```
  """
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts, module: __MODULE__] do

      @tag opts[:tag] || Markright.Utils.atomic_module_name(__MODULE__)
      case opts[:lead_and_handler] || Markright.Syntax.get(Markright.Utils.atomic_module_name(module), opts[:lead] || @tag) do
        {lead, handler} ->
          @lead lead
          @handler handler
        other -> raise Markright.Errors.UnexpectedFeature, value: other, expected: "{lead, handler} tuple"
      end

      use Markright.Helpers.Magnet, tag: @tag, attr: :empty, continuation: :empty, value: :empty
    end
  end
end
