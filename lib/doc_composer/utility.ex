defmodule DocsComposer.Utility do
  @moduledoc """
  Shared utility function
  """
  def camelize_keys(%{} = map) do
    map
    |> Map.to_list
    |> Enum.map(fn({k, v}) -> {camelize(k), v} end)
    |> Enum.into(%{})
  end

  def camelize(v), do: Inflex.camelize(v, :lower)

  def fields_to_text(map, formatter) when is_function(formatter) do
    map
    |> Map.to_list
    |> Enum.sort_by(fn{k, _} -> k end)
    |> Enum.map(formatter)
    |> Enum.join("\n")
  end
end
