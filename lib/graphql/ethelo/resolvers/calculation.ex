defmodule GraphQL.EtheloApi.Resolvers.Calculation do
  @moduledoc """
  Resolvers for graphql.
  """
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Calculation
  import GraphQL.EtheloApi.ResolveHelper
  import GraphQL.EtheloApi.BatchHelper

  @doc """
  lists all calculations

  See `EtheloApi.Structure.list_calculations/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """

  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Structure.list_calculations(modifiers) |> success()
  end
  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  loads all variables then filters them by parent
  """
  def batch_load_variables(parent, modifiers, _resolution) do
    modifiers = Map.put(modifiers, :decision_id, parent.decision_id)
    resolver = {Structure, :match_variables, modifiers}
    batch_many_to_many(parent, :variables, :calculations, resolver)
  end

  @doc """
  creates a new Calculation

  See `EtheloApi.Structure.create_calculation/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def create(decision, attrs) do
    Structure.create_calculation(decision, attrs)
  end

  @doc """
  updates an existing Calculation.

  See `EtheloApi.Structure.update_calculation/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def update(decision, %{id: id} = attrs) do
    case EtheloApi.Structure.get_calculation(id, decision) do
      nil -> not_found_error()
      calculation -> Structure.update_calculation(calculation, attrs)
    end
  end

  @doc """
  updates an existing Calculation.

  See `EtheloApi.Structure.delete_calculation/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(decision, %{id: id}) do
    Structure.delete_calculation(id, decision)
  end

  @doc """
  batch loads all Calculation in a Decision, then matches to specified record
  """
  def batch_load_belongs_to(parent, _, info) do
    resolver = {Structure, :match_calculations, %{decision_id: parent.decision_id}}
    batch_belongs_to(parent, %Calculation{}, :calculation, resolver, info)
  end
end
