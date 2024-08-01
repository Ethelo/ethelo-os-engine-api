defmodule EtheloApi.Voting.Queries.OptionCategoryBinVote do
  @moduledoc """
  Contains methods that will be delegated to inside EtheloApi.Voting.
  Used purely to reduce the size of voting.ex
  """

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.EctoHelper

  alias EtheloApi.Repo
  alias EtheloApi.Voting.OptionCategoryBinVote
  alias EtheloApi.Voting
  alias EtheloApi.Structure.Decision

  def valid_filters() do
    [:participant_id, :option_category_id, :criteria_id, :id]
  end

  @doc """
  Returns the list of OptionCategoryBinVotes for a Decision.

  ## Examples

      iex> list_option_category_bin_votes(decision_id)
      [%OptionCategoryBinVote{}, ...]

  """
  def list_option_category_bin_votes(decision, modifiers \\ %{})

  def list_option_category_bin_votes(%Decision{} = decision, modifiers),
    do: list_option_category_bin_votes(decision.id, modifiers)

  def list_option_category_bin_votes(nil, _),
    do: raise(ArgumentError, message: "you must supply a Decision")

  def list_option_category_bin_votes(decision_id, modifiers) do
    OptionCategoryBinVote
    |> where([t], t.decision_id == ^decision_id)
    |> filter_query(modifiers, valid_filters())
    |> Repo.all()
  end

  def match_one_option_category_bin_vote(modifiers \\ %{}, decision_id) do
    OptionCategoryBinVote
    |> where([t], t.decision_id == ^decision_id)
    |> filter_query(modifiers, valid_filters())
    |> Repo.one()
  end

  @doc """
  Generate counts by date interval for OptionCategoryBinVotes
  """
  def option_category_bin_vote_activity(decision, interval \\ "day", modifiers \\ %{})

  def option_category_bin_vote_activity(%Decision{} = decision, interval, modifiers),
    do: option_category_bin_vote_activity(decision.id, interval, modifiers)

  def option_category_bin_vote_activity(nil, _, _),
    do: raise(ArgumentError, message: "you must supply a Decision")

  def option_category_bin_vote_activity(decision_id, interval, modifiers)
      when interval in ["year", "month", "week", "day"] do
    EtheloApi.Voting.OptionCategoryBinVote
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
  Gets a single OptionCategoryBinVote.

  returns nil if OptionCategoryBinVote does not exist or does not belong to the specified Decision

  ## Examples

      iex> get_option_category_bin_vote(123, 1)
      %OptionCategoryBinVote{}

      iex> get_option_category_bin_vote(456, 3)
      nil

  """
  def get_option_category_bin_vote(id, %Decision{} = decision),
    do: get_option_category_bin_vote(id, decision.id)

  def get_option_category_bin_vote(_, nil),
    do: raise(ArgumentError, message: "you must supply a Decision id")

  def get_option_category_bin_vote(nil, _),
    do: raise(ArgumentError, message: "you must supply an OptionCategoryBinVote id")

  def get_option_category_bin_vote(id, decision_id) do
    OptionCategoryBinVote |> Repo.get_by(id: id, decision_id: decision_id)
  end

  @doc """
  Upserts an OptionCategoryBinVote.

  ## Examples

      iex> upsert_option_category_bin_vote( %{bin: 5, criteria_id: 1, option_category_id: 1, participant_id: 1}, decision)
      {:ok, %OptionCategoryBinVote{}}

      iex> upsert_option_category_bin_vote( %{bin: " "}, decision)
      {:error, %Ecto.Changeset{}}

  """

  def upsert_option_category_bin_vote(%{} = attrs, %Decision{} = decision) do
    attrs
    |> OptionCategoryBinVote.create_changeset(decision)
    |> Repo.insert(
      on_conflict: {:replace, [:bin, :updated_at]},
      conflict_target: [:criteria_id, :option_category_id, :participant_id],
      returning: true
    )
    |> Voting.maybe_update_influent_hash(attrs, decision.id)
  end

  def upsert_option_category_bin_vote(_, _),
    do: raise(ArgumentError, message: "you must supply a Decision")

  @doc """
  Deletes a OptionCategoryBinVote.

  ## Examples

      iex> delete_option_category_bin_vote(option_category_bin_vote, decision_id)
      {:ok, %OptionCategoryBinVote{}}

      iex> delete_option_category_bin_vote(option_category_bin_vote, decision_id)
      {:ok, nil}

      iex> delete_option_category_bin_vote(%{particiant_id: 1, option_category_id: 1, criteria_id: 2}, decision_id)
      {:ok, %OptionCategoryBinVote{}}

  """
  @spec delete_option_category_bin_vote(
          map() | integer | OptionCategoryBinVote.t(),
          map() | integer | Decision.t()
        ) :: {atom, nil | OptionCategoryBinVote.t()}

  def delete_option_category_bin_vote(id, %Decision{id: decision_id}),
    do: delete_option_category_bin_vote(id, decision_id)

  def delete_option_category_bin_vote(%OptionCategoryBinVote{id: id}, decision_id),
    do: do_delete(%{id: id}, decision_id)

  def delete_option_category_bin_vote(_, nil),
    do: raise(ArgumentError, message: "you must supply a Decision id")

  def delete_option_category_bin_vote(nil, _),
    do: raise_invalid_delete()

  def delete_option_category_bin_vote(
        %{participant_id: nil},
        _decision_id
      ),
      do: raise_invalid_delete()

  def delete_option_category_bin_vote(
        %{criteria_id: nil},
        _decision_id
      ),
      do: raise_invalid_delete()

  def delete_option_category_bin_vote(
        %{option_category_id: nil},
        _decision_id
      ),
      do: raise_invalid_delete()

  def delete_option_category_bin_vote(
        %{participant_id: _, criteria_id: _, option_category_id: _} = modifiers,
        decision_id
      ),
      do: do_delete(modifiers, decision_id)

  defp do_delete(modifiers, decision_id) do
    match_one_option_category_bin_vote(modifiers, decision_id)
    |> case do
      nil ->
        {:ok, nil}

      option_category_bin_vote ->
        Repo.delete(option_category_bin_vote)
        |> Voting.maybe_update_influent_hash(option_category_bin_vote, decision_id)
    end
  end

  defp raise_invalid_delete,
    do:
      raise(ArgumentError,
        message: "you must supply an OptionCategoryBinVote id  or a map with unique fields "
      )
end
