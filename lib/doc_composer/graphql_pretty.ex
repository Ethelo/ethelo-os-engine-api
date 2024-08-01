defmodule DocsComposer.GraphQLPretty do
  @moduledoc """
  Naive parser that indents a string with tabs where there are braces
  """

  def to_pretty_string(content) do
    content
    |> split
    |> Enum.map(&String.trim/1)
    |> Enum.reduce(%{tab_count: 0, content: ""}, &build_string/2)
    |> Map.get(:content)
    |> String.trim()
  end

  defp build_string("(" = brace, map), do: open_brace(map, brace)
  defp build_string("{" = brace, map), do: open_brace(map, brace)
  defp build_string("[" = brace, map), do: open_brace(map, brace)
  defp build_string("]" = brace, map), do: close_brace(map, brace)
  defp build_string(")" = brace, map), do: close_brace(map, brace)
  defp build_string("}" = brace, map), do: close_brace(map, brace)
  defp build_string("", map), do: map
  defp build_string(content, map) do
    add_on_new_line(map, String.trim(content))
  end

  defp open_brace(map, brace) do
    map |> add_on_same_line(brace) |> update_tab_count(1)
  end

  defp close_brace(map, brace) do
    map |> update_tab_count(-1) |> add_on_new_line(brace)
  end

  defp add_on_new_line(map, content) do
    tabs = String.duplicate("  ", map.tab_count)
    content = map.content <> tabs <> content <> "\n"
    %{map | content: content}
  end

  defp add_on_same_line(map, to_add) do
    content = String.trim(map.content, "\n") <> " " <> to_add <> "\n"
    Map.put(map, :content, content)
  end

  defp update_tab_count(map, count) do
    tab_count = map.tab_count + count
    tab_count = if tab_count <= 0, do: 0, else: tab_count
    Map.put(map, :tab_count, tab_count)
  end

  defp split(content) do
    braces = Regex.escape("[]{}()\n")
    {:ok, regex} = Regex.compile("[#{braces}]")
    Regex.split(regex, content, include_captures: true, trim: true)
  end

end
