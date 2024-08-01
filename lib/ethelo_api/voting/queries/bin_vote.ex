defmodule EtheloApi.Voting.Queries.BinVote do
  @moduledoc """
  Contains methods that will be delegated to inside EtheloApi.Voting.
  Used purely to reduce the size of voting.ex
  """

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.EctoHelper

  alias EtheloApi.Repo
  alias EtheloApi.Voting
  alias EtheloApi.Voting.BinVote
  alias EtheloApi.Structure.Decision

  def valid_filters() do
    [:participant_id, :option_id, :criteria_id, :id]
  end

  @doc """
  Returns the list of BinVotes for a Decision.

  ## Examples

      iex> list_bin_votes(decision_id)
      [%BinVote{}, ...]
  """
  def list_bin_votes(decision, modifiers \\ %{})

  def list_bin_votes(%Decision{} = decision, modifiers),
    do: list_bin_votes(decision.id, modifiers)

  def list_bin_votes(nil, _), do: raise(ArgumentError, message: "you must supply a Decision")

  def list_bin_votes(decision_id, modifiers) do
    BinVote
    |> where([t], t.decision_id == ^decision_id)
    |> filter_query(modifiers, valid_filters())
    |> Repo.all()
  end

  @doc """
  Returns the list of matching BinVotes for a list of Decision ids
  Used for batch processing

  ## Examples

      iex> match_bin_votes(modifiers, decision_ids)
      [%BinVote{}, ...]

  """
  def match_bin_votes(modifiers \\ %{}, decision_ids)

  def match_bin_votes(modifiers, decision_ids) when is_list(decision_ids) do
    decision_ids = Enum.uniq(decision_ids)

    BinVote
    |> where([t], t.decision_id in ^decision_ids)
    |> filter_query(modifiers, valid_filters())
    |> Repo.all()
  end

  def match_bin_votes(_, nil),
    do: raise(ArgumentError, message: "you must supply a list of Decision ids")

  def match_one_bin_vote(modifiers \\ %{}, decision_id) do
    BinVote
    |> where([t], t.decision_id == ^decision_id)
    |> filter_query(modifiers, valid_filters())
    |> Repo.one()
  end

  @doc """
  Gets a single BinVote.

  returns nil if BinVote does not exist or does not belong to the specified Decision

  ## Examples

      iex> get_bin_vote(123, 1)
      %BinVote{}

      iex> get_bin_vote(456, 3)
      nil

  """
  def get_bin_vote(id, %Decision{} = decision), do: get_bin_vote(id, decision.id)
  def get_bin_vote(_, nil), do: raise(ArgumentError, message: "you must supply a Decision id")
  def get_bin_vote(nil, _), do: raise(ArgumentError, message: "you must supply an BinVote id")

  def get_bin_vote(id, decision_id) do
    BinVote |> Repo.get_by(id: id, decision_id: decision_id)
  end

  @doc """
  Generate counts by date interval for BinVotes
  """
  def bin_vote_activity(decision, interval \\ "day", modifiers \\ %{})

  def bin_vote_activity(%Decision{} = decision, interval, modifiers),
    do: bin_vote_activity(decision.id, interval, modifiers)

  def bin_vote_activity(nil, _, _),
    do: raise(ArgumentError, message: "you must supply a Decision")

  def bin_vote_activity(decision_id, interval, modifiers)
      when interval in ["year", "month", "week", "day"] do
    EtheloApi.Voting.BinVote
    |> where([v], v.decision_id == ^decision_id)
    |> filter_query(modifiers, valid_filters())
    |> select([v], %{id: v.participant_id, datetime: max(v.inserted_at)})
    |> group_by([v], [v.participant_id])
    |> subquery
    |> count_by_date(interval)
  end

  def bin_vote_activity(_, _, _),
    do:
      raise(ArgumentError, message: "you must supply a date interval ( year, month, week, day )")

  @doc """
  Upserts a BinVote.

  ## Examples

      iex> upsert_bin_vote( %{bin: 1, criteria_id: 1, option_id: 1, participant_id: 1, }, decision)
      {:ok, %BinVote{}}

      iex> upsert_bin_vote( %{bin: "z"}, decision)
      {:error, %Ecto.Changeset{}}

  """
  def upsert_bin_vote(%{} = attrs, %Decision{} = decision) do
    attrs
    |> BinVote.create_changeset(decision)
    |> Repo.insert(
      on_conflict: {:replace, [:bin, :updated_at]},
      conflict_target: [:criteria_id, :participant_id, :option_id],
      returning: true
    )
    |> Voting.maybe_update_influent_hash(attrs, decision.id)
  end

  def upsert_bin_vote(_, _), do: raise(ArgumentError, message: "you must supply a Decision")

  @doc """
  Deletes a BinVote.

  ## Examples

      iex> delete_bin_vote(bin_vote, decision_id)
      {:ok, %BinVote{}}

      iex> delete_bin_vote(bin_vote, decision_id)
      {:ok, nil}

      iex> delete_bin_vote(%{particiant_id: 1, option_id: 1, criteria_id: 2}, decision_id)
      {:ok, %BinVote{}}
  """
  @spec delete_bin_vote(
          map() | integer | BinVote.t(),
          map() | integer | Decision.t()
        ) :: {atom, nil | BinVote.t()}
  def delete_bin_vote(id, %Decision{id: decision_id}),
    do: delete_bin_vote(id, decision_id)

  def delete_bin_vote(%BinVote{id: id}, decision_id),
    do: do_delete(%{id: id}, decision_id)

  def delete_bin_vote(_, nil),
    do: raise(ArgumentError, message: "you must supply a Decision id")

  def delete_bin_vote(nil, _),
    do: raise_invalid_delete()

  def delete_bin_vote(
        %{participant_id: nil},
        _decision_id
      ),
      do: raise_invalid_delete()

  def delete_bin_vote(
        %{criteria_id: nil},
        _decision_id
      ),
      do: raise_invalid_delete()

  def delete_bin_vote(
        %{option_id: nil},
        _decision_id
      ),
      do: raise_invalid_delete()

  def delete_bin_vote(
        %{participant_id: _, criteria_id: _, option_id: _} = modifiers,
        decision_id
      ),
      do: do_delete(modifiers, decision_id)

  defp do_delete(modifiers, decision_id) do
    match_one_bin_vote(modifiers, decision_id)
    |> case do
      nil ->
        {:ok, nil}

      bin_vote ->
        Repo.delete(bin_vote)
        |> Voting.maybe_update_influent_hash(bin_vote, decision_id)
    end
  end

  defp raise_invalid_delete,
    do:
      raise(ArgumentError, message: "you must supply a BinVote id  or a map with unique fields ")
end
