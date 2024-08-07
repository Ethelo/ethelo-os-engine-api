defmodule EtheloApi.Graphql.Resolvers.OptionCategoryRangeVote do
  @moduledoc """
  Resolvers for graphql.
  """

  alias EtheloApi.Voting
  alias EtheloApi.Structure.Decision
  import EtheloApi.Helpers.ValidationHelper

  @doc """
  lists all OptionCategoryRangeVotes

  See `EtheloApi.Voting.list_option_category_range_votes/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Voting.list_option_category_range_votes(modifiers) |> success()
  end

  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  Summary of OptionCategoryRangeVote by date
  """
  def activity(decision, params, _resolution) do
    interval = Map.get(params, :interval)
    {:ok, Voting.option_category_range_vote_activity(decision, interval)}
  end

  @doc """
  Add, Update or Deletes a OptionCategoryRangeVote

  See `EtheloApi.Voting.upsert_option_category_range_vote/2` and `EtheloApi.Voting.delete_option_category_range_vote/2` for more info
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

    Voting.delete_option_category_range_vote(modifiers, decision)
    {:ok, nil}
  end

  def upsert(%{input: %{decision: decision} = attrs}, _resolution) do
    Voting.upsert_option_category_range_vote(attrs, decision)
  end
end
