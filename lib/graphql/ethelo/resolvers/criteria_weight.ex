defmodule GraphQL.EtheloApi.Resolvers.CriteriaWeight do
  @moduledoc """
  Resolvers for graphql.
  """

  alias EtheloApi.Voting
  alias EtheloApi.Structure.Decision
  import GraphQL.EtheloApi.ResolveHelper

  @doc """
  lists all CriteriaWeights

  See `EtheloApi.Voting.list_criteria_weights/1` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Voting.list_criteria_weights(modifiers) |> success()
  end
  def list(_, _, _resolution), do: {:ok, []}


  @doc """
  upserts an CriteriaWeight

  See `EtheloApi.Voting.upsert_criteria_weight/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def upsert(decision, attrs) do
    if Map.get(attrs, :delete, false) do
      filters = %{participant_id: attrs.participant_id, criteria_id: attrs.criteria_id}
      Voting.delete_criteria_weight(filters, decision)
      {:ok, nil}
    else
      Voting.upsert_criteria_weight(decision, attrs)
    end
  end

  @doc """
  deletes a CriteriaWeight.

  See `EtheloApi.Voting.delete_criteria_weight/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(decision, %{id: id}) do
    Voting.delete_criteria_weight(id, decision)
  end

end
