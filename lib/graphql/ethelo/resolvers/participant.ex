defmodule GraphQL.EtheloApi.Resolvers.Participant do
  @moduledoc """
  Resolvers for graphql.
  """

  alias EtheloApi.Voting
  alias EtheloApi.Structure.Decision
  import GraphQL.EtheloApi.ResolveHelper
  import GraphQL.EtheloApi.BatchHelper

  @doc """
  lists all Participants

  See `EtheloApi.Voting.list_participants/1` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Voting.list_participants(modifiers) |> success()
  end
  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  gets a single Participant

  See `EtheloApi.Voting.get_participant/1` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def get(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    case decision |> Voting.list_participants(modifiers) |> Enum.take(1) do
      [participant] -> participant |> success()
      _ -> {:ok, nil}
    end
  end
  def get(_, _, _resolution), do: {:ok, nil}

  @doc """
  creates a new Participant

  See `EtheloApi.Voting.create_participant/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def create(decision, attrs) do
    Voting.create_participant(decision, attrs)
  end

  @doc """
  updates an existing Participant.

  See `EtheloApi.Voting.update_participant/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def update(decision, %{id: id} = attrs) do
    case EtheloApi.Voting.get_participant(id, decision) do
      nil -> not_found_error()
      option ->
        Voting.update_participant(option, attrs)
    end
  end

  @doc """
  deletes a Participant.

  See `EtheloApi.Voting.delete_participant/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(decision, %{id: id}) do
    Voting.delete_participant(id, decision)
  end

  @doc """
  batch loads all BinVotes in a Decision, then matches to specified record
  """
  def batch_load_bin_votes(parent, modifiers, _resolution) do
    modifiers = Map.put(modifiers, :decision_id, parent.decision_id)
    resolver = {Voting, :match_bin_votes, modifiers}
    batch_has_many(parent, :bin_votes, :participant_id, resolver)
  end

  @doc """
  batch loads all OptionCategoryRangeVotes in a Decision, then matches to specified record
  """
  def batch_load_option_category_range_votes(parent, modifiers, _resolution) do
    modifiers = Map.put(modifiers, :decision_id, parent.decision_id)
    resolver = {Voting, :match_option_category_range_votes, modifiers}
    batch_has_many(parent, :option_category_range_votes, :participant_id, resolver)
  end

  @doc """
  batch loads all OptionCategoryWeights in a Decision, then matches to specified record
  """
  def batch_load_option_category_weights(parent, modifiers, _resolution) do
    modifiers = Map.put(modifiers, :decision_id, parent.decision_id)
    resolver = {Voting, :match_option_category_weights, modifiers}
    batch_has_many(parent, :option_category_weights, :participant_id, resolver)
  end

  @doc """
  batch loads all CriteriaWeights in a Decision, then matches to specified record
  """
  def batch_load_criteria_weights(parent, modifiers, _resolution) do
    modifiers = Map.put(modifiers, :decision_id, parent.decision_id)
    resolver = {Voting, :match_criteria_weights, modifiers}
    batch_has_many(parent, :criteria_weights, :participant_id, resolver)
  end

end
