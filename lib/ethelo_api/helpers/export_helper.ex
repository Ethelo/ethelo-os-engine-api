defmodule EtheloApi.Helpers.ExportHelper do
  @moduledoc """
  Tools to export Decision data as generic maps
  """
  @spec group_by_key(list(map()), atom()) :: map()
  def group_by_key(list, key) do
    list |> Enum.group_by(&Map.get(&1, key))
  end

  def group_by_slug(list), do: group_by_key(list, :slug) |> delist_group()
  def group_by_id(list), do: group_by_key(list, :id) |> delist_group()
  def group_by_option_detail(list), do: group_by_key(list, :option_detail_id)
  def group_by_option(list), do: group_by_key(list, :option_id)
  def group_by_option_category(list), do: group_by_key(list, :option_category_id)
  def group_by_participant(list), do: group_by_key(list, :participant_id)
  def group_by_criteria(list), do: group_by_key(list, :criteria_id)

  def delist_group(list) do
    list
    |> Enum.map(fn
      {k, [v]} -> {k, v}
      {k, v} -> {k, v}
    end)
    |> Map.new()
  end

  @spec to_maps(list(struct() | map())) :: list(map())
  @doc """
  Convert a list of structs to maps
  """
  def to_maps(list) when is_list(list) do
    list |> Enum.map(&clean_map/1)
  end

  def to_maps(_), do: []

  def sort_by_slug(list) do
    list |> Enum.sort_by(fn map -> map.slug end)
  end

  @spec clean_map(struct() | map()) :: map()
  @doc """
  Convert a single struct / ecto schema to a simple map
  with no meta data
  """
  def clean_map(%_{} = struct) do
    struct |> Map.from_struct() |> clean_map
  end

  def clean_map(%{} = map) do
    invalid_fields =
      map
      |> Enum.map(fn
        {_, %Decimal{}} -> nil
        {k, %Ecto.Association.NotLoaded{}} -> k
        {k, v} when is_list(v) -> k
        {k, v} when is_map(v) -> k
        {k, _} -> if String.starts_with?("#{k}", "__"), do: k, else: nil
      end)
      |> Enum.reject(&is_nil(&1))

    Map.drop(map, invalid_fields)
  end

  def filter_enabled(list, true) do
    Enum.filter(list, &Map.get(&1, :enabled, true))
  end

  def filter_enabled(list, _), do: list

  def filter_deleted(list, true) do
    Enum.filter(list, &(!Map.get(&1, :deleted, false)))
  end

  def filter_deleted(list, _), do: list

  def extract_option_detail_values(options) do
    Enum.flat_map(options, fn option -> option.option_detail_values |> to_maps() end)
  end
end
