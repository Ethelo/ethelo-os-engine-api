defmodule EtheloApi.Voting.Queries.CriteriaWeight do
  @moduledoc """
  Contains methods that will be delegated to inside EtheloApi.Voting.
  Used purely to reduce the size of voting.ex
  """

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.EctoHelper

  alias EtheloApi.Repo
  alias EtheloApi.Voting.CriteriaWeight
  alias EtheloApi.Voting
  alias EtheloApi.Structure.Decision

  def valid_filters() do
    [:participant_id, :criteria_id, :id]
  end

  @doc """
  Returns the list of CriteriaWeights for a Decision.

  ## Examples

      iex> list_criteria_weights(decision_id)
      [%CriteriaWeight{}, ...]

  """
  def list_criteria_weights(decision, modifiers \\ %{})

  def list_criteria_weights(%Decision{} = decision, modifiers),
    do: list_criteria_weights(decision.id, modifiers)

  def list_criteria_weights(nil, _),
    do: raise(ArgumentError, message: "you must supply a Decision")

  def list_criteria_weights(decision_id, modifiers) do
    CriteriaWeight
    |> where([t], t.decision_id == ^decision_id)
    |> filter_query(modifiers, valid_filters())
    |> Repo.all()
  end

  def match_one_criteria_weight(modifiers \\ %{}, decision_id) do
    CriteriaWeight
    |> where([t], t.decision_id == ^decision_id)
    |> filter_query(modifiers, valid_filters())
    |> Repo.one()
  end

  @doc """
  Gets a single CriteriaWeight.

  returns nil if CriteriaWeight does not exist or does not belong to the specified Decision

  ## Examples

      iex> get_criteria_weight(123, 1)
      %CriteriaWeight{}

      iex> get_criteria_weight(456, 3)
      nil

  """
  def get_criteria_weight(id, %Decision{} = decision), do: get_criteria_weight(id, decision.id)

  def get_criteria_weight(_, nil),
    do: raise(ArgumentError, message: "you must supply a Decision id")

  def get_criteria_weight(nil, _),
    do: raise(ArgumentError, message: "you must supply a CriteriaWeight id")

  def get_criteria_weight(id, decision_id) do
    CriteriaWeight |> Repo.get_by(id: id, decision_id: decision_id)
  end

  @doc """
  Upserts a CriteriaWeight.

  ## Examples

      iex> upsert_criteria_weight( %{weighting: 43, criteria_id: 1, participant_id: 1}, decision)
      {:ok, %CriteriaWeight{}}

      iex> upsert_criteria_weight( %{weighting: " "}, decision)
      {:error, %Ecto.Changeset{}}

  """
  def upsert_criteria_weight(%{} = attrs, %Decision{} = decision) do
    attrs
    |> CriteriaWeight.create_changeset(decision)
    |> Repo.insert(
      on_conflict: {:replace, [:weighting, :updated_at]},
      conflict_target: [:criteria_id, :participant_id],
      returning: true
    )
    |> Voting.maybe_update_influent_hash(attrs, decision.id)
  end

  def upsert_criteria_weight(_, _),
    do: raise(ArgumentError, message: "you must supply a Decision")

  @doc """
  Deletes a CriteriaWeight.

  ## Examples

      iex> delete_criteria_weight(criteria_weight, decision_id)
      {:ok, %CriteriaWeight{}}

      iex> delete_criteria_weight(criteria_weight, decision_id)
      {:ok, nil}

      iex> delete_criteria_weight(%{particiant_id: 1, criteria_id: 2}, decision_id)
      {:ok, %CriteriaWeight{}}

  """
  @spec delete_criteria_weight(
          map() | integer | CriteriaWeight.t(),
          map() | integer | Decision.t()
        ) :: {atom, nil | CriteriaWeight.t()}

  def delete_criteria_weight(id, %Decision{id: decision_id}),
    do: delete_criteria_weight(id, decision_id)

  def delete_criteria_weight(%CriteriaWeight{id: id}, decision_id),
    do: do_delete(%{id: id}, decision_id)

  def delete_criteria_weight(_, nil),
    do: raise(ArgumentError, message: "you must supply a Decision id")

  def delete_criteria_weight(nil, _),
    do: raise_invalid_delete()

  def delete_criteria_weight(
        %{participant_id: nil},
        _decision_id
      ),
      do: raise_invalid_delete()

  def delete_criteria_weight(
        %{criteria_id: nil},
        _decision_id
      ),
      do: raise_invalid_delete()

  def delete_criteria_weight(
        %{participant_id: _, criteria_id: _} = modifiers,
        decision_id
      ),
      do: do_delete(modifiers, decision_id)

  defp do_delete(modifiers, decision_id) do
    match_one_criteria_weight(modifiers, decision_id)
    |> case do
      nil ->
        {:ok, nil}

      criteria_weight ->
        Repo.delete(criteria_weight)
        |> Voting.maybe_update_influent_hash(criteria_weight, decision_id)
    end
  end

  defp raise_invalid_delete,
    do:
      raise(ArgumentError,
        message: "you must supply a CriteriaWeight id  or a map with unique fields "
      )
end
