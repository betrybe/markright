defmodule Markright.Test do
  use ExUnit.Case
  doctest Markright

  @input_text ~S"""
  **Опыт использования пространств имён в клиентском XHTML**

  _Текст Ростислава Чебыкина._

  > Я вам посылку принёс. Только я вам её не отдам, потому что у вас документов нету.
  > —⇓Почтальон Печкин⇓

  Мы вместе с Денисом Лесновым разрабатываем аудиопроигрыватель для сайта,
  о котором уже рассказывали здесь в 2015 году.

  ```elixir
  defmodule Xml.Namespaces do
    @var 42
    def method(param \\ 3.14) do
      if is_nil(param), do: @var, else: @var * param
    end
  ```

  Сейчас на подходе обновлённая версия, которая умеет играть
  не только отдельные треки, но и целые плейлисты.
  """

  @output_text ~s"""
  <p>
  \t<b>Опыт использования пространств имён в клиентском XHTML</b>
  </p>
  <p>
  \t<em>Текст Ростислава Чебыкина.</em>\n</p>
  <blockquote> Я вам посылку принёс. Только я вам её не отдам, потому что у вас документов нету.</blockquote>
  <blockquote>
  \t —
  \t<span>Почтальон Печкин</span>
  </blockquote>
  <p>Мы вместе с Денисом Лесновым разрабатываем аудиопроигрыватель для сайта,
  о котором уже рассказывали здесь в 2015 году.</p>
  <pre>
  \t<code lang=\"elixir\">defmodule Xml.Namespaces do
    @var 42
    def method(param \\\\ 3.14) do
      if is_nil(param), do: @var, else: @var * param
    end</code>
  </pre>
  <p>Сейчас на подходе обновлённая версия, которая умеет играть
  не только отдельные треки, но и целые плейлисты.</p>
  """

  test "generates XML from parsed markright" do
    assert (@input_text
            |> Markright.to_ast
            |> IO.inspect
            |> XmlBuilder.generate) == String.trim(@output_text)
  end
end
