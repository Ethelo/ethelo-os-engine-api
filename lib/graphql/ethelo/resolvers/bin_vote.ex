defmodule GraphQL.EtheloApi.Resolvers.BinVote do
  @moduledoc """
  Resolvers for graphql.
  """

  alias EtheloApi.Voting
  alias EtheloApi.Structure.Decision
  import GraphQL.EtheloApi.ResolveHelper

  @doc """
  lists all BinVotes

  See `EtheloApi.Voting.list_bin_votes/1` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Voting.list_bin_votes(modifiers) |> success()
  end
  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  upserts a BinVote

  See `EtheloApi.Voting.upsert_bin_vote/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def upsert(decision, attrs) do
    if Map.get(attrs, :delete, false) do
      Enum.each(Voting.list_bin_votes(decision, attrs), fn(x) ->
        Voting.delete_bin_vote(x.id, decision)
      end)
      {:ok, nil}
    else
      Voting.upsert_bin_vote(decision, attrs)
    end
  end

  @doc """
  deletes a BinVote.

  See `EtheloApi.Voting.delete_bin_vote/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(decision, %{id: id}) do
    Voting.delete_bin_vote(id, decision)
  end

end
