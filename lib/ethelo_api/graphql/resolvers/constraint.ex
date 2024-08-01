defmodule EtheloApi.Graphql.Resolvers.Constraint do
  @moduledoc """
  Resolvers for graphql.
  """
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  import EtheloApi.Helpers.ValidationHelper

  @doc """
  lists all Constraints

  See `EtheloApi.Structure.list_constraints/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """

  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Structure.list_constraints(modifiers) |> success()
  end

  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  creates a new Constraint

  See `EtheloApi.Structure.create_constraint/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def create(%{input: %{decision: decision} = attrs}, _resolution) do
    Structure.create_constraint(attrs, decision)
  end

  @doc """
  updates a Constraint.

  See `EtheloApi.Structure.update_constraint/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """

  def update(%{input: %{decision: decision, id: id} = attrs}, _resolution) do
    case EtheloApi.Structure.get_constraint(id, decision) do
      nil -> {:ok, not_found_error()}
      constraint -> Structure.update_constraint(constraint, attrs)
    end
  end

  @doc """
  Deletes a existing Constraint.

  See `EtheloApi.Structure.delete_constraint/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(%{input: %{decision: decision, id: id}}, _resolution) do
    Structure.delete_constraint(id, decision)
  end
end
