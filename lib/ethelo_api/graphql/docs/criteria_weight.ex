defmodule EtheloApi.Graphql.Docs.CriteriaWeight do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  # TODO delete param
  alias EtheloApi.Voting.Docs.CriteriaWeight, as: CriteriaWeightDocs
  alias EtheloApi.Graphql.QueryHelper

  def input_fields() do
    [
      :criteria_id,
      :participant_id,
      :weighting
    ]
  end

  defp sample1() do
    Map.get(CriteriaWeightDocs.examples(), "Sample 1")
  end

  defp sample2() do
    Map.get(CriteriaWeightDocs.examples(), "Sample 2")
  end

  @spec list() :: String.t()
  def list() do
    QueryHelper.query_example(
      "criteriaWeights",
      sample1() |> Map.take([:decision_id]),
      Map.keys(sample1()),
      [sample1(), sample2()],
      "List matching CriteriaWeights"
    )
  end

  @spec upsert() :: String.t()
  def upsert() do
    params = QueryHelper.mutation_params(sample1(), input_fields())

    QueryHelper.mutation_example(
      "upsertCriteriaWeight",
      params,
      Map.keys(sample1()),
      sample1(),
      "Add or Update a CriteriaWeight"
    )
  end

  @spec delete() :: String.t()
  def delete() do
    attrs = sample1() |> Map.put(:delete, true)
    params = QueryHelper.mutation_params(attrs, input_fields() ++ [:delete])

    QueryHelper.mutation_example(
      "upsertCriteriaWeight",
      params,
      [:id],
      nil,
      "Delete a CriteriaWeight via Upsert"
    )
  end
end
