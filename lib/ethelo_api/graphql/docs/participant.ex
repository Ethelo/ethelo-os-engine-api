defmodule EtheloApi.Graphql.Docs.Participant do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  alias EtheloApi.Voting.Docs.Participant, as: ParticipantDocs
  alias EtheloApi.Graphql.QueryHelper

  def input_fields() do
    [
      :decision_id,
      :weighting
    ]
  end

  defp sample1() do
    Map.get(ParticipantDocs.examples(), "Sample 1")
  end

  defp sample2() do
    Map.get(ParticipantDocs.examples(), "Sample 2")
  end

  @spec list() :: String.t()
  def list() do
    QueryHelper.query_example(
      "participants",
      sample1() |> Map.take([:decision_id]),
      Map.keys(sample1()),
      [sample1(), sample2()],
      "List matching Participants"
    )
  end

  @spec create() :: String.t()
  def create() do
    params = QueryHelper.mutation_params(sample1(), input_fields())

    QueryHelper.mutation_example(
      "createParticipant",
      params,
      Map.keys(sample1()),
      sample1(),
      "Add a Participant"
    )
  end

  @spec update() :: String.t()
  def update() do
    params = QueryHelper.mutation_params(sample1(), input_fields())

    QueryHelper.mutation_example(
      "updateParticipant",
      params,
      Map.keys(sample1()),
      sample1(),
      "Update a Participant"
    )
  end

  @spec delete() :: String.t()
  def delete() do
    params = QueryHelper.mutation_params(sample1(), [:decision_id, :id])

    QueryHelper.delete_mutation_example(
      "deleteParticipant",
      params,
      [:id],
      sample1() |> Map.take([:id]),
      "Delete a Participant"
    )
  end
end
