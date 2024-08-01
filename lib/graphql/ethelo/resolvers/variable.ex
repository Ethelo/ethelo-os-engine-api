defmodule GraphQL.EtheloApi.Resolvers.Variable do
  @moduledoc """
  Resolvers for graphql.
  """
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  import GraphQL.EtheloApi.BatchHelper
  import GraphQL.EtheloApi.ResolveHelper
  alias EtheloApi.Structure.Variable


  @doc """
  lists all Variables

  See `EtheloApi.Structure.list_variables/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """

  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Structure.list_variables(modifiers) |> success()
  end
  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  lists suggested Variables

  See `EtheloApi.Structure.suggested_variables/1` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def suggested(%{decision: %Decision{} = decision}, _args, _info) do
    decision |> Structure.suggested_variables() |> success()
  end
  def suggested(_, _, _info), do: nil

  @doc """
  loads all Calculations then filters them by parent
  """
  def batch_load_calculations(parent, modifiers, _resolution) do
    modifiers = Map.put(modifiers, :decision_id, parent.decision_id)
    resolver = {Structure, :match_calculations, modifiers}
    batch_many_to_many(parent, :calculations, :variables, resolver)
  end

  @doc """
  creates a new Variable

  See `EtheloApi.Structure.create_variable/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def create(decision, attrs) do
    Structure.create_variable(decision, attrs)
  end

  @doc """
  updates an existing Variable.

  See `EtheloApi.Structure.update_variable/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def update(decision, %{id: id} = attrs) do
    case EtheloApi.Structure.get_variable(id, decision) do
      nil -> not_found_error()
      variable -> Structure.update_variable(variable, attrs)
    end
  end

  @doc """
  updates an existing Variable.

  See `EtheloApi.Structure.delete_variable/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(decision, %{id: id}) do
    Structure.delete_variable(id, decision)
  end

  @doc """
  batch loads all Variables in a Decision, then matches to specified record
  """
  def batch_load_belongs_to(parent, _, info) do
    resolver = {Structure, :match_variables, %{decision_id: parent.decision_id}}
    batch_belongs_to(parent, %Variable{}, :variable, resolver, info)
  end

end
