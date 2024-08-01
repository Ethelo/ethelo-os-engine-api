defmodule GraphQL.EtheloApi.Resolvers.OptionCategory do
  @moduledoc """
  Resolvers for graphql.
  """
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  import GraphQL.EtheloApi.BatchHelper
  import GraphQL.EtheloApi.ResolveHelper
  alias EtheloApi.Structure.OptionCategory

  @doc """
  lists all option_categories

  See `EtheloApi.Structure.list_option_categories/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """

  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Structure.list_option_categories(modifiers) |> success()
  end
  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  batch loads all Options in a Decision, then matches to specified record
  """
  def batch_load_options(parent, modifiers, _resolution) do
    modifiers = Map.put(modifiers, :decision_id, parent.decision_id)
    resolver = {Structure, :match_options, modifiers}
    batch_has_many(parent, :options, :option_category_id, resolver)
  end

  @doc """
  creates a new OptionCategory

  See `EtheloApi.Structure.create_option_category/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def create(decision, attrs) do
    Structure.create_option_category(decision, attrs)
  end

  @doc """
  updates an existing OptionCategory.

  See `EtheloApi.Structure.update_option_category/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def update(decision, %{id: id} = attrs) do
    case EtheloApi.Structure.get_option_category(id, decision) do
      nil -> not_found_error()
      option_category -> Structure.update_option_category(option_category, attrs)
    end
  end

  @doc """
  updates an existing OptionCategory.

  See `EtheloApi.Structure.delete_option_category/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(decision, %{id: id}) do
    Structure.delete_option_category(id, decision)
  end

  @doc """
  batch loads all OptionCategories in a Decision, then matches to specified OptionCategory by id
  """
  def batch_load_belongs_to(parent, _, info) do
    resolver = {Structure, :match_option_categories, %{decision_id: parent.decision_id}}
    batch_belongs_to(parent, %OptionCategory{}, :option_category, resolver, info)
  end
end
