defmodule EtheloApi.Voting.Queries.OptionCategoryBinVote do
  @moduledoc """
  Contains methods that will be delegated to inside EtheloApi.Voting.
  Used purely to reduce the size of voting.ex
  """

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.QueryHelper

  alias EtheloApi.Repo
  alias EtheloApi.Voting
  alias EtheloApi.Voting.OptionCategoryBinVote
  alias EtheloApi.Structure.Decision

  @doc """
  private method to start querying with acceptable preloads
  """
  def base_query() do
    OptionCategoryBinVote |> preload([:decision, :participant, :option_category, :criteria])
  end

  def valid_filters() do
    [:participant_id, :option_category_id, :criteria_id]
  end

  @doc """
  Returns the list of OptionCategoryBinVotes for a Decision.

  ## Examples

      iex> list_option_category_bin_votes(decision_id)
      [%OptionCategoryBinVote{}, ...]

  """
  def list_option_category_bin_votes(decision, filters \\ %{})
  def list_option_category_bin_votes(%Decision{} = decision, filters), do: list_option_category_bin_votes(decision.id, filters)
  def list_option_category_bin_votes(nil, _), do: raise ArgumentError, message: "you must supply a Decision"
  def list_option_category_bin_votes(decision_id, filters) do
    base_query()
    |> where([t], t.decision_id == ^decision_id)
    |> filter_query(filters, valid_filters())
    |> Repo.all
  end

  @doc """
  Returns the list of matching OptionCategoryBinVotes for a Decision.
  Used for batch processing

  ## Examples

      iex> match_option_category_bin_votes(filters, decision_id)
      [%OptionCategoryBinVote{}, ...]

  """
  def match_option_category_bin_votes(filters \\ %{}, decision_ids)
  def match_option_category_bin_votes(filters, decision_ids) when is_list(decision_ids) do
    decision_ids = Enum.uniq(decision_ids)
    OptionCategoryBinVote
    |> where([t], t.decision_id in ^decision_ids)
    |> filter_query(filters, valid_filters())
    |> Repo.all
  end
  def match_option_category_bin_votes(_, nil), do: raise ArgumentError, message: "you must supply a list of Decision ids"


  @doc """
  Generate a date histogram for the votes in a decision
  """
  def option_category_bin_votes_histogram(decision, type \\ "day", filters \\ %{})
  def option_category_bin_votes_histogram(%Decision{} = decision, type, filters), do: option_category_bin_votes_histogram(decision.id, type, filters)
  def option_category_bin_votes_histogram(nil, _, _), do: raise ArgumentError, message: "you must supply a Decision"
  def option_category_bin_votes_histogram(decision_id, type, filters) when type in ["year", "month", "week", "day"] do
    dates_query = EtheloApi.Voting.OptionCategoryBinVote
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
  Gets a single option_category_bin_vote.

  returns nil if OptionCategoryBinVote does not exist or does not belong to the specified Decision

  ## Examples

      iex> get_option_category_bin_vote(123, 1)
      %OptionCategoryBinVote{}

      iex> get_option_category_bin_vote(456, 3)
      nil

  """
  def get_option_category_bin_vote(id, %Decision{} = decision), do: get_option_category_bin_vote(id, decision.id)
  def get_option_category_bin_vote(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def get_option_category_bin_vote(nil, _), do:  raise ArgumentError, message: "you must supply an OptionCategoryBinVote id"
  def get_option_category_bin_vote(id, decision_id) do
    base_query() |> Repo.get_by(id: id, decision_id: decision_id)
  end

  @doc """
  Creates an option_category_bin_vote.

  ## Examples

      iex> upsert_option_category_bin_vote(decision, %{title: "This is my title"})
      {:ok, %OptionCategoryBinVote{}}

      iex> upsert_option_category_bin_vote(decision, %{title: " "})
      {:error, %Ecto.Changeset{}}

  """
  def upsert_option_category_bin_vote(decision, attrs)
  def upsert_option_category_bin_vote(%Decision{} = decision, %{} = attrs) do
    %OptionCategoryBinVote{}
    |> OptionCategoryBinVote.create_changeset(attrs, decision)
    |> Repo.insert([upsert: true] |> handle_conflicts([:criteria_id, :participant_id, :option_category_id]))
    |> Voting.maybe_update_voting_hashes(attrs, decision.id, :influent)
  end
  def upsert_option_category_bin_vote(_, _), do: raise ArgumentError, message: "you must supply a Decision"

  @doc """
  Deletes a OptionCategoryBinVote.

  ## Examples

      iex> delete_option_category_bin_vote(option_category_bin_vote, decision_id)
      {:ok, %OptionCategoryBinVote{}, decision_id}

  """
  def delete_option_category_bin_vote(id, %Decision{} = decision), do: delete_option_category_bin_vote(id, decision.id)
  def delete_option_category_bin_vote(%OptionCategoryBinVote{} = option_category_bin_vote, decision_id), do: delete_option_category_bin_vote(option_category_bin_vote.id, decision_id)
  def delete_option_category_bin_vote(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def delete_option_category_bin_vote(nil, _), do:  raise ArgumentError, message: "you must supply an OptionCategoryBinVote id"
  def delete_option_category_bin_vote(id, decision_id) do
    id
    |> get_option_category_bin_vote(decision_id)
    |> case do
      nil -> {:ok, nil}
      option_category_bin_vote ->
        Repo.delete(option_category_bin_vote)
        |> Voting.maybe_update_voting_hashes(option_category_bin_vote, decision_id, :influent)

    end
  end

end
