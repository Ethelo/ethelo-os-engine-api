defmodule GraphQL.EtheloApi.Resolvers.Option do
  @moduledoc """
  Resolvers for graphql.
  """

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Option
  import GraphQL.EtheloApi.BatchHelper
  import GraphQL.EtheloApi.ResolveHelper

  @doc """
  lists all Options

  See `EtheloApi.Structure.list_options/1` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Structure.list_options(modifiers) |> success()
  end
  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  batch loads all OptionDetailValues for the Decision, then filters to match the loaded Option
  """
  def batch_detail_values(%Option{} = option, modifiers, _resolution) do
    modifiers = Map.put(modifiers, :option_id, option.id)
    resolver = {Structure, :match_option_detail_values, modifiers}
    batch_has_many(option, :option_detail_values, :option_id, resolver)
  end

  @doc """
  creates a new Option

  See `EtheloApi.Structure.create_option/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def create(decision, attrs) do
    Structure.create_option(decision, attrs)
  end

  @doc """
  updates an existing Option.

  See `EtheloApi.Structure.update_option/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def update(decision, %{id: id} = attrs) do
    case EtheloApi.Structure.get_option(id, decision) do
      nil -> not_found_error()
      option ->
        Structure.update_option(option, attrs)
    end
  end

  @doc """
  updates an existing Option.

  See `EtheloApi.Structure.delete_option/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(decision, %{id: id}) do
    Structure.delete_option(id, decision)
  end

  @doc """
  batch loads all Options in a Decision, then matches to specified record
  """
  def batch_load_belongs_to(parent, _, info) do
    resolver = {Structure, :match_options, %{decision_id: parent.decision_id}}
    batch_belongs_to(parent, %Option{}, :option, resolver, info)
  end

end
