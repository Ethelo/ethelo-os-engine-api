defmodule EtheloApi.Graphql.Resolvers.OptionCategory do
  @moduledoc """
  Resolvers for graphql.
  """
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  import EtheloApi.Helpers.ValidationHelper

  @doc """
  lists all OptionCategories

  See `EtheloApi.Structure.list_option_categories/4` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """

  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Structure.list_option_categories(modifiers) |> success()
  end

  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  creates a new OptionCategory

  See `EtheloApi.Structure.create_option_category/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def create(%{input: %{decision: decision} = attrs}, _resolution) do
    Structure.create_option_category(attrs, decision)
  end

  @doc """
  updates an OptionCategory.

  See `EtheloApi.Structure.update_option_category/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def update(%{input: %{decision: decision, id: id} = attrs}, _resolution) do
    case EtheloApi.Structure.get_option_category(id, decision) do
      nil -> {:ok, not_found_error()}
      option_category -> Structure.update_option_category(option_category, attrs)
    end
  end

  @doc """
  Deletes an OptionCategory.

  See `EtheloApi.Structure.delete_option_category/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(%{input: %{decision: decision, id: id}}, _resolution) do
    Structure.delete_option_category(id, decision)
  end
end
