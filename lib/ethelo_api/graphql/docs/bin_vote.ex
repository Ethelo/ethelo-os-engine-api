defmodule EtheloApi.Graphql.Docs.BinVote do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  # TODO delete param
  alias EtheloApi.Voting.Docs.BinVote, as: BinVoteDocs
  alias EtheloApi.Graphql.QueryHelper

  def input_fields() do
    [
      :bin,
      :criteria_id,
      :option_id,
      :participant_id
    ]
  end

  defp sample1() do
    Map.get(BinVoteDocs.examples(), "Sample 1")
  end

  defp sample2() do
    Map.get(BinVoteDocs.examples(), "Sample 2")
  end

  @spec list() :: String.t()
  def list() do
    QueryHelper.query_example(
      "binVotes",
      sample1() |> Map.take([:decision_id]),
      Map.keys(sample1()),
      [sample1(), sample2()],
      "List matching BinVotes"
    )
  end

  @spec upsert() :: String.t()
  def upsert() do
    params = QueryHelper.mutation_params(sample1(), input_fields())

    QueryHelper.mutation_example(
      "upsertBinVote",
      params,
      Map.keys(sample1()),
      sample1(),
      "Add or Update a BinVote"
    )
  end

  @spec delete() :: String.t()
  def delete() do
    attrs = sample1() |> Map.put(:delete, true)
    params = QueryHelper.mutation_params(attrs, input_fields() ++ [:delete])

    QueryHelper.mutation_example(
      "upsertBinVote",
      params,
      [:id],
      nil,
      "Delete a BinVote via Upsert"
    )
  end
end
