defmodule GraphQL.EtheloApi.Resolvers.OptionCategoryRangeVote do
  @moduledoc """
  Resolvers for graphql.
  """

  alias EtheloApi.Voting
  alias EtheloApi.Structure.Decision
  import GraphQL.EtheloApi.ResolveHelper

  @doc """
  lists all OptionCategoryRangeVotes

  See `EtheloApi.Voting.list_option_category_range_votes/1` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Voting.list_option_category_range_votes(modifiers) |> success()
  end
  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  upserts a OptionCategoryRangeVote

  See `EtheloApi.Voting.upsert_option_category_range_vote/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def upsert(decision, attrs) do
    if Map.get(attrs, :delete, false) do
      filters = %{participant_id: attrs.participant_id, option_category_id: attrs.option_category_id}
      Voting.delete_option_category_range_vote(filters, decision)
      {:ok, nil}
    else
      Voting.upsert_option_category_range_vote(decision, attrs)
    end
  end

  @doc """
  deletes a OptionCategoryRangeVote.

  See `EtheloApi.Voting.delete_option_category_range_vote/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(decision, %{id: id}) do
    Voting.delete_option_category_range_vote(id, decision)
  end


end
