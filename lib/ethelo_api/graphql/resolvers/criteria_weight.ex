defmodule EtheloApi.Graphql.Resolvers.CriteriaWeight do
  @moduledoc """
  Resolvers for graphql.
  """

  alias EtheloApi.Voting
  alias EtheloApi.Structure.Decision
  import EtheloApi.Helpers.ValidationHelper

  @doc """
  lists all CriteriaWeights

  See `EtheloApi.Voting.list_criteria_weights/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Voting.list_criteria_weights(modifiers) |> success()
  end

  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  Upserts a CriteriaWeight  Add, Update
  or Deletes a CriteriaWeight

  See `EtheloApi.Voting.upsert_criteria_weight/2` and `EtheloApi.Voting.delete_criteria_weight/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def upsert(
        %{input: %{decision: decision, delete: true} = attrs},
        _resolution
      ) do
    modifiers = %{
      criteria_id: attrs.criteria_id,
      participant_id: attrs.participant_id
    }

    Voting.delete_criteria_weight(modifiers, decision)
    {:ok, nil}
  end

  def upsert(%{input: %{decision: decision} = attrs}, _resolution) do
    Voting.upsert_criteria_weight(attrs, decision)
  end
end
