defmodule EtheloApi.Graphql.Resolvers.Calculation do
  @moduledoc """
  Resolvers for graphql.
  """
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  import EtheloApi.Helpers.ValidationHelper

  @doc """
  lists all Calculations

  See `EtheloApi.Structure.list_calculations/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """

  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Structure.list_calculations(modifiers) |> success()
  end

  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  creates a new Calculation

  See `EtheloApi.Structure.create_calculation/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def create(%{input: %{decision: decision} = attrs}, _resolution) do
    Structure.create_calculation(attrs, decision)
  end

  @doc """
  updates a Calculation.

  See `EtheloApi.Structure.update_calculation/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def update(%{input: %{decision: decision, id: id} = attrs}, _resolution) do
    case EtheloApi.Structure.get_calculation(id, decision) do
      nil -> {:ok, not_found_error()}
      calculation -> Structure.update_calculation(calculation, attrs)
    end
  end

  @doc """
  Deletes a Calculation.

  See `EtheloApi.Structure.delete_calculation/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(%{input: %{decision: decision, id: id}}, _resolution) do
    Structure.delete_calculation(id, decision)
  end
end
