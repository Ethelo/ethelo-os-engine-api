defmodule EtheloApi.Voting.Queries.OptionCategoryRangeVote do
  @moduledoc """
  Contains methods that will be delegated to inside EtheloApi.Voting.
  Used purely to reduce the size of voting.ex
  """

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.EctoHelper

  alias EtheloApi.Repo
  alias EtheloApi.Voting.OptionCategoryRangeVote
  alias EtheloApi.Voting
  alias EtheloApi.Structure.Decision

  def valid_filters() do
    [:participant_id, :option_category_id, :low_option_id, :high_option_id, :id]
  end

  @doc """
  Returns the list of OptionCategoryRangeVotes for a Decision.

  ## Examples

      iex> list_option_category_range_votes(decision_id)
      [%OptionCategoryRangeVote{}, ...]

  """
  def list_option_category_range_votes(decision, modifiers \\ %{})

  def list_option_category_range_votes(%Decision{} = decision, modifiers),
    do: list_option_category_range_votes(decision.id, modifiers)

  def list_option_category_range_votes(nil, _),
    do: raise(ArgumentError, message: "you must supply a Decision")

  def list_option_category_range_votes(decision_id, modifiers) do
    OptionCategoryRangeVote
    |> where([t], t.decision_id == ^decision_id)
    |> filter_query(modifiers, valid_filters())
    |> Repo.all()
  end

  def match_one_option_category_range_vote(modifiers \\ %{}, decision_id) do
    OptionCategoryRangeVote
    |> where([t], t.decision_id == ^decision_id)
    |> filter_query(modifiers, valid_filters())
    |> Repo.one()
  end

  @doc """
  Generate counts by date interval for OptionCategoryRangeVotes
  """
  def option_category_range_vote_activity(decision, interval \\ "day", modifiers \\ %{})

  def option_category_range_vote_activity(%Decision{} = decision, interval, modifiers),
    do: option_category_range_vote_activity(decision.id, interval, modifiers)

  def option_category_range_vote_activity(nil, _, _),
    do: raise(ArgumentError, message: "you must supply a Decision")

  def option_category_range_vote_activity(decision_id, interval, modifiers)
      when interval in ["year", "month", "week", "day"] do
    EtheloApi.Voting.OptionCategoryRangeVote
    |> where([v], v.decision_id == ^decision_id)
    |> filter_query(modifiers, valid_filters())
    |> select([v], %{id: v.participant_id, datetime: max(v.inserted_at)})
    |> group_by([v], [v.participant_id])
    |> subquery
    |> count_by_date(interval)
  end

  def option_category_bin_vote_activity(_, _, _),
    do:
      raise(ArgumentError, message: "you must supply a date interval ( year, month, week, day )")

  @doc """
  Gets a single OptionCategoryRangeVote.

  returns nil if OptionCategoryRangeVote does not exist or does not belong to the specified Decision

  ## Examples

      iex> get_option_category_range_vote(123, 1)
      %OptionCategoryRangeVote{}

      iex> get_option_category_range_vote(456, 3)
      nil

  """
  def get_option_category_range_vote(id, %Decision{} = decision),
    do: get_option_category_range_vote(id, decision.id)

  def get_option_category_range_vote(_, nil),
    do: raise(ArgumentError, message: "you must supply a Decision id")

  def get_option_category_range_vote(nil, _),
    do: raise(ArgumentError, message: "you must supply an OptionCategoryRangeVote id")

  def get_option_category_range_vote(id, decision_id) do
    OptionCategoryRangeVote |> Repo.get_by(id: id, decision_id: decision_id)
  end

  @doc """
  Upserts an OptionCategoryRangeVote.

  ## Examples

      iex> upsert_option_category_range_vote( %{participant_id: 1, low_option_id:1, high_option_id: 2, option_category_id: 1}, decision)
      {:ok, %OptionCategoryRangeVote{}}

      iex> upsert_option_category_range_vote( %{participant_id: " "}, decision)
      {:error, %Ecto.Changeset{}}

  """

  def upsert_option_category_range_vote(%{} = attrs, %Decision{} = decision) do
    attrs
    |> OptionCategoryRangeVote.create_changeset(decision)
    |> Repo.insert(
      on_conflict: {:replace, [:low_option_id, :high_option_id, :updated_at]},
      conflict_target: [:option_category_id, :participant_id],
      returning: true
    )
    |> Voting.maybe_update_influent_hash(attrs, decision.id)
  end

  def upsert_option_category_range_vote(_, _),
    do: raise(ArgumentError, message: "you must supply a Decision")

  @doc """
  Deletes an OptionCategoryRangeVote.

  ## Examples

      iex> delete_option_category_range_vote(option_category_range_vote, decision_id)
      {:ok, %OptionCategoryRangeVote{}}

      iex> delete_option_category_range_vote(option_category_range_vote, decision_id)
      {:ok, nil}
      iex> delete_option_category_range_vote(%{particiant_id: 1, option_category_id: 2}, decision_id)
      {:ok, %OptionCategoryRangeVote{}}
  """
  @spec delete_option_category_range_vote(
          map() | integer | OptionCategoryRangeVote.t(),
          map() | integer | Decision.t()
        ) :: {atom, nil | OptionCategoryRangeVote.t()}

  def delete_option_category_range_vote(id, %Decision{id: decision_id}),
    do: delete_option_category_range_vote(id, decision_id)

  def delete_option_category_range_vote(%OptionCategoryRangeVote{id: id}, decision_id),
    do: do_delete(%{id: id}, decision_id)

  def delete_option_category_range_vote(_, nil),
    do: raise(ArgumentError, message: "you must supply a Decision id")

  def delete_option_category_range_vote(nil, _),
    do: raise_invalid_delete()

  def delete_option_category_range_vote(
        %{participant_id: nil},
        _decision_id
      ),
      do: raise_invalid_delete()

  def delete_option_category_range_vote(
        %{option_category_id: nil},
        _decision_id
      ),
      do: raise_invalid_delete()

  def delete_option_category_range_vote(
        %{participant_id: _, option_category_id: _} = modifiers,
        decision_id
      ),
      do: do_delete(modifiers, decision_id)

  defp do_delete(modifiers, decision_id) do
    match_one_option_category_range_vote(modifiers, decision_id)
    |> case do
      nil ->
        {:ok, nil}

      option_category_range_vote ->
        Repo.delete(option_category_range_vote)
        |> Voting.maybe_update_influent_hash(option_category_range_vote, decision_id)
    end
  end

  defp raise_invalid_delete,
    do:
      raise(ArgumentError,
        message: "you must supply a OptionCategoryRangeVote id  or a map with unique fields "
      )
end
