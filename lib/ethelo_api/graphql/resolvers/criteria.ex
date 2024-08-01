defmodule EtheloApi.Graphql.Resolvers.Criteria do
  @moduledoc """
  Resolvers for graphql.
  """
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  import EtheloApi.Helpers.ValidationHelper

  @doc """
  lists all Criterias

  See `EtheloApi.Structure.list_criterias/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """

  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Structure.list_criterias(modifiers) |> success()
  end

  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  Creates a new Criteria

  See `EtheloApi.Structure.create_criteria/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def create(%{input: %{decision: decision} = attrs}, _resolution) do
    Structure.create_criteria(attrs, decision)
  end

  @doc """
  Updates a Criteria.

  See `EtheloApi.Structure.update_criteria/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def update(%{input: %{decision: decision, id: id} = attrs}, _resolution) do
    case EtheloApi.Structure.get_criteria(id, decision) do
      nil -> {:ok, not_found_error()}
      criteria -> Structure.update_criteria(criteria, attrs)
    end
  end

  @doc """
  Deletes a Criteria.

  See `EtheloApi.Structure.delete_criteria/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(%{input: %{decision: decision, id: id}}, _resolution) do
    Structure.delete_criteria(id, decision)
  end
end
