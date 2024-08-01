defmodule DocsComposer.MarkdownBuilder do
  @moduledoc """
  Tools for generating markdown versions of examples
  """
  import DocsComposer.Utility

  def schema_examples(%{} = examples) do
    examples
    |> Enum.to_list
    |> Enum.map(&format_example/1)
    |> Enum.join("\n")
  end

  def format_example({label, values}) do
    values
    |> fields_to_markdown_list
    |> (&"### #{label}\n#{&1}").()
  end

  defp fields_to_markdown_list(map) do
    map |> fields_to_text(fn({k, v}) -> "- #{k}: #{v}" end)
  end

end
