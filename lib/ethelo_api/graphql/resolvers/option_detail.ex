defmodule EtheloApi.Graphql.Resolvers.OptionDetail do
  @moduledoc """
  Resolvers for graphql.
  """
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  import EtheloApi.Helpers.ValidationHelper

  @doc """
  lists all OptionDetails

  See `EtheloApi.Structure.list_option_details/4` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """

  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Structure.list_option_details(modifiers) |> success()
  end

  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  Creates a new OptionDetail

  See `EtheloApi.Structure.create_option_detail/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def create(%{input: %{decision: decision} = attrs}, _resolution) do
    Structure.create_option_detail(attrs, decision)
  end

  @doc """
  Updates an OptionDetail.

  See `EtheloApi.Structure.update_option_detail/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def update(%{input: %{decision: decision, id: id} = attrs}, _resolution) do
    case EtheloApi.Structure.get_option_detail(id, decision) do
      nil -> {:ok, not_found_error()}
      option_detail -> Structure.update_option_detail(option_detail, attrs)
    end
  end

  @doc """
  Deletes an OptionDetail.

  See `EtheloApi.Structure.delete_option_detail/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(%{input: %{decision: decision, id: id}}, _resolution) do
    Structure.delete_option_detail(id, decision)
  end
end
