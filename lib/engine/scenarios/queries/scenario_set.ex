defmodule Engine.Scenarios.Queries.ScenarioSet do
  @moduledoc """
  Contains methods that will be delegated to inside scenario_set.
  Used purely to reduce the size of scenario_set.ex
  """

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.QueryHelper
  import EtheloApi.Helpers.ValidationHelper

  alias EtheloApi.Repo
  alias EtheloApi.Structure.Decision
  alias Engine.Scenarios.ScenarioSet
  alias EtheloApi.Voting.Participant

  def valid_filters() do
    [:id, :decision_id, :participant_id, :status, :hash, :cached_decision]
  end

  def match_query(decision_id, filters) do
    filters = filters |> Map.put(:decision_id, decision_id)
                      |> Map.put_new(:participant_id, nil)

    ScenarioSet
    |> filter_query(filters, valid_filters())
  end

  @doc """
  Returns the list of non-participant ScenarioSets for a Decision.

  ## Examples

      iex> list_scenario_sets(scenario_set_id)
      [%Scenario{}, ...]

  """
  def list_scenario_sets(decision, filters \\ %{})
  def list_scenario_sets(%Decision{} = decision, filters), do: list_scenario_sets(decision.id, filters)
  def list_scenario_sets(nil, _), do: raise ArgumentError, message: "you must supply a Decision"
  def list_scenario_sets(decision_id, filters) do
    decision_id |> match_query(filters) |> order_by(desc: :updated_at, desc: :id)
    |> Repo.all
  end

  @doc """
  Returns the list of ScenarioSets for a Decision and Participant.

  ## Examples

      iex> list_participant_scenario_sets(scenario_set_id)
      [%Scenario{}, ...]

  """
  def list_participant_scenario_sets(decision, participant, filters \\ %{})
  def list_participant_scenario_sets(%Decision{} = decision, %Participant{} = participant, filters), do: list_participant_scenario_sets(decision.id, participant.id, filters)
  def list_participant_scenario_sets(nil, _, _), do: raise ArgumentError, message: "you must supply a Decision"
  def list_participant_scenario_sets(_, nil, _), do: raise ArgumentError, message: "you must supply a Participant"
  def list_participant_scenario_sets(decision_id, participant_id, filters) do
    filters = Map.put(filters, :participant_id, participant_id)
    decision_id |> match_query(filters) |> order_by(desc: :updated_at) |> Repo.all
  end

  @doc """
  Returns the matching ScenarioSets for a list of Decision ids.

  ## Examples

      iex> match_scenario_sets(scenario_set_id)
      [%Option{}, ...]

  """
  def match_scenario_sets(filters \\ %{}, decision_ids)
  def match_scenario_sets(filters, decision_ids) when is_list(decision_ids) do
    decision_ids = Enum.uniq(decision_ids)

    ScenarioSet
    |> where([t], t.decision_id in ^decision_ids)
    |> filter_query(filters, valid_filters())
    |> Repo.all
  end
  def match_scenario_sets(_, nil), do: raise ArgumentError, message: "you must supply a list of Decision ids"


  @doc """
  Gets the latest ScenarioSet

  returns nil if latest ScenarioSet does not exist or does not belong to the specified Decision

  ## Examples

      iex> get_latest_scenario_set(1)
      %ScenarioSet{}

  """
  def get_latest_scenario_set(decision, filters \\ %{})
  def get_latest_scenario_set(%Decision{} = decision, filters), do: get_latest_scenario_set(decision.id, filters)
  def get_latest_scenario_set(nil, _), do: raise ArgumentError, message: "you must supply a Decision id"
  def get_latest_scenario_set(decision_id, filters) do
    decision_id |> match_query(filters) |> order_by(desc: :updated_at) |> limit(1) |> Repo.one
  end

  @doc """
  Gets a single ScenarioSet by id

  returns nil if ScenarioSet does not exist or does not belong to the specified Decision

  ## Examples

      iex> get_scenario_set(123, 1)
      %ScenarioSet{}

      iex> get_scenario_set(456, 3)
      nil

  """
  def get_scenario_set(id, %Decision{} = decision), do: get_scenario_set(id, decision.id)
  def get_scenario_set(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def get_scenario_set(nil, _), do:  raise ArgumentError, message: "you must supply a ScenarioSet id"
  def get_scenario_set(id, decision_id) do
    ScenarioSet |> Repo.get_by(id: id, decision_id: decision_id)
  end

  @doc """
  Touch a single ScenarioSet by id

  Updates the updated_at timestamp for a scenario_set

  """
  def touch_scenario_set(id, %Decision{} = decision), do: touch_scenario_set(id, decision.id)

  def touch_scenario_set(%ScenarioSet{} = scenario_set, decision_id),
    do: touch_scenario_set(scenario_set.id, decision_id)

  def touch_scenario_set(_, nil),
    do: raise(ArgumentError, message: "you must supply a Decision id")

  def touch_scenario_set(nil, _),
    do: raise(ArgumentError, message: "you must supply a ScenarioSet id")

  def touch_scenario_set(id, decision_id) do
    if scenario_set = ScenarioSet |> Repo.get_by(id: id, decision_id: decision_id) do
      ScenarioSet.update_changeset(scenario_set, %{updated_at: Ecto.DateTime.utc()})
      |> Repo.update()
    end
  end

  #   @doc """
  #   Helper to set all running scenario sets to pending so they will no longer be used
  #   """
  #   def disable_pending_scenario_sets(%Decision{} = decision), do: disable_pending_scenario_sets(decision.id)
  #   def disable_pending_scenario_sets(decision_id), do: disable_pending_scenario_sets(decision.id)
  #     list = list_scenario_sets(decision_id, %{status: "pending"})
  #
  #     list |> Enum.map(fn(scenario_set) ->
  #       ScenarioSet.update_changeset(scenario_set, %{status: "error", error: "Manually Stopped"}) |> Repo.update
  #     end)
  #
  # end

  @doc """
  Update the engine start time  of a single ScenarioSet by id

  """
  def set_scenario_set_engine_start(id, %Decision{} = decision),
    do: set_scenario_set_engine_start(id, decision.id)

  def set_scenario_set_engine_start(%ScenarioSet{} = scenario_set, decision_id),
    do: set_scenario_set_engine_start(scenario_set.id, decision_id)

  def set_scenario_set_engine_start(_, nil),
    do: raise(ArgumentError, message: "you must supply a Decision id")

  def set_scenario_set_engine_start(nil, _),
    do: raise(ArgumentError, message: "you must supply a ScenarioSet id")

  def set_scenario_set_engine_start(id, decision_id) do
    if scenario_set = ScenarioSet |> Repo.get_by(id: id, decision_id: decision_id) do
      ScenarioSet.update_changeset(scenario_set, %{engine_start: Ecto.DateTime.utc()})
      |> Repo.update()
    end
  end

  @doc """
  Update the engine end time  of a single ScenarioSet by id

  """
  def set_scenario_set_engine_end(id, %Decision{} = decision), do: set_scenario_set_engine_end(id, decision.id)
  def set_scenario_set_engine_end(%ScenarioSet{} = scenario_set, decision_id), do: set_scenario_set_engine_end(scenario_set.id, decision_id)
  def set_scenario_set_engine_end(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def set_scenario_set_engine_end(nil, _), do:  raise ArgumentError, message: "you must supply a ScenarioSet id"
  def set_scenario_set_engine_end(id, decision_id) do
    if scenario_set = ScenarioSet |> Repo.get_by(id: id, decision_id: decision_id) do
      ScenarioSet.update_changeset(scenario_set, %{engine_end: Ecto.DateTime.utc}) |> Repo.update
    end
  end

  @doc """
  Updates a ScenarioSet with the error state
  """
  def set_scenario_set_error(id, %Decision{} = decision, error), do: set_scenario_set_error(id, decision.id, error)
  def set_scenario_set_error(%ScenarioSet{} = scenario_set, decision_id, error), do: set_scenario_set_error(scenario_set.id, decision_id, error)
  def set_scenario_set_error(_, nil, _), do: raise ArgumentError, message: "you must supply a Decision id"
  def set_scenario_set_error(nil, _, _), do:  raise ArgumentError, message: "you must supply a ScenarioSet id"
  def set_scenario_set_error(id, decision_id, error) do
    if scenario_set = ScenarioSet |> Repo.get_by(id: id, decision_id: decision_id) do
      ScenarioSet.update_changeset(scenario_set, %{updated_at: Ecto.DateTime.utc, status: "error", error: error}) |> Repo.update
    end
  end

  @doc """
  Updates a ScenarioSet.
  Note: this method will not change the Decision a ScenarioSet belongs to.

  ## Examples

      iex> update_scenario_set(scenario_set, %{field: new_value})
      {:ok, %ScenarioSet{}}

      iex> update_scenario_set(scenario_set, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_scenario_set(%ScenarioSet{} = scenario_set, %{} = attrs) do
    scenario_set
    |> ScenarioSet.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Find ScenarioSet or create one.
  """
  def find_or_create_scenario_set(decision, filters, attrs)
  def find_or_create_scenario_set(%Decision{} = decision, filters, attrs), do: find_or_create_scenario_set(decision.id, filters, attrs)
  def find_or_create_scenario_set(nil, _, _), do: raise ArgumentError, message: "you must supply a Decision id"
  def find_or_create_scenario_set(decision_id, filters, attrs) do
    scenario_set = decision_id |> match_query(filters)
                               |> where([s], s.status in ["pending", "success"])
                               |> order_by(desc: :updated_at)
                               |> limit(1) |> Repo.one
    if is_nil(scenario_set) do
      case create_scenario_set(decision_id, attrs) do
        {:ok, scenario_set} ->
          {:ok, {scenario_set, true}}
        error -> error
      end
    else
      {:ok, {scenario_set, false}}
    end
  end

  @doc """
  Creates a ScenarioSet.

  ## Examples

      iex> create_scenario_set(decision, %{status: "This is my status"})
      {:ok, %ScenarioSet{}}

  """
  def create_scenario_set(decision, attrs)
  def create_scenario_set(%Decision{} = decision, attrs), do: create_scenario_set(decision.id, attrs)
  def create_scenario_set(nil, _), do: raise ArgumentError, message: "you must supply a Decision id"
  def create_scenario_set(decision_id, %{} = attrs) do
    %ScenarioSet{}
    |> ScenarioSet.create_changeset(Map.put(attrs, :decision_id, decision_id))
    |> Repo.insert()
  end

  def delete_expired_scenario_sets(%Decision{} = decision), do: delete_expired_scenario_sets(decision.id)
  def delete_expired_scenario_sets(nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def delete_expired_scenario_sets(decision_id) do
    latest_scenario_set = get_latest_scenario_set(decision_id, %{status: "success"})
    delete_expired_scenario_sets(decision_id, latest_scenario_set, "success")
    delete_expired_scenario_sets(decision_id, latest_scenario_set, "error")
  end

  def delete_expired_scenario_sets(_decision_id, nil, _status), do: nil
  def delete_expired_scenario_sets(decision_id, latest_scenario_set, status) do
    ScenarioSet
    |> join(:inner, [s], config in assoc(s, :scenario_config))
    |> where([s], s.status == ^status)
    |> where([s], s.decision_id == ^decision_id)
    |> where([s], s.id != ^latest_scenario_set.id)
    |> where([s, config], config.ttl != 0 and s.inserted_at <= datetime_add(^NaiveDateTime.utc_now, fragment("-(?)", config.ttl), "second"))
    |> Repo.delete_all(timeout: :infinity)
  end

  @doc """
  Deletes a ScenarioSet.

  ## Examples

      iex> delete_scenario_set(scenario_set, decision_id)
      {:ok, %ScenarioSet{}, decision_id}

  """
  def delete_scenario_set(id, %Decision{} = decision), do: delete_scenario_set(id, decision.id)
  def delete_scenario_set(%ScenarioSet{} = scenario_set, decision_id), do: delete_scenario_set(scenario_set.id, decision_id)
  def delete_scenario_set(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def delete_scenario_set(nil, _), do:  raise ArgumentError, message: "you must supply a ScenarioSet id"
  def delete_scenario_set(id, decision_id) do
    existing = get_scenario_set(id, decision_id)
    count = Repo.aggregate(ScenarioSet, :count, :id)
    case {existing, count} do
      {nil, _} -> {:ok, nil}
      {_, 1} -> {:error, protected_record_changeset(ScenarioSet, :id)}
      {existing, _} -> Repo.delete(existing)
    end
  end

end
