defmodule EtheloApi.Graphql.Docs.OptionFilter do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  # TODO add inline queries
  alias EtheloApi.Structure.Docs.OptionFilter, as: OptionFilterDocs
  alias EtheloApi.Graphql.QueryHelper

  def input_fields() do
    [
      :match_mode,
      :match_value,
      :option_category_id,
      :option_detail_id,
      :slug,
      :title
    ]
  end

  defp sample1() do
    Map.get(OptionFilterDocs.examples(), "Option Detail Sample 1")
  end

  defp sample2() do
    Map.get(OptionFilterDocs.examples(), "Option Category Sample")
  end

  defp sample3() do
    Map.get(OptionFilterDocs.examples(), "Option Detail Sample 2")
  end

  defp update1() do
    Map.get(OptionFilterDocs.examples(), "Option Category Sample")
  end

  defp update2() do
    Map.get(OptionFilterDocs.examples(), "Option Detail Sample 2")
  end

  @spec list() :: String.t()
  def list() do
    QueryHelper.query_example(
      "optionFilters",
      sample1() |> Map.take([:decision_id]),
      Map.keys(sample1()),
      [sample1(), sample2()],
      "List matching OptionFilters"
    )
  end

  @spec create_option_detail_filter() :: String.t()
  def create_option_detail_filter() do
    input_fields = input_fields() |> List.delete([:option_category_id])

    params = QueryHelper.mutation_params(sample1(), input_fields)

    QueryHelper.mutation_example(
      "createOptionDetailFilter",
      params,
      Map.keys(sample1()),
      sample1(),
      "Add an OptionFilter using an OptionDetail"
    )
  end

  @spec update_option_detail_filter() :: String.t()
  def update_option_detail_filter() do
    input_fields = input_fields() |> List.delete([:option_category_id])

    params = QueryHelper.mutation_params(update1(), input_fields)

    QueryHelper.mutation_example(
      "updateOptionDetailFilter",
      params,
      Map.keys(update1()),
      update1(),
      "Update an OptionFilter using an OptionDetail"
    )
  end

  @spec create_option_category_filter() :: String.t()
  def create_option_category_filter() do
    input_fields = input_fields() |> List.delete([:option_detail_id])

    params = QueryHelper.mutation_params(sample3(), input_fields)

    QueryHelper.mutation_example(
      "createOptionCategoryFilter",
      params,
      Map.keys(sample3()),
      sample3(),
      "Add an OptionFilter using an OptionCategory"
    )
  end

  @spec update_option_category_filter() :: String.t()
  def update_option_category_filter() do
    input_fields = input_fields() |> List.delete([:option_detail_id])

    params = QueryHelper.mutation_params(update2(), input_fields)

    QueryHelper.mutation_example(
      "updateOptionCategoryFilter",
      params,
      Map.keys(sample3()),
      sample3(),
      "Update an OptionFilter using an OptionCategory"
    )
  end

  @spec delete() :: String.t()
  def delete() do
    params = QueryHelper.mutation_params(sample1(), [:decision_id, :id])
    comment = "Delete an OptionFilter.
    Default Option Filters will be automatically recreated."

    QueryHelper.delete_mutation_example(
      "deleteOptionFilter",
      params,
      [:id],
      sample1() |> Map.take([:id]),
      comment
    )
  end
end
