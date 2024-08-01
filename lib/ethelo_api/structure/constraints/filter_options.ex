defmodule EtheloApi.Structure.FilterOptions do
  @moduledoc """
  Tools for building queries from filter configs.

  This tool loads all Options and OptionDetailValues and filters them,
  as values are all stored as strings and need to be cast before comparision.

  Caching to be added as necessary in future.
  """

  import Ecto.Query, warn: false
  alias EtheloApi.Repo
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Option
  alias EtheloApi.Structure.OptionFilter
  alias EtheloApi.Structure.OptionDetailValue
  import EtheloApi.Structure.ValueParser
  import EtheloApi.Helpers.ExportHelper

  @doc """
  Returns a list of matching Option ids for a single OptionFilters
  Use an optional second argument to only include enabled Options.

  ## Examples

      iex> option_ids_matching_filter(filter, decision_id)
      [1,45]

      iex> option_ids_matching_filter(filter, decision_id, true)
      [1]

  """
  def option_ids_matching_filter(
        %OptionFilter{id: id, decision_id: decision_id} = filter,
        enabled_only \\ false
      ) do
    list =
      [filter]
      |> option_ids_matching_filters(decision_id, enabled_only)
      |> get_in([:ids, id])

    list || []
  end

  @doc """
  Returns the list of matching Option ids for a list of OptionFilters in a Decision.
  Use an optional third argument to only include enabled Options.

  ## Examples

      iex> option_ids_matching_filters([1,3,4], 1)
      %{1: [23, 40], 3: [32]}

      iex> option_ids_matching_filters([1,3,4],1,  true)
      %{1: [40], 3: [32]}

  """
  def option_ids_matching_filters(filter_list, decision_id, enabled_only \\ false)
  def option_ids_matching_filters([], _, _), do: %{slugs: %{}, ids: %{}}

  def option_ids_matching_filters(filter_list, decision_id, enabled_only)
      when is_list(filter_list) do
    options_by_category =
      load_options(decision_id, enabled_only)
      |> options_by_category_and_all()

    all_options_index = option_ids_matching_all_options_filter(filter_list, options_by_category)

    category_index = option_ids_matching_category_filters(filter_list, options_by_category)

    detail_index = option_ids_matching_detail_filters(filter_list, decision_id, enabled_only)

    all_options_index |> merge_indexes(category_index) |> merge_indexes(detail_index)
  end

  def option_ids_matching_filter_data(%{options: _, option_filters: _} = filter_data) do
    options_by_category = options_by_category_and_all(filter_data.options)

    all_options_index =
      option_ids_matching_all_options_filter(filter_data.option_filters, options_by_category)

    category_index =
      option_ids_matching_category_filters(filter_data.option_filters, options_by_category)

    detail_index = option_ids_matching_detail_filters(filter_data)

    all_options_index |> merge_indexes(category_index) |> merge_indexes(detail_index)
  end

  defp merge_indexes(%{slugs: slugs1, ids: ids1}, %{slugs: slugs2, ids: ids2}) do
    %{
      slugs: Map.merge(slugs1, slugs2),
      ids: Map.merge(ids1, ids2)
    }
  end

  defp merge_indexes(%{slugs: _, ids: _} = index, %{}), do: index
  defp merge_indexes(%{}, %{slugs: _, ids: _} = index), do: index
  defp merge_indexes(%{}, %{}), do: %{slugs: %{}, ids: %{}}

  defp build_index_map(%{slugs: _, ids: _} = base, %{id: id, slug: slug}, list) do
    base
    |> put_in([:ids, id], Enum.sort(list))
    |> put_in([:slugs, slug], Enum.sort(list))
  end

  defp build_index_map(base, %{id: _, slug: _} = filter, list) do
    base
    |> Map.put(:ids, %{})
    |> Map.put(:slugs, %{})
    |> build_index_map(filter, Enum.sort(list))
  end

  defp build_index_map(base, _, _), do: base

  def option_ids_matching_all_options_filter([], _), do: %{}
  def option_ids_matching_all_options_filter(nil, _), do: %{}

  def option_ids_matching_all_options_filter(filter_list, category_index) do
    filter =
      filter_list
      |> Enum.find(fn filter -> Map.get(filter, :match_mode) == "all_options" end)

    build_index_map(%{}, filter, Map.get(category_index, :all, []))
  end

  def option_ids_matching_category_filters(filter_list, options_by_category)
  def option_ids_matching_category_filters([], _), do: %{}
  def option_ids_matching_category_filters(nil, _), do: %{}

  def option_ids_matching_category_filters(filter_list, options_by_category) do
    filter_list = Enum.filter(filter_list, &Map.get(&1, :option_category_id, false))

    filter_list
    |> Enum.reduce(%{}, fn filter, memo ->
      option_ids = option_ids_for_category_filter(options_by_category, filter)
      build_index_map(memo, filter, option_ids)
    end)
  end

  def option_ids_for_category_filter(
        options_by_category,
        %{match_mode: "in_category"} = filter
      ) do
    Map.get(options_by_category, filter.option_category_id, [])
  end

  def option_ids_for_category_filter(
        options_by_category,
        %{match_mode: "not_in_category"} = filter
      ) do
    all_list = Map.get(options_by_category, :all, [])
    category_list = Map.get(options_by_category, filter.option_category_id, [])
    all_list -- category_list
  end

  def option_ids_for_category_filter(_, _), do: []

  def option_ids_matching_detail_filters(%{option_filters: []}), do: %{}

  def option_ids_matching_detail_filters(%{option_filters: _, option_details: _} = filter_data) do
    filter_list =
      filter_data.option_filters
      |> Enum.filter(&Map.get(&1, :option_detail_id, false))

    detail_list = filter_data.option_details |> group_by_id()

    odv_list = filter_data.option_detail_values |> group_by_option_detail()

    build_option_detail_filter_index(filter_list, detail_list, odv_list)
  end

  def option_ids_matching_detail_filters(filter_list, decision_id, enabled_only \\ false)
  def option_ids_matching_detail_filters([], _, _), do: %{}

  def option_ids_matching_detail_filters(filter_list, decision_id, enabled_only) do
    detail_list =
      Structure.list_option_details(decision_id, %{}, [:id, :slug, :format])
      |> group_by_id()

    filter_list =
      filter_list
      |> Enum.filter(&Map.get(&1, :option_detail_id, false))

    odv_list =
      filter_list |> load_odvs_for_detail_filters(enabled_only) |> group_by_option_detail()

    build_option_detail_filter_index(filter_list, detail_list, odv_list)
  end

  defp build_option_detail_filter_index(filter_list, detail_list, odv_list) do
    filter_list
    |> Enum.reduce(%{}, fn filter, memo ->
      detail_odvs = Map.get(odv_list, filter.option_detail_id, [])
      option_detail = Map.get(detail_list, filter.option_detail_id, %{format: "string"})
      option_ids = filter_by_match_value(detail_odvs, filter.match_value, option_detail.format)

      build_index_map(memo, filter, option_ids)
    end)
    |> Enum.into(%{})
  end

  defp filter_by_match_value([], _, _), do: []

  defp filter_by_match_value(odv_list, match_value, format) do
    Enum.filter(odv_list, fn %{value: detail_value} ->
      {_, matchable_string} = to_matchable_string(detail_value, format)
      match_value == matchable_string
    end)
    |> extract_option_ids()
  end

  def load_odvs_for_detail_filters(nil, _), do: []
  def load_odvs_for_detail_filters([], _), do: []

  def load_odvs_for_detail_filters(filter_list, enabled_only) do
    option_detail_ids =
      filter_list
      |> Enum.map(&Map.get(&1, :option_detail_id, false))
      |> Enum.filter(& &1)
      |> Enum.uniq()

    decision_id = filter_list |> hd() |> Map.get(:decision_id)

    query =
      Option
      |> join(:left, [o], odv in OptionDetailValue, on: odv.option_id == o.id)
      |> where([o, odv], odv.option_detail_id in ^option_detail_ids)
      |> where([o, odv], o.decision_id == ^decision_id)
      |> select([o, odv], %{
        option_id: o.id,
        option_detail_id: odv.option_detail_id,
        value: odv.value
      })

    query =
      if enabled_only == true do
        query |> where([o, odv], o.enabled == true)
      else
        query
      end

    Repo.all(query)
  end

  defp options_by_category_and_all(nil), do: %{}

  defp options_by_category_and_all(options) do
    option_index =
      options
      |> group_by_option_category()
      |> Enum.map(fn {oc_id, group} -> {oc_id, extract_option_ids(group)} end)
      |> Enum.into(%{})

    option_index = Map.put(option_index, :all, extract_option_ids(options))

    option_index
  end

  defp load_options(decision_id, enabled_only) do
    query =
      Option
      |> where([o], o.decision_id == ^decision_id)
      |> select([o], %{id: o.id, option_category_id: o.option_category_id})
      |> order_by(asc: :id)

    query =
      if enabled_only == true do
        query |> where([o], o.enabled == true)
      else
        query
      end

    Repo.all(query)
  end

  defp extract_option_ids(list) do
    list
    |> Enum.map(fn
      %{option_id: id} -> id
      %{id: id} -> id
    end)
    |> Enum.uniq()
  end
end
