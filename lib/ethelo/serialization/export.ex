defmodule EtheloApi.Serialization.Export do

  alias EtheloApi.Repo

  def export(%{__struct__: struct} = instance, options \\ []) do
    to_export = Keyword.get(options, :to_export, instance.__struct__.__schema__(:associations))
    case instance |> Repo.preload(to_export) |> sanitize do
      {:ok, sanitized} ->
        name = struct |> Module.split |> List.last |> String.downcase
        %{name => sanitized} |> Poison.encode(pretty: Keyword.get(options, :pretty, false))

      error ->
        error
    end
  end

  defp sanitize(%Ecto.Association.NotLoaded{}), do: :drop
  defp sanitize(%Date{}), do: :ok
  defp sanitize(%Time{}), do: :ok
  defp sanitize(%DateTime{}), do: :ok
  defp sanitize(%Decimal{} = value), do: {:ok, Decimal.to_float(value)}
  defp sanitize(%{__struct__: _} = instance) do
    {:ok, instance
      |> Map.from_struct
      |> Map.drop([:__meta__])
      |> Enum.reduce(%{}, fn({field, value}, acc) ->
        case sanitize(value) do
          {:ok, sanitized} -> Map.put(acc, field, sanitized)
          :ok -> Map.put(acc, field, value)
          _ -> acc
        end
      end)
      |> Map.new}
  end
  defp sanitize(list) when is_list(list) do
    {:ok, list |> Enum.reduce([], fn(value, acc) ->
      case sanitize(value) do
        {:ok, sanitized} -> acc ++ [sanitized]
        :ok -> acc ++ [value]
        _ -> acc
      end
    end)}
  end
  defp sanitize(_), do: :ok
end
