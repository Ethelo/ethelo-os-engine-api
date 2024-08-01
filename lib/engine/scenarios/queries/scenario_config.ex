defmodule Engine.Scenarios.Queries.ScenarioConfig do
  @moduledoc """
  Contains methods that will be delegated to inside structure.
  Used purely to reduce the size of structure.ex
  """

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.QueryHelper
  import EtheloApi.Helpers.ValidationHelper

  alias EtheloApi.Repo
  alias EtheloApi.Structure.Decision
  alias Engine.Scenarios.ScenarioConfig

  def valid_filters() do
    [:slug, :id, :decision_id, :enabled, :quadratic]
  end

  @doc """
  private method to start querying with acceptable preloads
  """
  def base_query() do
    ScenarioConfig
  end

  def match_query(decision_id, filters) do
    filters = Map.put(filters, :decision_id, decision_id)

    ScenarioConfig
    |> filter_query(filters, valid_filters())
  end

  @doc """
  Returns the list of ScenarioConfigs for a Decision.

  ## Examples

      iex> list_scenario_configs(decision_id)
      [%ScenarioConfig{}, ...]

  """
  def list_scenario_configs(decision, filters \\ %{})
  def list_scenario_configs(%Decision{} = decision, filters), do: list_scenario_configs(decision.id, filters)
  def list_scenario_configs(nil, _), do: raise ArgumentError, message: "you must supply a Decision"
  def list_scenario_configs(decision_id, filters) do
    decision_id |> match_query(filters) |> Repo.all
  end

  @doc """
  Returns the matching ScenarioConfigs for a list of Decision ids.

  ## Examples

      iex> match_scenario_configs(decision_id)
      [%Option{}, ...]

  """
  def match_scenario_configs(filters \\ %{}, decision_ids)
  def match_scenario_configs(filters, decision_ids) when is_list(decision_ids) do
    decision_ids = Enum.uniq(decision_ids)

    ScenarioConfig
    |> where([t], t.decision_id in ^decision_ids)
    |> filter_query(filters, valid_filters())
    |> Repo.all
  end
  def match_scenario_configs(_, nil), do: raise ArgumentError, message: "you must supply a list of Decision ids"


  @doc """
  Gets a single ScenarioConfig by id

  returns nil if ScenarioConfig does not exist or does not belong to the specified Decision

  ## Examples

      iex> get_scenario_config(123, 1)
      %ScenarioConfig{}

      iex> get_scenario_config(456, 3)
      nil

  """
  def get_scenario_config(id, %Decision{} = decision), do: get_scenario_config(id, decision.id)
  def get_scenario_config(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def get_scenario_config(nil, _), do:  raise ArgumentError, message: "you must supply a ScenarioConfig id"
  def get_scenario_config(id, decision_id) do
    base_query() |> Repo.get_by(id: id, decision_id: decision_id)
  end

  @doc """
  Creates a ScenarioConfig.

  ## Examples

      iex> create_scenario_config(decision, %{title: "This is my title"})
      {:ok, %ScenarioConfig{}}

      iex> create_scenario_config(decision, %{title: " "})
      {:error, %Ecto.Changeset{}}

  """
  def create_scenario_config(%Decision{} = decision, %{} = attrs) do
    %ScenarioConfig{}
    |> ScenarioConfig.create_changeset(attrs, decision)
    |> Repo.insert()
  end
  def create_scenario_config(_, _), do: raise ArgumentError, message: "you must supply a Decision"

  @doc """
  Creates a default ScenarioConfig if no ScenarioConfigs exist.


  This method should only be used internally and should never be exposed via api

  ## Examples

      iex> ensure_one_scenario_config(decision)
      :ok

  """
  def ensure_one_scenario_config(%Decision{id: decision_id}) do
    ScenarioConfig
    |> where(decision_id: ^decision_id)
    |> limit(1) |> Repo.one
    |> case do
      %ScenarioConfig{} = config -> {:ok, config}
      nil -> Repo.insert(%ScenarioConfig{decision_id: decision_id, title: "Default", slug: "default", bins: 5})
    end
  end
  def ensure_one_scenario_config(_), do: raise ArgumentError, message: "you must supply a Decision"

  @doc """
  Updates a ScenarioConfig.
  Note: this method will not change the Decision a ScenarioConfig belongs to.

  ## Examples

      iex> update_scenario_config(scenario_config, %{field: new_value})
      {:ok, %ScenarioConfig{}}

      iex> update_scenario_config(scenario_config, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_scenario_config(%ScenarioConfig{} = scenario_config, %{} = attrs) do
    scenario_config
    |> ScenarioConfig.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a ScenarioConfig.

  ## Examples

      iex> delete_scenario_config(scenario_config, decision_id)
      {:ok, %ScenarioConfig{}, decision_id}

  """
  def delete_scenario_config(id, %Decision{} = decision),
    do: delete_scenario_config(id, decision.id)

  def delete_scenario_config(%ScenarioConfig{} = scenario_config, decision_id),
    do: delete_scenario_config(scenario_config.id, decision_id)

  def delete_scenario_config(_, nil),
    do: raise(ArgumentError, message: "you must supply a Decision id")

  def delete_scenario_config(nil, _),
    do: raise(ArgumentError, message: "you must supply a ScenarioConfig id")

  def delete_scenario_config(id, decision_id) do
    existing = get_scenario_config(id, decision_id)
    count = Repo.aggregate(ScenarioConfig, :count, :id)

    case {existing, count} do
      {nil, _} ->
        {:ok, nil}

      {_, 1} ->
        {:error, protected_record_changeset(ScenarioConfig, :id)}

      {existing, _} ->
        result = Repo.delete(existing)
        Engine.Invocation.delete_scenario_config_cache_value(id, existing.decision_id)
        result
    end
  end
end
