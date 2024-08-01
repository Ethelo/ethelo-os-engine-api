defmodule EtheloApi.Graphql.Docs.OptionCategoryBinVote do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """

  # TODO delete param
  alias EtheloApi.Voting.Docs.OptionCategoryBinVote, as: OptionCategoryBinVoteDocs
  alias EtheloApi.Graphql.QueryHelper

  def input_fields() do
    [
      :bin,
      :criteria_id,
      :option_id,
      :option_category_id,
      :participant_id
    ]
  end

  defp sample1() do
    Map.get(OptionCategoryBinVoteDocs.examples(), "Sample 1")
  end

  defp sample2() do
    Map.get(OptionCategoryBinVoteDocs.examples(), "Sample 2")
  end

  @spec list() :: String.t()
  def list() do
    QueryHelper.query_example(
      "optionCategoryBinVotes",
      sample1() |> Map.take([:decision_id]),
      Map.keys(sample1()),
      [sample1(), sample2()],
      "List matching OptionCategoryBinVotes"
    )
  end

  @spec upsert() :: String.t()
  def upsert() do
    params = QueryHelper.mutation_params(sample1(), input_fields())

    QueryHelper.mutation_example(
      "upsertOptionCategoryBinVote",
      params,
      Map.keys(sample1()),
      sample1(),
      "Add or Update an OptionCategoryBinVote"
    )
  end

  @spec delete() :: String.t()
  def delete() do
    attrs = sample1() |> Map.put(:delete, true)
    params = QueryHelper.mutation_params(attrs, input_fields() ++ [:delete])

    QueryHelper.mutation_example(
      "upsertOptionCategoryBinVote",
      params,
      [:id],
      nil,
      "Delete a OptionCategoryBinVote via Upsert"
    )
  end
end
