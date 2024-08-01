defmodule GraphQL.EtheloApi.Resolvers.Criteria do
  @moduledoc """
  Resolvers for graphql.
  """
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  import GraphQL.EtheloApi.ResolveHelper

  @doc """
  lists all criterias

  See `EtheloApi.Structure.list_criterias/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """

  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Structure.list_criterias(modifiers) |> success()
  end
  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  creates a new Criteria

  See `EtheloApi.Structure.create_criteria/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def create(decision, attrs) do
    Structure.create_criteria(decision, attrs)
  end

  @doc """
  updates an existing Criteria.

  See `EtheloApi.Structure.update_criteria/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def update(decision, %{id: id} = attrs) do
    case EtheloApi.Structure.get_criteria(id, decision) do
      nil -> not_found_error()
      criteria -> Structure.update_criteria(criteria, attrs)
    end
  end

  @doc """
  updates an existing Criteria.

  See `EtheloApi.Structure.delete_criteria/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(decision, %{id: id}) do
    Structure.delete_criteria(id, decision)
  end
end
