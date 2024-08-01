defmodule EtheloApi.Graphql.Docs.Option do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """

  # TODO add inline queries

  alias EtheloApi.Structure.Docs.Option, as: OptionDocs
  alias EtheloApi.Graphql.QueryHelper

  def input_fields() do
    [
      #  :determinative,
      :enabled,
      :info,
      :option_category_id,
      :results_title,
      :slug,
      :sort,
      :title
    ]
  end

  defp sample1() do
    Map.get(OptionDocs.examples(), "Sample 1")
  end

  defp sample2() do
    Map.get(OptionDocs.examples(), "Sample 2")
  end

  defp update1() do
    Map.get(OptionDocs.examples(), "Update 1") |> Map.put(:id, sample1().id)
  end

  # TODO: filter example
  @spec list() :: String.t()
  def list() do
    QueryHelper.query_example(
      "options",
      sample1() |> Map.take([:decision_id]),
      Map.keys(sample1()),
      [sample1(), sample2()],
      "List matching Options"
    )
  end

  @spec create() :: String.t()
  def create() do
    params = QueryHelper.mutation_params(sample1(), input_fields())

    QueryHelper.mutation_example(
      "createOption",
      params,
      Map.keys(sample1()),
      sample1(),
      "Add an Option"
    )
  end

  @spec update() :: String.t()
  def update() do
    params = QueryHelper.mutation_params(update1(), input_fields())

    QueryHelper.mutation_example(
      "updateOption",
      params,
      Map.keys(sample1()),
      update1(),
      "Update an Option"
    )
  end

  @spec delete() :: String.t()
  def delete() do
    params = QueryHelper.mutation_params(sample1(), [:decision_id, :id])

    comment = ~s[
      Delete an Option

      All associated OptionDetailValues, BinVotes and OptionCategoryRangeVotes will also be removed.

      THIS CANNOT BE UNDONE!
    ]

    QueryHelper.delete_mutation_example(
      "deleteOption",
      params,
      [:id],
      sample1() |> Map.take([:id]),
      comment
    )
  end
end
