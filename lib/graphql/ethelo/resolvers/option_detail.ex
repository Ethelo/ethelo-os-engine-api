defmodule GraphQL.EtheloApi.Resolvers.OptionDetail do
  @moduledoc """
  Resolvers for graphql.
  """
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.OptionDetail
  import GraphQL.EtheloApi.ResolveHelper
  import GraphQL.EtheloApi.BatchHelper

  @doc """
  lists all option_details

  See `EtheloApi.Structure.list_option_details/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """

  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Structure.list_option_details(modifiers) |> success()
  end
  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  batch loads all OptionDetailValues for the Decision, then filters to match the specified record
  """
  def batch_option_values(parent, modifiers, _resolution) do
    modifiers = Map.put(modifiers, :option_detail_id, parent.id)
    resolver = {Structure, :match_option_detail_values, modifiers}
    batch_has_many(parent, :option_detail_values, :option_detail_id, resolver)
  end

  @doc """
  creates a new OptionDetail

  See `EtheloApi.Structure.create_option_detail/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def create(decision, attrs) do
    Structure.create_option_detail(decision, attrs)
  end

  @doc """
  updates an existing OptionDetail.

  See `EtheloApi.Structure.update_option_detail/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def update(decision, %{id: id} = attrs) do
    case EtheloApi.Structure.get_option_detail(id, decision) do
      nil -> not_found_error()
      option_detail -> Structure.update_option_detail(option_detail, attrs)
    end
  end

  @doc """
  updates an existing OptionDetail.

  See `EtheloApi.Structure.delete_option_detail/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(decision, %{id: id}) do
    Structure.delete_option_detail(id, decision)
  end

  @doc """
  batch loads all OptionDetails in a Decision, then matches to specified record
  """
  def batch_load_belongs_to(parent, _, info) do
    resolver = {Structure, :match_option_details, %{decision_id: parent.decision_id}}
    batch_belongs_to(parent, %OptionDetail{}, :option_detail, resolver, info)
  end

end
