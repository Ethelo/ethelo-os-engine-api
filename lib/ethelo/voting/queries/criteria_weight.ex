defmodule EtheloApi.Voting.Queries.CriteriaWeight do
  @moduledoc """
  Contains methods that will be delegated to inside EtheloApi.Voting.
  Used purely to reduce the size of voting.ex
  """

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.QueryHelper

  alias EtheloApi.Repo
  alias EtheloApi.Voting.CriteriaWeight
  alias EtheloApi.Voting
  alias EtheloApi.Structure.Decision

  @doc """
  private method to start querying with acceptable preloads
  """
  def base_query() do
    CriteriaWeight |> preload([:decision, :participant, :criteria])
  end

  def valid_filters() do
    [:participant_id, :criteria_id]
  end

  @doc """
  Returns the list of CriteriaWeights for a Decision.

  ## Examples

      iex> list_criteria_weights(decision_id)
      [%CriteriaWeight{}, ...]

  """
  def list_criteria_weights(decision, filters \\ %{})
  def list_criteria_weights(%Decision{} = decision, filters), do: list_criteria_weights(decision.id, filters)
  def list_criteria_weights(nil, _), do: raise ArgumentError, message: "you must supply a Decision"
  def list_criteria_weights(decision_id, filters) do
    base_query()
    |> where([t], t.decision_id == ^decision_id)
    |> filter_query(filters, valid_filters())
    |> Repo.all
  end

  @doc """
  Returns the list of matching CriteriaWeights for a Decision.
  Used for batch processing

  ## Examples

      iex> match_criteria_weights(filters, decision_id)
      [%CriteriaWeight{}, ...]

  """
  def match_criteria_weights(filters \\ %{}, decision_ids)
  def match_criteria_weights(filters, decision_ids) when is_list(decision_ids) do
    decision_ids = Enum.uniq(decision_ids)
    CriteriaWeight
    |> where([t], t.decision_id in ^decision_ids)
    |> filter_query(filters, valid_filters())
    |> Repo.all
  end
  def match_criteria_weights(_, nil), do: raise ArgumentError, message: "you must supply a list of Decision ids"


  @doc """
  Gets a single criteria_weight.

  returns nil if CriteriaWeight does not exist or does not belong to the specified Decision

  ## Examples

      iex> get_criteria_weight(123, 1)
      %CriteriaWeight{}

      iex> get_criteria_weight(456, 3)
      nil

  """
  def get_criteria_weight(id, %Decision{} = decision), do: get_criteria_weight(id, decision.id)
  def get_criteria_weight(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def get_criteria_weight(nil, _), do:  raise ArgumentError, message: "you must supply a CriteriaWeight id"
  def get_criteria_weight(id, decision_id) do
    base_query() |> Repo.get_by(id: id, decision_id: decision_id)
  end

  @doc """
  Upserts an criteria_weight.

  ## Examples

      iex> upsert_criteria_weight(decision, %{title: "This is my title"})
      {:ok, %CriteriaWeight{}}

      iex> upsert_criteria_weight(decision, %{title: " "})
      {:error, %Ecto.Changeset{}}

  """
  def upsert_criteria_weight(decision, attrs)
  def upsert_criteria_weight(%Decision{} = decision, %{} = attrs) do
    %CriteriaWeight{}
    |> CriteriaWeight.create_changeset(attrs, decision)
    |> Repo.insert([upsert: true] |> handle_conflicts([:criteria_id, :participant_id]))
    |> Voting.maybe_update_voting_hashes(attrs, decision.id, :weighting)

  end
  def upsert_criteria_weight(_, _), do: raise ArgumentError, message: "you must supply a Decision"


  @doc """
  Deletes a CriteriaWeight.

  ## Examples

      iex> delete_criteria_weight(criteria_weight, decision_id)
      {:ok, %CriteriaWeight{}, decision_id}

  """
  def delete_criteria_weight(id, %Decision{} = decision), do: delete_criteria_weight(id, decision.id)
  def delete_criteria_weight(%CriteriaWeight{} = criteria_weight, decision_id), do: delete_criteria_weight(criteria_weight.id, decision_id)
  def delete_criteria_weight(
  %{participant_id: participant_id, criteria_id: criteria_id},
  decision_id) do
    CriteriaWeight
    |> Repo.get_by(participant_id: participant_id, criteria_id: criteria_id, decision_id: decision_id)
    |> case do
      nil -> {:ok, nil}
      criteria_weight ->
        Repo.delete(criteria_weight)
        |> Voting.maybe_update_voting_hashes(criteria_weight, decision_id, :weighting)
      end
  end
  def delete_criteria_weight(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def delete_criteria_weight(nil, _), do:  raise ArgumentError, message: "you must supply a CriteriaWeight id"
  def delete_criteria_weight(id, decision_id) do
    id
    |> get_criteria_weight(decision_id)
    |> case do
      nil -> {:ok, nil}
      criteria_weight ->
        Repo.delete(criteria_weight)
        |> Voting.maybe_update_voting_hashes(criteria_weight, decision_id, :weighting)

    end
  end
end
