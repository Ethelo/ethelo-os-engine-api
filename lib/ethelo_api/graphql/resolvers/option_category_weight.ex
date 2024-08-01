defmodule EtheloApi.Graphql.Resolvers.OptionCategoryWeight do
  @moduledoc """
  Resolvers for graphql.
  """

  alias EtheloApi.Voting
  alias EtheloApi.Structure.Decision
  import EtheloApi.Helpers.ValidationHelper

  @doc """
  lists all OptionCategoryWeights

  See `EtheloApi.Voting.list_option_category_weights/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Voting.list_option_category_weights(modifiers) |> success()
  end

  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  Upserts a OptionCategoryWeight  Add, Update
  or Deletes a OptionCategoryWeight

  See `EtheloApi.Voting.upsert_option_category_weight/2` and `EtheloApi.Voting.delete_option_category_weight/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def upsert(
        %{input: %{decision: decision, delete: true} = attrs},
        _resolution
      ) do
    modifiers = %{
      option_category_id: attrs.option_category_id,
      participant_id: attrs.participant_id
    }

    Voting.delete_option_category_weight(modifiers, decision)
    {:ok, nil}
  end

  def upsert(%{input: %{decision: decision} = attrs}, _resolution) do
    Voting.upsert_option_category_weight(attrs, decision)
  end
end
