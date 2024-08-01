defmodule EtheloApi.Graphql.Resolvers.OptionCategoryBinVote do
  @moduledoc """
  Resolvers for graphql.
  """

  alias EtheloApi.Voting
  alias EtheloApi.Structure.Decision
  import EtheloApi.Helpers.ValidationHelper

  @doc """
  lists all OptionCategoryBinVotes

  See `EtheloApi.Voting.list_option_category_bin_votes/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Voting.list_option_category_bin_votes(modifiers) |> success()
  end

  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  Summary of OptionCategoryBinVotes by date
  """
  def activity(decision, params, _resolution) do
    interval = Map.get(params, :interval)
    {:ok, Voting.option_category_bin_vote_activity(decision, interval)}
  end

  @doc """
  Add, Update or Deletes a OptionCategoryBinVote

  See `EtheloApi.Voting.upsert_option_category_bin_vote/2` and `EtheloApi.Voting.delete_option_category_bin_vote/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def upsert(
        %{input: %{decision: decision, delete: true} = attrs},
        _resolution
      ) do
    modifiers = %{
      option_category_id: attrs.option_category_id,
      criteria_id: attrs.criteria_id,
      participant_id: attrs.participant_id
    }

    Voting.delete_option_category_bin_vote(modifiers, decision)
    {:ok, nil}
  end

  def upsert(%{input: %{decision: decision} = attrs}, _resolution) do
    Voting.upsert_option_category_bin_vote(attrs, decision)
  end
end
