defmodule GraphQL.EtheloApi.Docs.BinVote do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  alias EtheloApi.Voting.Docs.BinVote, as: BinVoteDocs
  alias GraphQL.DocBuilder

  defp sample1() do
    Map.get(BinVoteDocs.examples, "Sample 1")
  end

  defp sample2() do
    Map.get(BinVoteDocs.examples, "Sample 2")
  end

  def input_fields() do
    [:decision_id, :weighting]
  end

  defp object_name() do
    "binVote"
  end

  def list() do
    request = sample1()
    responses = [sample1(), sample2()]
    DocBuilder.list("binVotes", request, responses, [:decision_id])
  end

  def get() do
    request = sample1()
    response = sample1()
    param_fields = [:decision_id, :id]
    DocBuilder.get(object_name(), request, response, param_fields)
  end

  def upsert() do
    query_field = "upsertBinVote"
    request = sample1()
    response = sample1()

    DocBuilder.upsert(query_field, request, response, object_name(), input_fields())
  end

  def delete() do
    query_field = "deleteBinVote"
    request = sample1()

    DocBuilder.delete(query_field, request, object_name(), "")
  end

end
