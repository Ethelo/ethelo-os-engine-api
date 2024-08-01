defmodule EtheloApi.Graphql.Resolvers.OptionDetailValue do
  @moduledoc """
  Resolvers for graphql.
  """

  alias EtheloApi.Structure

  @doc """
  Add or Update an OptionDetailValue.

  See `EtheloApi.Structure.upsert_option_detail_value/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def upsert(
        %{input: %{decision: decision, option_id: _, option_detail_id: _} = attrs},
        _resolution
      ) do
    Structure.upsert_option_detail_value(attrs, decision)
  end

  @spec delete(
          %{
            :input => %{
              :decision => any(),
              :option_detail_id => any(),
              :option_id => any(),
              optional(any()) => any()
            },
            optional(any()) => any()
          },
          any()
        ) :: {:ok, nil} | map()
  @doc """
  Deletes an OptionDetailValue.

  See `EtheloApi.Structure.delete_option_detail_value/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(
        %{input: %{decision: decision, option_id: _, option_detail_id: _} = attrs},
        _resolution
      ) do
    Structure.delete_option_detail_value(attrs, decision)
  end
end
