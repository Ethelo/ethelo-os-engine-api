defmodule EtheloApi.Graphql.Docs.Criteria do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  alias EtheloApi.Structure.Docs.Criteria, as: CriteriaDocs
  alias EtheloApi.Graphql.QueryHelper

  def input_fields() do
    [
      :apply_participant_weights,
      :bins,
      :info,
      :slug,
      :sort,
      :support_only,
      :title,
      :weighting
    ]
  end

  defp sample1() do
    Map.get(CriteriaDocs.examples(), "Sample 1")
  end

  defp sample2() do
    Map.get(CriteriaDocs.examples(), "Sample 2")
  end

  defp update1() do
    Map.get(CriteriaDocs.examples(), "Update 1")
  end

  @spec list() :: String.t()
  def list() do
    QueryHelper.query_example(
      "criterias",
      sample1() |> Map.take([:decision_id]),
      Map.keys(sample1()),
      [sample1(), sample2()],
      "List matching Criterias"
    )
  end

  @spec create() :: String.t()
  def create() do
    params = QueryHelper.mutation_params(sample1(), input_fields())

    QueryHelper.mutation_example(
      "createCriteria",
      params,
      Map.keys(sample1()),
      sample1(),
      "Add a Criteria"
    )
  end

  @spec update() :: String.t()
  def update() do
    params = QueryHelper.mutation_params(update1(), input_fields())

    QueryHelper.mutation_example(
      "updateCriteria",
      params,
      Map.keys(sample1()),
      update1(),
      "Update a Criteria"
    )
  end

  def delete() do
    params = QueryHelper.mutation_params(sample1(), [:decision_id, :id])
    comment = "Delete a Criteria.

    All associated BinVotes will also be removed."

    QueryHelper.delete_mutation_example(
      "deleteCriteria",
      params,
      [:id],
      sample1() |> Map.take([:id]),
      comment
    )
  end
end
