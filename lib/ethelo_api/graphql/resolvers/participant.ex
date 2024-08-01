defmodule EtheloApi.Graphql.Resolvers.Participant do
  @moduledoc """
  Resolvers for graphql.
  """

  alias EtheloApi.Voting
  alias EtheloApi.Structure.Decision
  import EtheloApi.Helpers.ValidationHelper

  @doc """
  lists all Participants

  See `EtheloApi.Voting.list_participants/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Voting.list_participants(modifiers) |> success()
  end

  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  Creates a new Participant

  See `EtheloApi.Voting.create_participant/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def create(%{input: %{decision: decision} = attrs}, _resolution) do
    Voting.create_participant(attrs, decision)
  end

  @doc """
  Updates a Participant.

  See `EtheloApi.Voting.update_participant/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def update(%{input: %{decision: decision, id: id} = attrs}, _resolution) do
    case EtheloApi.Voting.get_participant(id, decision) do
      nil -> {:ok, not_found_error()}
      participant -> Voting.update_participant(participant, attrs)
    end
  end

  @doc """
  deletes a Participant.

  See `EtheloApi.Voting.delete_participant/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(%{input: %{decision: decision, id: id}}, _resolution) do
    Voting.delete_participant(id, decision)
  end
end
