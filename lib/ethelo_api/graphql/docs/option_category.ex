defmodule EtheloApi.Graphql.Docs.OptionCategory do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """

  # TODO add inline queries
  alias EtheloApi.Structure.Docs.OptionCategory, as: OptionCategoryDocs
  alias EtheloApi.Graphql.QueryHelper

  def input_fields() do
    [
      :budget_percent,
      :flat_fee,
      :info,
      :keywords,
      :quadratic,
      :results_title,
      :slug,
      :sort,
      :title,
      :vote_on_percent,
      :weighting
    ]
  end

  defp sample1() do
    Map.get(OptionCategoryDocs.examples(), "Default")
  end

  defp sample2() do
    Map.get(OptionCategoryDocs.examples(), "Food")
  end

  defp update1() do
    Map.get(OptionCategoryDocs.examples(), "Drink")
  end

  @spec list() :: String.t()
  def list() do
    QueryHelper.query_example(
      "optionCategories",
      sample1() |> Map.take([:decision_id]),
      Map.keys(sample1()),
      [sample1(), sample2()],
      "List matching OptionCategories"
    )
  end

  @spec create() :: String.t()
  def create() do
    params = QueryHelper.mutation_params(sample1(), input_fields())

    QueryHelper.mutation_example(
      "createOptionCategory",
      params,
      Map.keys(sample1()),
      sample1(),
      "Add an OptionCategory"
    )
  end

  @spec update() :: String.t()
  def update() do
    params = QueryHelper.mutation_params(update1(), input_fields())

    QueryHelper.mutation_example(
      "updateOptionCategory",
      params,
      Map.keys(sample1()),
      update1(),
      "Update an OptionCategory"
    )
  end

  @spec delete() :: String.t()
  def delete() do
    params = QueryHelper.mutation_params(sample1(), [:decision_id, :id])
    comment = "Delete an OptionCategory.
    Cannot be deleted if there are Options assigned.
    All associated OptionCategoryRangeVotes will also be removed."

    QueryHelper.delete_mutation_example(
      "deleteOptionCategory",
      params,
      [:id],
      sample1() |> Map.take([:id]),
      comment
    )
  end
end
