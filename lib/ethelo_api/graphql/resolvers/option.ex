defmodule EtheloApi.Graphql.Resolvers.Option do
  @moduledoc """
  Resolvers for graphql.
  """

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  import EtheloApi.Helpers.ValidationHelper

  @doc """
  lists all Options

  See `EtheloApi.Structure.list_options/4` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Structure.list_options(modifiers) |> success()
  end

  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  creates a new Option

  See `EtheloApi.Structure.create_option/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def create(%{input: %{decision: decision} = attrs}, _resolution) do
    Structure.create_option(attrs, decision)
  end

  @doc """
  updates an Option.

  See `EtheloApi.Structure.update_option/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def update(%{input: %{decision: decision, id: id} = attrs}, _resolution) do
    case EtheloApi.Structure.get_option(id, decision) do
      nil -> {:ok, not_found_error()}
      option -> Structure.update_option(option, attrs)
    end
  end

  @doc """
  Deletes an Option.

  See `EtheloApi.Structure.delete_option/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(%{input: %{decision: decision, id: id}}, _resolution) do
    Structure.delete_option(id, decision)
  end
end
