defmodule EtheloApi.Graphql.Resolvers.BinVote do
  @moduledoc """
  Resolvers for graphql.
  """

  alias EtheloApi.Voting
  alias EtheloApi.Structure.Decision
  import EtheloApi.Helpers.ValidationHelper

  @doc """
  lists all BinVotes

  See `EtheloApi.Voting.list_bin_votes/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Voting.list_bin_votes(modifiers) |> success()
  end

  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  return a summary of BinVotes by date
  """
  def activity(decision, params, _resolution) do
    interval = Map.get(params, :interval)
    {:ok, Voting.bin_vote_activity(decision, interval)}
  end

  @doc """
  Add, Update or Deletes a BinVote

  See `EtheloApi.Voting.upsert_bin_vote/2` and `EtheloApi.Voting.delete_bin_vote/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def upsert(
        %{input: %{decision: decision, delete: true} = attrs},
        _resolution
      ) do
    modifiers = %{
      criteria_id: attrs.criteria_id,
      option_id: attrs.option_id,
      participant_id: attrs.participant_id
    }

    Voting.delete_bin_vote(modifiers, decision)
    {:ok, nil}
  end

  def upsert(%{input: %{decision: decision} = attrs}, _resolution) do
    Voting.upsert_bin_vote(attrs, decision)
  end
end
