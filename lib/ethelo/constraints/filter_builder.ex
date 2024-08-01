defmodule EtheloApi.Constraints.FilterBuilder do
  @moduledoc """
  Used to suggest possible filters based on details configured on a decision.
  """

  require Timex
  alias EtheloApi.Structure.OptionFilter
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure
  alias EtheloApi.Constraints.SuggestionMatcher
  alias EtheloApi.Constraints.FilterData

  import EtheloApi.Helpers.ExportHelper

  @doc """
  Populates missing filters

  ## Examples

      iex> ensure_all_valid_filters(decision)
      {:ok, nil}

      iex> ensure_all_valid_filters(decision)
      {:error, nil}

  """
  def ensure_all_valid_filters(decision_id) when is_integer(decision_id) do
    Structure.get_decision(decision_id) |> ensure_all_valid_filters
  end

  def ensure_all_valid_filters(%Decision{} = decision) do
    # prevent order of operation errors on new decisions
    EtheloApi.Structure.Queries.OptionFilter.ensure_all_options_filter(decision)

    decision |> FilterData.initialize_all() |> ensure_filters()
    {:ok, true}
  end

  def ensure_filters(%FilterData{} = filter_data) do
    filter_data |> list_filters |> create_and_update()
  end

  def missing_filters(%FilterData{} = filter_data) do
    list_filters(filter_data) |> Map.get(:missing_filters)
  end

  def list_filters(%FilterData{} = filter_data) do
    possible_filters = possible_filters(filter_data)

    {missing, existing} =
      Enum.split_with(possible_filters, fn possible ->
        Map.get(possible, :id) |> is_nil()
      end)

    filter_data = Map.put(filter_data, :missing_filters, missing)
    filter_data = Map.put(filter_data, :changed_filters, changed_filters(existing, filter_data))
    filter_data
  end

  def create_and_update(%FilterData{} = filter_data) do
    Map.put(filter_data, :created_filters, create_filters(filter_data))
    Map.put(filter_data, :updated_filters, update_changed_filters(filter_data))
    filter_data
  end

  def create_filters(%{missing_filters: nil}), do: []
  def create_filters(%{missing_filters: []}), do: []

  def create_filters(%{missing_filters: missing, decision: decision}) when is_list(missing) do
    missing
    |> Enum.map(fn struct ->
      new_value = Map.get(struct, :match_value) || ""
      Map.put(struct, :match_value, new_value)
    end)
    |> Enum.map(&Map.from_struct/1)
    |> Enum.map(&Structure.create_option_filter(decision, &1, false))
    |> Enum.map(&elem(&1, 1))
  end

  def create_filters(_), do: []

  def changed_filters(existing_filters, filter_data) do
    option_filters_by_id = filter_data.option_filters |> group_by_id()

    updates =
      existing_filters
      |> Enum.map(fn struct ->
        new_value = Map.get(struct, :match_value, "")
        Map.put(struct, :match_value, new_value)
      end)

    updates
    |> Enum.map(fn updated ->
      existing = Map.get(option_filters_by_id, updated.id)
      attrs = Map.from_struct(updated) |> clean_map |> Map.delete(:id)
      {existing.id, get_changes(existing, attrs)}
    end)
    |> Enum.reject(fn
      {_, []} -> true
      _ -> false
    end)
  end

  def get_changes(existing, calculated) do
    field_list = [
      :slug,
      :title,
      :match_mode,
      :match_value,
      :option_detail_id,
      :option_category_id
    ]

    existing = Map.from_struct(existing) |> Map.take(field_list)
    changes = if existing == calculated, do: [], else: calculated
    changes
  end

  def update_changed_filters(%{changed_filters: nil}), do: []
  def update_changed_filters(%{changed_filters: []}), do: []

  def update_changed_filters(%{
        changed_filters: changed_filters,
        option_filters_by_id: option_filters_by_id
      }) do
    changed_filters
    |> Enum.map(fn {id, changes} ->
      existing = Map.get(option_filters_by_id, id)
      Structure.update_option_filter(existing, changes, false)
    end)
  end

  defp add_ids(missing, filter_data) do
    SuggestionMatcher.add_existing_ids(missing, filter_data.option_filters, &matches?/2)
  end

  defp matches?(missing, filter) do
    filter.option_detail_id == missing.option_detail_id and
      filter.option_category_id == missing.option_category_id and
      filter.match_mode == missing.match_mode and
      to_string(filter.match_value) == to_string(missing.match_value)
  end

  def possible_filters(%FilterData{} = filter_data) do
    oc_filters = convert_to_oc_filters(filter_data)

    od_filters = convert_to_od_filters(filter_data)

    list = oc_filters ++ od_filters

    list
    |> Enum.uniq()
    |> add_ids(filter_data)
  end

  def convert_to_oc_filters(%{option_category_data: oc_data} = filter_data)
      when is_list(oc_data) do
    oc_data
    |> Enum.flat_map(fn option_category ->
      [
        %OptionFilter{
          match_mode: "in_category",
          title: option_category.title,
          option_category_id: option_category.id,
          decision_id: filter_data.decision.id
        }
      ]
    end)
  end

  def convert_to_oc_filters(_), do: []

  def convert_to_od_filters(%{option_detail_data: od_data} = filter_data)
      when is_list(od_data) do

    od_data
    |> Enum.flat_map(fn option_detail ->
      [
        build_detail_filter("true", "Yes", option_detail, filter_data.decision.id),
        build_detail_filter("false", "No", option_detail, filter_data.decision.id)
      ]
    end)
  end

  def convert_to_od_filters(_), do: []

  defp build_detail_filter(value, title_value, option_detail, decision_id) do
    title = ~s(#{option_detail.title} #{title_value})

    %OptionFilter{
      match_value: value,
      match_mode: "equals",
      title: title,
      option_detail_id: option_detail.id,
      decision_id: decision_id
    }
  end
end
