defmodule GraphQL.EtheloApi.Resolvers.OptionDetailValue do
  @moduledoc """
  Resolvers for graphql.
  """

  alias EtheloApi.Structure

  @doc """
  update or create an existing OptionDetailValue.

  See `EtheloApi.Structure.update_option/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def update(decision, %{option_id: _, option_detail_id: _} = attrs) do
    Structure.upsert_option_detail_value(decision, attrs)
  end

  @doc """
  updates an existing OptionDetailValue.

  See `EtheloApi.Structure.delete_option/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(decision, %{option_id: _, option_detail_id: _} = attrs) do
    Structure.delete_option_detail_value(attrs, decision)
  end
end
