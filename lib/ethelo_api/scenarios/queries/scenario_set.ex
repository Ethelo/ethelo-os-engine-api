defmodule EtheloApi.Scenarios.Queries.ScenarioSet do
  @moduledoc """
  Contains methods that will be delegated to inside scenario_set.
  Used purely to reduce the size of scenario_set.ex
  """

  alias EtheloApi.Repo
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Scenarios.ScenarioSet

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.EctoHelper
  import EtheloApi.Helpers.ValidationHelper

  def valid_filters() do
    [
      :id,
      :cached_decision,
      :decision_id,
      :hash,
      :participant_id,
      :scenario_config_id,
      :status
    ]
  end

  def match_query(decision_id, modifiers) do
    modifiers =
      modifiers
      |> Map.put(:decision_id, decision_id)
      |> Map.put_new(:participant_id, nil)

    ScenarioSet
    |> filter_query(modifiers, valid_filters())
  end

  @doc """
  Returns the a single matching ScenarioSet if it exists

  ## Examples

      iex> match_latest_scenario_set(decision, %{hash: hash})
      [%Scenario{}, ...]

  """
  def match_latest_scenario_set(decision, modifiers \\ %{})

  def match_latest_scenario_set(%Decision{} = decision, modifiers),
    do: match_latest_scenario_set(decision.id, modifiers)

  def match_latest_scenario_set(nil, _),
    do: raise(ArgumentError, message: "you must supply a Decision")

  def match_latest_scenario_set(decision_id, modifiers) do
    ScenarioSet

    match_query(decision_id, modifiers)
    |> order_by(desc: :updated_at)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Returns the list of ScenarioSets for a Decision.

  ## Examples

      iex> list_scenario_sets(decision_id, %{participant_id: 1})
      [%Scenario{}, ...]

  """
  def list_scenario_sets(%Decision{} = decision, modifiers),
    do: list_scenario_sets(decision.id, modifiers)

  def list_scenario_sets(nil, _), do: raise(ArgumentError, message: "you must supply a Decision")

  def list_scenario_sets(decision_id, modifiers) do
    decision_id
    |> match_query(modifiers)
    |> order_by(desc: :updated_at, desc: :id)
    |> Repo.all()
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
  def get_scenario_set(_, nil), do: raise(ArgumentError, message: "you must supply a Decision id")

  def get_scenario_set(nil, _),
    do: raise(ArgumentError, message: "you must supply a ScenarioSet id")

  def get_scenario_set(id, decision_id) do
    ScenarioSet |> Repo.get_by(id: id, decision_id: decision_id)
  end

  @doc """
  Creates a ScenarioSet.

  ## Examples

      iex> create_scenario_set(%{status: "This is my status"}, decision)
      {:ok, %ScenarioSet{}}

  """
  def create_scenario_set(attrs, decision)

  def create_scenario_set(%{} = attrs, %Decision{} = decision) do
    attrs
    |> ScenarioSet.create_changeset(decision)
    |> Repo.insert()
  end

  def create_scenario_set(_, nil),
    do: raise(ArgumentError, message: "you must supply a Decision")

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

  #   @doc """
  #   Helper to set all running ScenarioSets to pending so they will no longer be used
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

  defp no_assoc_update(id, decision, attrs)

  defp no_assoc_update(id, %Decision{id: decision_id}, attrs),
    do: no_assoc_update(id, decision_id, attrs)

  defp no_assoc_update(%ScenarioSet{id: id}, decision_id, attrs),
    do: no_assoc_update(id, decision_id, attrs)

  defp no_assoc_update(_, nil, _),
    do: raise(ArgumentError, message: "you must supply a Decision id")

  defp no_assoc_update(nil, _, _),
    do: raise(ArgumentError, message: "you must supply a ScenarioSet id")

  defp no_assoc_update(id, decision_id, attrs) do
    if scenario_set = get_scenario_set(id, decision_id) do
      ScenarioSet.no_assoc_changeset(scenario_set, attrs)
      |> Repo.update()
    end
  end

  @doc """
  Updates the updated_at timestamp for a ScenarioSet

  """
  def touch_scenario_set(id, decision_id) do
    no_assoc_update(id, decision_id, %{updated_at: DateTime.utc_now()})
  end

  @doc """
  Updates the engine_start timestamp for a ScenarioSet

  """

  def set_scenario_set_engine_start(id, decision_id) do
    no_assoc_update(id, decision_id, %{engine_start: DateTime.utc_now()})
  end

  @doc """
  Updates the engine_end timestamp for a ScenarioSet

  """

  def set_scenario_set_engine_end(id, decision_id) do
    no_assoc_update(id, decision_id, %{engine_end: DateTime.utc_now()})
  end

  @doc """
  Updates a ScenarioSet with the error state
  """

  def set_scenario_set_error(id, decision_id, error) do
    attrs = %{updated_at: DateTime.utc_now(), status: "error", error: error}
    no_assoc_update(id, decision_id, attrs)
  end

  @doc """
  Deletes ScenarioSets older than latest sucessful solve
  """
  def delete_expired_scenario_sets(%Decision{} = decision),
    do: delete_expired_scenario_sets(decision.id)

  def delete_expired_scenario_sets(nil),
    do: raise(ArgumentError, message: "you must supply a Decision id")

  def delete_expired_scenario_sets(decision_id) do
    latest_scenario_set = match_latest_scenario_set(decision_id, %{status: "success"})
    delete_expired_scenario_sets(decision_id, latest_scenario_set, "success")
    delete_expired_scenario_sets(decision_id, latest_scenario_set, "error")
  end

  def delete_expired_scenario_sets(_decision_id, nil, _status), do: nil

  def delete_expired_scenario_sets(decision_id, latest_scenario_set, status) do
    {:ok, now} = DateTime.now("Etc/UTC")

    ScenarioSet
    |> join(:inner, [s], config in assoc(s, :scenario_config))
    |> where([s], s.status == ^status)
    |> where([s], s.decision_id == ^decision_id)
    |> where([s], s.id != ^latest_scenario_set.id)
    |> where(
      [s, config],
      config.ttl != 0 and
        s.inserted_at <=
          datetime_add(^now, fragment("-(?)", config.ttl), "second")
    )
    |> Repo.delete_all(timeout: :infinity)
  end

  @doc """
  Cleans pending ScenarioSets that have run too long
  """
  def clean_pending_scenario_sets(%Decision{} = decision),
    do: clean_pending_scenario_sets(decision.id)

  def clean_pending_scenario_sets(nil),
    do: raise(ArgumentError, message: "you must supply a Decision id")

  def clean_pending_scenario_sets(decision_id) do
    {:ok, now} = DateTime.now("Etc/UTC")

    ScenarioSet
    |> join(:inner, [s], config in assoc(s, :scenario_config))
    |> where([s], s.status == "pending")
    |> where([s], not is_nil(s.engine_start))
    |> where([s], s.decision_id == ^decision_id)
    |> where(
      [s, config],
      config.engine_timeout != 0 and
        s.engine_start <=
          datetime_add(
            ^now,
            fragment("-(?)", config.engine_timeout / 1000),
            "second"
          )
    )
    |> Repo.update_all(set: [status: "error", error: "Timeout", updated_at: DateTime.utc_now()])
  end

  @doc """
  Deletes a ScenarioSet.

  ## Examples

      iex> delete_scenario_set(scenario_set, decision_id)
      {:ok, %ScenarioSet{}, decision_id}

  """
  def delete_scenario_set(id, %Decision{} = decision), do: delete_scenario_set(id, decision.id)

  def delete_scenario_set(%ScenarioSet{} = scenario_set, decision_id),
    do: delete_scenario_set(scenario_set.id, decision_id)

  def delete_scenario_set(_, nil),
    do: raise(ArgumentError, message: "you must supply a Decision id")

  def delete_scenario_set(nil, _),
    do: raise(ArgumentError, message: "you must supply a ScenarioSet id")

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
