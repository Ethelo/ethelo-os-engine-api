defmodule EtheloApi.Graphql.Resolvers.Variable do
  @moduledoc """
  Resolvers for graphql.
  """
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  import EtheloApi.Helpers.ValidationHelper

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
  def suggested(%{decision: %Decision{} = decision}, _modifiers, _resolution) do
    decision |> Structure.suggested_variables() |> success()
  end

  def suggested(_, _, _info), do: nil

  @doc """
  Creates a new Variable

  See `EtheloApi.Structure.create_variable/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def create(%{input: %{decision: decision} = attrs}, _resolution) do
    Structure.create_variable(attrs, decision)
  end

  @doc """
  Updates a Variable.

  See `EtheloApi.Structure.update_variable/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def update(%{input: %{decision: decision, id: id} = attrs}, _resolution) do
    case EtheloApi.Structure.get_variable(id, decision) do
      nil -> {:ok, not_found_error()}
      variable -> Structure.update_variable(variable, attrs)
    end
  end

  @doc """
  Deletes a Variable.

  See `EtheloApi.Structure.delete_variable/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(%{input: %{decision: decision, id: id}}, _resolution) do
    Structure.delete_variable(id, decision)
  end

  def datasource() do
    Dataloader.KV.new(&batch_query/2)
  end

  # returned keys must be the Variables passed in, not the Variable ids
  defp batch_query({:calculation_ids_by_variable, _field_args}, variables) do
    variable_ids = Enum.map(variables, & &1.id)

    ids_by_variable = Structure.calculation_ids_by_variable(variable_ids)

    variables
    |> Map.new(fn variable ->
      {variable, Map.get(ids_by_variable, variable.id)}
    end)
  end

  defp batch_query({_field_identifier, _field_args}, _args) do
    %{}
  end
end
