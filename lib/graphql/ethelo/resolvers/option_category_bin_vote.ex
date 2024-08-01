defmodule GraphQL.EtheloApi.Resolvers.OptionCategoryBinVote do
  @moduledoc """
  Resolvers for graphql.
  """

  alias EtheloApi.Voting
  alias EtheloApi.Structure.Decision
  import GraphQL.EtheloApi.ResolveHelper

  @doc """
  lists all OptionCategoryBinVotes

  See `EtheloApi.Voting.list_option_category_bin_votes/1` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Voting.list_option_category_bin_votes(modifiers) |> success()
  end
  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  upserts a OptionCategoryBinVote

  See `EtheloApi.Voting.upsert_option_category_bin_vote/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def upsert(decision, attrs) do
    if Map.get(attrs, :delete, false) do
      Enum.each(Voting.list_option_category_bin_votes(decision, attrs), fn(x) ->
        Voting.delete_option_category_bin_vote(x.id, decision)
      end)
      {:ok, nil}
    else
      Voting.upsert_option_category_bin_vote(decision, attrs)
    end
  end

  @doc """
  deletes a OptionCategoryBinVote.

  See `EtheloApi.Voting.delete_option_category_bin_vote/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(decision, %{id: id}) do
    Voting.delete_option_category_bin_vote(id, decision)
  end


end
