defmodule Demo do
  @moduledoc """
  Documentation for `Demo`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Demo.hello()
      Hello World!
      :ok

  """
  def hello do
    html = """
    <!doctype html>
    <html>
    <body>
      <section id="content">
        <p class="headline">Hello World!</p>
        <span class="headline">Enables search using CSS selectors</span>
        <a href="https://github.com/philss/floki">Github page</a>
        <span data-model="user">philss</span>
      </section>
      <a href="https://hex.pm/packages/floki">Hex package</a>
    </body>
    </html>
    """

    {:ok, document} = Floki.parse_document(html)
    [{"p", [{"class", "headline"}], [header]}] = Floki.find(document, "p.headline")

    IO.puts(header)
  end
end
