defmodule EtheloApi.Graphql.Docs.OptionCategoryWeight do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  # TODO delete param
  alias EtheloApi.Voting.Docs.OptionCategoryWeight, as: OptionCategoryWeightDocs
  alias EtheloApi.Graphql.QueryHelper

  def input_fields() do
    [
      :option_category_id,
      :participant_id,
      :weighting
    ]
  end

  defp sample1() do
    Map.get(OptionCategoryWeightDocs.examples(), "Sample 1")
  end

  defp sample2() do
    Map.get(OptionCategoryWeightDocs.examples(), "Sample 2")
  end

  @spec list() :: String.t()
  def list() do
    QueryHelper.query_example(
      "optionCategoryWeights",
      sample1() |> Map.take([:decision_id]),
      Map.keys(sample1()),
      [sample1(), sample2()],
      "List matching OptionCategoryWeights"
    )
  end

  @spec upsert() :: String.t()
  def upsert() do
    params = QueryHelper.mutation_params(sample1(), input_fields())

    QueryHelper.mutation_example(
      "upsertOptionCategoryWeight",
      params,
      Map.keys(sample1()),
      sample1(),
      "Add or Update an OptionCategoryWeight"
    )
  end

  @spec delete() :: String.t()
  def delete() do
    attrs = sample1() |> Map.put(:delete, true)
    params = QueryHelper.mutation_params(attrs, input_fields() ++ [:delete])

    QueryHelper.mutation_example(
      "upsertOptionCategoryWeight",
      params,
      [:id],
      nil,
      "Delete a OptionCategoryWeight via Upsert"
    )
  end
end
