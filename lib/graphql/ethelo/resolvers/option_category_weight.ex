defmodule GraphQL.EtheloApi.Resolvers.OptionCategoryWeight do
  @moduledoc """
  Resolvers for graphql.
  """

  alias EtheloApi.Voting
  alias EtheloApi.Structure.Decision
  import GraphQL.EtheloApi.ResolveHelper

  @doc """
  lists all OptionCategoryWeights

  See `EtheloApi.Voting.list_option_category_weights/1` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Voting.list_option_category_weights(modifiers) |> success()
  end
  def list(_, _, _resolution), do: {:ok, []}


  @doc """
  upserts an OptionCategoryWeight

  See `EtheloApi.Voting.upsert_option_category_weight/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def upsert(decision, attrs) do
    if Map.get(attrs, :delete, false) do
      filters = %{participant_id: attrs.participant_id, option_category_id: attrs.option_category_id}
      Voting.delete_option_category_weight(filters, decision)
      {:ok, nil}
    else
      Voting.upsert_option_category_weight(decision, attrs)
    end
  end

  @doc """
  deletes a OptionCategoryWeight.

  See `EtheloApi.Voting.delete_option_category_weight/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(decision, %{id: id}) do
    Voting.delete_option_category_weight(id, decision)
  end

end
