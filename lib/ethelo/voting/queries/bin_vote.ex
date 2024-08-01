defmodule EtheloApi.Voting.Queries.BinVote do
  @moduledoc """
  Contains methods that will be delegated to inside EtheloApi.Voting.
  Used purely to reduce the size of voting.ex
  """

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.QueryHelper

  alias EtheloApi.Repo
  alias EtheloApi.Voting
  alias EtheloApi.Voting.BinVote
  alias EtheloApi.Structure.Decision

  @doc """
  private method to start querying with acceptable preloads
  """
  def base_query() do
    BinVote |> preload([:decision, :participant, :option, :criteria])
  end

  def valid_filters() do
    [:participant_id, :option_id, :criteria_id, :id]
  end

  @doc """
  Returns the list of BinVotes for a Decision.

  ## Examples

      iex> list_bin_votes(decision_id)
      [%BinVote{}, ...]
  """
  def list_bin_votes(decision, filters \\ %{})
  def list_bin_votes(%Decision{} = decision, filters), do: list_bin_votes(decision.id, filters)
  def list_bin_votes(nil, _), do: raise ArgumentError, message: "you must supply a Decision"
  def list_bin_votes(decision_id, filters) do
    base_query()
    |> where([t], t.decision_id == ^decision_id)
    |> filter_query(filters, valid_filters())
    |> Repo.all
  end

  @doc """
  Returns the list of matching BinVotes for a Decision.
  Used for batch processing

  ## Examples

      iex> match_bin_votes(filters, decision_id)
      [%BinVote{}, ...]

  """
  def match_bin_votes(filters \\ %{}, decision_ids)
  def match_bin_votes(filters, decision_ids) when is_list(decision_ids) do
    decision_ids = Enum.uniq(decision_ids)
    BinVote
    |> where([t], t.decision_id in ^decision_ids)
    |> filter_query(filters, valid_filters())
    |> Repo.all
  end
  def match_bin_votes(_, nil), do: raise ArgumentError, message: "you must supply a list of Decision ids"


  @doc """
  Generate a date histogram for the votes in a decision
  """
  def bin_votes_histogram(decision, type \\ "day", filters \\ %{})
  def bin_votes_histogram(%Decision{} = decision, type, filters), do: bin_votes_histogram(decision.id, type, filters)
  def bin_votes_histogram(nil, _, _), do: raise ArgumentError, message: "you must supply a Decision"
  def bin_votes_histogram(decision_id, type, filters) when type in ["year", "month", "week", "day"] do
    dates_query = EtheloApi.Voting.BinVote
      |> where([v], v.decision_id == ^decision_id)
      |> filter_query(filters, valid_filters())
      |> select([v], %{id: v.participant_id, datetime: max(v.inserted_at)})
      |> group_by([v], [v.participant_id])
      |> subquery

    dates_query
      |> select([v], %{datetime: fragment("date_trunc(?, ? AT TIME ZONE 'UTC') as truncated_date", ^type, v.datetime), count: count("*")})
      |> group_by([v], [fragment("truncated_date")])
      |> EtheloApi.Repo.all
      |> Enum.map(fn(x = %{datetime: {{year, month, day}, {hh, mm, ss, _}}}) ->
        %{x | datetime: NaiveDateTime.from_erl!({{year, month, day}, {hh, mm, ss}}) |> DateTime.from_naive!("Etc/UTC")}
      end)
  end

  @doc """
  Gets a single bin_vote.

  returns nil if BinVote does not exist or does not belong to the specified Decision

  ## Examples

      iex> get_bin_vote(123, 1)
      %BinVote{}

      iex> get_bin_vote(456, 3)
      nil

  """
  def get_bin_vote(id, %Decision{} = decision), do: get_bin_vote(id, decision.id)
  def get_bin_vote(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def get_bin_vote(nil, _), do:  raise ArgumentError, message: "you must supply an BinVote id"
  def get_bin_vote(id, decision_id) do
    base_query() |> Repo.get_by(id: id, decision_id: decision_id)
  end

  @doc """
  Creates an bin_vote.

  ## Examples

      iex> upsert_bin_vote(decision, %{title: "This is my title"})
      {:ok, %BinVote{}}

      iex> upsert_bin_vote(decision, %{title: " "})
      {:error, %Ecto.Changeset{}}

  """
  def upsert_bin_vote(decision, attrs)
  def upsert_bin_vote(%Decision{} = decision, %{} = attrs) do
    %BinVote{}
    |> BinVote.create_changeset(attrs, decision)
    |> Repo.insert([upsert: true] |> handle_conflicts([:criteria_id, :participant_id, :option_id]))
    |> Voting.maybe_update_voting_hashes(attrs, decision.id, :influent)

  end
  def upsert_bin_vote(_, _), do: raise ArgumentError, message: "you must supply a Decision"

  @doc """
  Deletes a BinVote.

  ## Examples

      iex> delete_bin_vote(bin_vote, decision_id)
      {:ok, %BinVote{}, decision_id}

  """
  def delete_bin_vote(id, %Decision{} = decision), do: delete_bin_vote(id, decision.id)
  def delete_bin_vote(%BinVote{} = bin_vote, decision_id), do: delete_bin_vote(bin_vote.id, decision_id)
  def delete_bin_vote(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def delete_bin_vote(nil, _), do:  raise ArgumentError, message: "you must supply an BinVote id"
  def delete_bin_vote(id, decision_id) do
    id
    |> get_bin_vote(decision_id)
    |> case do
      nil -> {:ok, nil}
      bin_vote ->
        Repo.delete(bin_vote)
        |> Voting.maybe_update_voting_hashes(bin_vote, decision_id, :influent)
    end
  end

end
