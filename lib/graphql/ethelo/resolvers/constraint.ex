defmodule GraphQL.EtheloApi.Resolvers.Constraint do
  @moduledoc """
  Resolvers for graphql.
  """
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  import GraphQL.EtheloApi.ResolveHelper
  import GraphQL.EtheloApi.BatchHelper

  @doc """
  lists all constraints

  See `EtheloApi.Structure.list_constraints/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """

  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Structure.list_constraints(modifiers) |> success()
  end
  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  batch loads all Variables in a Decision, then matches to specified record
  """
  def batch_load_variables(parent, modifiers, _resolution) do
    modifiers = Map.put(modifiers, :decision_id, parent.decision_id)
    resolver = {Structure, :match_variables, modifiers}
    batch_many_to_many(parent, :variables, :calculations, resolver)
  end

  defp prepare_attrs(%{operator: operator} = attrs) do
    attrs = if operator == :between do
      upper = Map.get(attrs, :between_high)
      if upper != nil, do: Map.put(attrs, :rhs, upper), else: attrs
    else
      value = Map.get(attrs, :value)
      if value != nil, do: Map.put(attrs, :rhs, value), else: attrs
    end

    lower = Map.get(attrs, :between_low)
    attrs = if lower != nil, do: Map.put(attrs, :lhs, lower), else: attrs

    Map.drop(attrs, [:value, :between_high, :between_low])
  end
  defp prepare_attrs(%{} = attrs) do
    attrs |> Map.put(:operator, :between)
          |> prepare_attrs
  end

  defp prepare_changeset_errors({:error, %Ecto.Changeset{} = changeset}) do
    operator = Ecto.Changeset.get_field(changeset, :operator)

    errors = changeset
    |> Ecto.Changeset.traverse_errors(fn(_changeset, field, error) ->
      field = graphql_field_name(operator, field)
      Kronky.ChangesetParser.construct_message(field, error)
    end)
    |> Enum.flat_map(fn({_, messages}) -> messages end)

    {:ok, {:error, errors}}
  end
  defp prepare_changeset_errors(response), do: response

  defp graphql_field_name(:between, :rhs), do: :between_high
  defp graphql_field_name(_, :rhs), do: :value
  defp graphql_field_name(_, :lhs), do: :between_low
  defp graphql_field_name(_, field), do: field

  @doc """
  creates a new Constraint

  See `EtheloApi.Structure.create_constraint/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def create(decision, attrs) do
    attrs = prepare_attrs(attrs)

    decision
    |> Structure.create_constraint(attrs)
    |> prepare_changeset_errors()
  end

  @doc """
  updates an existing  Constraint.

  See `EtheloApi.Structure.update_constraint/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def update(decision, %{id: id} = attrs) do
    constraint = EtheloApi.Structure.get_constraint(id, decision)

    if is_nil(constraint) do
      not_found_error()
    else
      attrs = prepare_attrs(attrs)

      constraint
      |> Structure.update_constraint(attrs)
      |> prepare_changeset_errors()
    end
  end

  @doc """
  updates an existing Constraint.

  See `EtheloApi.Structure.delete_constraint/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(decision, %{id: id}) do
    Structure.delete_constraint(id, decision)
  end

  @doc """
  field resolver to return the rhs value of a constraint
  """
  def value(constraint, _params, _resolution) do
    value = if Map.get(constraint, :operator) != :between, do: Map.get(constraint, :rhs)
    {:ok, value}
  end

  @doc """
  field resolver to return the rhs value of a constraint
  """
  def between_high(constraint, _params, _resolution) do
    value = if Map.get(constraint, :operator) == :between, do: Map.get(constraint, :rhs)
    {:ok, value}
  end

  @doc """
  field resolver to return the lhs value of a constraint
  """
  def between_low(constraint, _params, _resolution) do
    {:ok, Map.get(constraint, :lhs)}
  end
end
