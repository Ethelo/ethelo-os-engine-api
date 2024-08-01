defmodule EtheloApi.Graphql.Docs.OptionCategoryRangeVote do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  # TODO delete param
  alias EtheloApi.Voting.Docs.OptionCategoryRangeVote, as: OptionCategoryRangeVoteDocs
  alias EtheloApi.Graphql.QueryHelper

  def input_fields() do
    [
      :high_option_id,
      :low_option_id,
      :option_category_id,
      :participant_id
    ]
  end

  defp sample1() do
    Map.get(OptionCategoryRangeVoteDocs.examples(), "Sample 1")
  end

  defp sample2() do
    Map.get(OptionCategoryRangeVoteDocs.examples(), "Sample 2")
  end

  @spec list() :: String.t()
  def list() do
    QueryHelper.query_example(
      "optionCategoryRangeVotes",
      sample1() |> Map.take([:decision_id]),
      Map.keys(sample1()),
      [sample1(), sample2()],
      "List matching OptionCategoryRangeVotes"
    )
  end

  @spec upsert() :: String.t()
  def upsert() do
    params = QueryHelper.mutation_params(sample1(), input_fields())

    QueryHelper.mutation_example(
      "upsertOptionCategoryRangeVote",
      params,
      Map.keys(sample1()),
      sample1(),
      "Add or Update an OptionCategoryRangeVote"
    )
  end

  @spec delete() :: String.t()
  def delete() do
    attrs = sample1() |> Map.put(:delete, true)
    params = QueryHelper.mutation_params(attrs, input_fields() ++ [:delete])

    QueryHelper.mutation_example(
      "upsertOptionCategoryRangeVote",
      params,
      [:id],
      nil,
      "Delete a OptionCategoryRangeVote via Upsert"
    )
  end
end
