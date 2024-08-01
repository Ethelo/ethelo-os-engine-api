defmodule DocsComposer.MarkdownBuilder do
  @moduledoc """
  Tools for generating markdown versions of examples
  """

  @spec schema_examples(map()) :: String.t()
  def schema_examples(%{} = examples) do
    examples
    |> Enum.to_list()
    |> Enum.map_join("\n", &format_example/1)
  end

  @spec format_example({atom(), map()}) :: String.t()
  def format_example({label, values}) do
    values
    |> fields_to_markdown_list
    |> (&"### #{label}\n#{&1}").()
  end

  defp fields_to_markdown_list(map) do
    map
    |> Map.to_list()
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.map_join("\n", fn {k, v} -> "- #{k}: #{v}" end)
  end
end
