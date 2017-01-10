defmodule Markright.Parsers.Blockquote do
  @moduledoc ~S"""
  Parses the input for the blockquote block.

  ## Examples

      iex> input = "Hello
      ...> — world!
      ...>
      ...> Other text.
      ...> "
      iex> Markright.Parsers.Blockquote.to_ast(input)
      %Markright.Continuation{ast: {:blockquote, %{},
             "Hello\n — world!"}, tail: " Other text.\n "}
  """

  ##############################################################################

  @behaviour Markright.Parser

  ##############################################################################

  @max_indent Markright.Syntax.indent

  ##############################################################################

  require Logger

  ##############################################################################

  use Markright.Buffer
  use Markright.Continuation

  ##############################################################################

  def to_ast(input, fun \\ nil, opts \\ %{})
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    with %C{ast: ast, tail: tail} <- astify(input, fun, opts),
         %C{ast: block, tail: ""} <- Markright.Parsers.Generic.to_ast(ast) do
      %C{ast: {:blockquote, opts, block}, tail: tail}
    end
    |> C.callback(fun)
  end

  ##############################################################################

  @spec astify(String.t, Function.t, List.t, Buf.t) :: Markright.Continuation.t
  defp astify(part, fun, opts, acc \\ Buf.empty())

  ##############################################################################

  defp astify(<<"\n\n" :: binary, rest :: binary>>, _fun, _opts, acc) do
    %C{ast: acc.buffer, tail: rest}
  end

  Enum.each(0..@max_indent-1, fn i ->
    indent = String.duplicate(" ", i)
    defp astify(<<
                  "\n" :: binary,
                  unquote(indent) :: binary,
                  unquote(Markright.Syntax.blocks()[:blockquote]) :: binary,
                  rest :: binary
                >>, fun, opts, acc) do
      astify(" " <> rest, fun, opts, acc)
    end
  end)

  defp astify(<<letter :: binary-size(1), rest :: binary>>, fun, opts, acc),
    do: astify(rest, fun, opts, Buf.append(acc, letter))

  defp astify("", _fun, _opts, acc),
    do: %C{ast: acc.buffer, tail: ""}

  ##############################################################################
end