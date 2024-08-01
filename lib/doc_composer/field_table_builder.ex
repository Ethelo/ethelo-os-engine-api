defmodule DocsComposer.FieldTableBuilder do
  @moduledoc false

  @field_table_start """

  |Name|Type|Info|Validation|
  |----|----|----|----------|
  """

  @doc """
  Converts a supplied list of fields into a markdown table.
  """
  def to_markdown(fields) when is_list(fields) do
    fields
    |> Enum.sort_by(fn(field) -> field.name end)
    |> Enum.map(&field_to_markdown_table_line/1)
    |> Enum.join("\n")
    |> (&(@field_table_start <> &1 <> "\n")).()
  end

  def to_markdown(_) do
    raise ArgumentError, message: "field list must be a list"
  end

  # default values for each allowed field
  defp default_values() do
    %{name: nil, info: nil, type: nil, required: nil, automatic: nil, immutable: nil, validation: nil}
  end

  # Append automatic, immutable to info
  defp update_info(field) do
    info = field.info |> maybe_add_automatic(field) |> maybe_add_immutable(field)
    %{field | info: info}
  end

  # Append required to validation.
  defp update_validation(field) do
    validation = field.validation |> maybe_add_required(field)
    %{field | validation: validation}
  end

  defp maybe_add(content, nil, _), do: content
  defp maybe_add(content, false, _), do: content
  defp maybe_add(content, true, value), do: add_content(content, value)
  defp maybe_add(content, value, _), do: add_content(content, value)

  defp add_content(content, to_add), do: "#{content} #{to_add}" |> String.trim

  defp maybe_add_required(content, %{required: required}), do: maybe_add(content, required, "Required.")
  defp maybe_add_automatic(content, %{automatic: automatic}), do: maybe_add(content, automatic, "Updated Automatically.")
  defp maybe_add_immutable(content, %{immutable: immutable}), do: maybe_add(content, immutable, "Immutable.")

  defp field_to_markdown_table_line(%{} = field) do
    default_values()
    |> Map.merge(field)
    |> update_info
    |> update_validation
    |> Map.take([:name, :info, :type, :validation])
    |> Map.to_list
    |> Enum.sort_by(&sort_for_schema_fields/1)
    |> Enum.map(&field_to_cell/1)
    |> Enum.join(" | ")
    |> (&"| #{&1} |").()
  end

  @sort_order %{name: 1, type: 2, info: 3, validation: 4}
  defp sort_for_schema_fields({k, _v}) do
    Map.get(@sort_order, k) || 10
  end

  defp field_to_cell({_k, v}), do: to_cell_display(v)
  defp to_cell_display(true), do: "Yes"
  defp to_cell_display(false), do: "No"
  defp to_cell_display(nil), do: ""
  defp to_cell_display(other), do: "#{other}"

end
