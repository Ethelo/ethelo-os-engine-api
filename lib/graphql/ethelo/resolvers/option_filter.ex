defmodule GraphQL.EtheloApi.Resolvers.OptionFilter do
  @moduledoc """
  Resolvers for graphql.
  """

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.OptionFilter
  import GraphQL.EtheloApi.BatchHelper
  import GraphQL.EtheloApi.ResolveHelper

  @doc """
  lists all OptionFilterss

  See `EtheloApi.Structure.list_option_filterss/1` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%{decision: %Decision{} = decision}, modifiers, _info) do
    decision |> Structure.list_option_filters(modifiers) |> success()
  end
  def list(_, _, _info), do: nil

  
  @doc """
  lists Options for the OptionFilter

  loads all options for the decision then option_filters them
  """
  def batch_load_options(parent, _args, _info) do
    resolver = {Structure, :all_options_for_all_filters}
    batch_keyed_map(parent, resolver)
  end

  @doc """
  creates a new OptionFilter

  See `EtheloApi.Structure.create_option_filter/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def create(decision, attrs) do
    Structure.create_option_filter(decision, attrs)
  end

  @doc """
  updates an existing OptionFilter.

  See `EtheloApi.Structure.update_option_filter/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def update(decision, %{id: id} = attrs) do
    case EtheloApi.Structure.get_option_filter(id, decision) do
      nil -> not_found_error()
      option_filter ->
        Structure.update_option_filter(option_filter, attrs)
    end
  end

  @doc """
  updates an existing OptionFilter.

  See `EtheloApi.Structure.delete_option/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(decision, %{id: id}) do
    Structure.delete_option_filter(id, decision)
  end


  @doc """
  batch loads all OptionFilters in a Decision, then matches to specified record
  """
  def batch_load_belongs_to(parent, _, info) do
    resolver = {Structure, :match_option_filters, %{decision_id: parent.decision_id}}
    batch_belongs_to(parent, %OptionFilter{}, :option_filter, resolver, info)
  end

end
