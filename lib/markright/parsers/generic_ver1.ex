defmodule Markright.Parsers.GenericVer1 do
  @behaviour Markright.Parser

  @max_lookahead Markright.Syntax.lookahead
  @max_indent    Markright.Syntax.indent

  require Logger
  use Markright.Buffer
  import Markright.Utils, only: [leavify: 1, deleavify: 1]

  def to_ast(input, fun \\ nil, opts \\ %{}, acc \\ Buf.empty())
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    ast = astify(input, fun, %{}, acc)
    case opts[:only] do
      :ast -> ast
      _    -> {ast, ""}
    end
  end

  ##############################################################################

  @spec callback_through(Tuple.t, Function.t, Buf.t | String.t) :: Tuple.t
  defp callback_through(ast, fun, rest)

  defp callback_through(ast, nil, _rest), do: ast
  defp callback_through(ast, fun, rest) when is_function(fun, 1) do
    fun.({ast, rest})
    callback_through(ast, nil, rest)
  end
  defp callback_through(ast, fun, rest) when is_function(fun, 2) do
    fun.(ast, rest)
    callback_through(ast, nil, rest)
  end

  ##############################################################################

  @spec astify(String.t, Function.t, List.t, Buf.t) :: any
  defp astify(part, fun, opts, acc)

  ##############################################################################
  ##  CODE BLOCKS

  # defp astify(<<"```" :: binary, rest :: binary>>, fun, opts, acc) when is_empty_buffer(acc) do
  #   with {code_ast, tail} <- Markright.Parsers.Code.to_ast(rest, fun, opts) do
  #     leavify({
  #       callback_through(code_ast, fun, acc),
  #       astify(tail, fun, opts, acc)
  #     })
  #   end
  # end

  ##############################################################################
  ##  Last in BLOCKS

#  defp astify(input, fun, opts, acc) when is_binary(input) and is_empty_buffer(acc) do
#    callback_through({:p, opts, astify(input, fun, opts, Buf.unshift(acc, {:p, %{}}))}, fun, acc)
#  end

  ##############################################################################
  ##############################################################################

  defp astify(<<
                "\n\n" :: binary,
                rest :: binary
              >>, fun, opts, acc) do
    Logger.error "★5.6: “#{rest}”"
    with {ast, tail} <- Markright.Parsers.Block.to_ast(rest, fun, opts, Buf.empty()) do
      Logger.info "★5.3: #{inspect({ast, tail})}"
      [callback_through(ast, fun, acc)] ++
      case tail do
        s when is_binary(s) -> deleavify(s)
        astified when is_list(astified) ->
          {ready, [{tbd, tail}]} = Enum.split(astified, -1)
          Logger.info "★5.4: #{inspect({ready, [{tbd, tail}]})}"
          [
            ready,
            astify(tbd, fun, opts, tail)
          ]
      end
      |> Enum.map(&deleavify/1)
      |> Enum.reduce([], &(&2 ++ &1))
    end
  end

  Enum.each(0..@max_lookahead-1, fn i ->
    defp astify(<<
                  plain :: binary-size(unquote(i)),
                  "\n\n" :: binary,
                  rest :: binary
                >>, fun, opts, acc) do
      Logger.error "★5.5: #{inspect({plain, rest})}"
      {astify(plain, fun, opts, acc), Markright.Parsers.Generic.to_ast("\n\n" <> rest, fun, opts, Buf.empty())}
    end

    Enum.each(Markright.Syntax.shields(), fn shield ->
      defp astify(<<
                    plain :: binary-size(unquote(i)),
                    unquote(shield) :: binary,
                    next :: binary-size(1),
                    rest :: binary
                  >>, fun, opts, acc) do
        astify(rest, fun, opts, Buf.append(acc, plain <> next))
      end
    end)

    Enum.each(0..@max_indent-1, fn indent ->
      indent = String.duplicate(" ", indent)
      Enum.each(Markright.Syntax.leads(), fn {tag, delimiter} ->
        defp astify(<<
                      plain :: binary-size(unquote(i)),
                      "\n" :: binary,
                      unquote(indent) :: binary,
                      unquote(delimiter) :: binary,
                      rest :: binary
                    >>, fun, opts, acc) do
          with mod <- Markright.Utils.to_module(unquote(tag)),
              {code_ast, tail} <- apply(mod, :to_ast, [rest, fun, opts, Buf.empty()]) do
            ast = if mod == Markright.Parsers.Generic, do: {unquote(tag), opts, code_ast}, else: code_ast
            [
              astify(plain, fun, opts, acc),
              callback_through(ast, fun, acc),
              astify(tail, fun, opts, Buf.cleanup(acc))
            ]
            |> Enum.map(&deleavify/1)
            |> Enum.reduce([], &(&2 ++ &1))
          end
        end
      end)
    end)

    Enum.each(Markright.Syntax.customs(), fn {tag, g} ->
      defp astify(<<plain :: binary-size(unquote(i)), unquote(g) :: binary, rest :: binary>>, fun, opts, acc) do
        with mod <- Markright.Utils.to_module(unquote(tag)),
            {code_ast, tail} <- apply(mod, :to_ast, [rest, fun, opts, Buf.empty()]) do
          ast = if mod == Markright.Parsers.Generic, do: {unquote(tag), opts, code_ast}, else: code_ast
          [
            astify(plain, fun, opts, acc),
            callback_through(ast, fun, acc),
            astify(tail, fun, opts, Buf.cleanup(acc))
          ]
          |> Enum.map(&deleavify/1)
          |> Enum.reduce([], &(&2 ++ &1))
        end
      end
    end)

    Enum.each(Markright.Syntax.grips(), fn {t, g} ->
      defp astify(<<plain :: binary-size(unquote(i)), unquote(g) :: binary, rest :: binary>>, fun, opts, acc) do
        case Buf.shift(acc) do
          {{unquote(t), opts}, tail} ->
            [astify(plain, fun, opts, acc), {rest, Buf.cleanup(tail)}]

          _ ->
            [astify(plain, fun, opts, acc)] ++
            case astify(rest, fun, opts, Buf.unshift_and_cleanup(acc, {unquote(t), opts})) do
              s when is_binary(s) -> deleavify(s)
              astified when is_list(astified) ->
                {ready, [{tbd, tail}]} = Enum.split(astified, -1)
                [
                  callback_through({unquote(t), opts, leavify(ready)}, fun, tail),
                  astify(tbd, fun, opts, tail)
                ]
            end
            |> Enum.map(&deleavify/1)
            |> Enum.reduce([], &(&2 ++ &1))
        end
      end
    end)
  end)

  defp astify(<<plain :: binary-size(@max_lookahead), rest :: binary>>, fun, opts, acc) do
    Logger.debug "★3: #{inspect({plain, rest})}"
    astify(rest, fun, opts, Buf.append(acc, plain))
  end

  ##############################################################################
  ### MUST BE LAST
  ##############################################################################

  defp astify(unmatched, _fun, _opts, acc) when is_binary(unmatched) do
    Logger.debug "★4: #{inspect(unmatched)}"
    Buf.append(acc, unmatched).buffer
  end

end
