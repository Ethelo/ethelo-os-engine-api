defmodule Engine.Scenarios.Queries.Scenario do
  @moduledoc """
  Contains methods that will be delegated to inside scenario.
  Used purely to reduce the size of scenario.ex
  """

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.QueryHelper

  alias EtheloApi.Repo
  alias Engine.Scenarios.ScenarioSet
  alias Engine.Scenarios.Scenario
  alias Engine.Scenarios.Queries.ScenarioStats

  def valid_filters() do
    [:id, :scenario_set_id, :status, :minimize, :global]
  end

  @doc """
  private method to start querying with acceptable preloads
  """
  def base_query() do
    Scenario |> preload(:options)
  end

  def match_query(scenario_set_id, filters) do
    rank = Map.get(filters, :rank, nil)

    query = if Map.get(filters, :all) do
      base_query()
    else
      base_query() |> where(status: "success")
    end

    filters = Map.put(filters, :scenario_set_id, scenario_set_id)
    filters = filters |> Map.delete(:rank) |> Map.delete(:global) |> Map.delete(:all) |> Map.delete(:count)

    query  = query |> filter_query(filters, valid_filters())

    cond do
      rank == 0 ->
        query |> where(global: true) |> limit(1)
      rank == nil ->
        query
      rank > 0 ->
        query |> where( global: false )
      true ->
        query
    end

  end

  @doc """
  Returns a list of distinct (on options & minimize) Scenarios for a ScenarioSet.

  Note: Only scenarios with status "success" are listed unless the special boolean filter :all is passed as true

  ## Examples

      iex> list_scenarios(scenario_set_id)
      [%Scenario{}, ...]

  """
  def list_scenarios(scenario_set, filters \\ %{})
  def list_scenarios(%ScenarioSet{} = scenario_set, filters), do: list_scenarios(scenario_set.id, filters)
  def list_scenarios(nil, _), do: raise ArgumentError, message: "you must supply a ScenarioSet"
  def list_scenarios(scenario_set_id, filters) do
    count = Map.get(filters, :count, 1)
    rank = Map.get(filters, :rank, nil)

    scenario_set_id
      |> match_query(filters)
      |> Repo.all
      |> order_by_ethelo(scenario_set_id)
      |> limit_scenarios(rank, count)
  end

  defp limit_scenarios(list, nil, _), do: list
  defp limit_scenarios(list, rank, count) when rank > 0  do
    list  |> Enum.slice(rank - 1, count)
  end
  defp limit_scenarios(list, _, _), do: list

  defp order_by_ethelo(list, scenario_set_id) do
    sort_order = scenario_set_id
      |> ScenarioStats.list_scenario_stats(%{issue_id: nil, option_id: nil, criteria_id: nil})
      |> Enum.sort_by(&(&1.ethelo))
      |> Enum.reverse()
      |> Enum.map(&(Map.get(&1, :scenario_id, false)))
      |> Enum.filter(&(&1))
    
    list |> Enum.sort_by(fn(%Scenario{id: scenario_id}) ->
      index = Enum.find_index(sort_order, fn(x) -> x == scenario_id end )
      if index == nil do
        10000 # sort to end
      else
        index
      end
    end)


  end

  @doc """
  Returns the "global" Scenario for a ScenarioSet.

  ## Examples

      iex> get_global_scenario(scenario_set_id)
      [%Scenario{}, ...]

  """
  def get_global_scenario(scenario_set)
  def get_global_scenario(%ScenarioSet{} = scenario_set), do: get_global_scenario(scenario_set.id)
  def get_global_scenario(nil), do: raise ArgumentError, message: "you must supply a ScenarioSet"
  def get_global_scenario(scenario_set_id) do
    scenario_set_id |> match_query(%{all: true, global: true}) |> limit(1) |> Repo.one
  end

  @doc """
  Returns the matching Scenarios for a list of DecisionId ids.
  used for batch processing

  ## Examples

      iex> match_scenarios(decision_ids)
      [%Scenario{}, ...]

  """
  def match_scenarios(filters \\ %{}, decision_ids)
  def match_scenarios(filters, decision_ids) when is_list(decision_ids) do
    decision_ids = Enum.uniq(decision_ids)

    all = Map.get(filters, :all)
    filters = filters |> Map.delete(:all)

    query = if all do
      Scenario
    else
      Scenario |> where(status: "success")
    end

    query
      |> where([t], t.decision_ids in ^decision_ids)
      |> filter_query(filters, valid_filters())
      |> Repo.all
  end
  def match_scenarios(_, nil), do: raise ArgumentError, message: "you must supply a list of Decision ids"


  @doc """
  Gets a single Scenario by id

  returns nil if Scenario does not exist or does not belong to the specified ScenarioSet

  ## Examples

      iex> get_scenario(123, 1)
      %Scenario{}

      iex> get_scenario(456, 3)
      nil

  """
  def get_scenario(id, %ScenarioSet{} = scenario_set), do: get_scenario(id, scenario_set.id)
  def get_scenario(_, nil), do: raise ArgumentError, message: "you must supply a ScenarioSet id"
  def get_scenario(nil, _), do:  raise ArgumentError, message: "you must supply a Scenario id"
  def get_scenario(id, scenario_set_id) do
    base_query() |> Repo.get_by(id: id, scenario_set_id: scenario_set_id)
  end

  @doc """
  Creates a Scenario.

  ## Examples

      iex> create_scenario(scenario_set, %{title: "This is my title"})
      {:ok, %Scenario{}}

      iex> create_scenario(scenario_set, %{title: " "})
      {:error, %Ecto.Changeset{}}

  """
  def create_scenario(%ScenarioSet{} = scenario_set, %{} = attrs) do
    %Scenario{}
    |> Scenario.create_changeset(attrs, scenario_set)
    |> Repo.insert()
  end
  def create_scenario(_, _), do: raise ArgumentError, message: "you must supply a ScenarioSet"

  @doc """
  Creates a default Scenario if no Scenarios exist.


  This method should only be used internally and should never be exposed via api

  ## Examples

      iex> ensure_one_scenario(scenario_set)
      :ok

  """
  def ensure_one_scenario(%ScenarioSet{id: scenario_set_id}) do
    Scenario
    |> Repo.get_by(scenario_set_id: scenario_set_id)
    |> case do
      %Scenario{} = config -> {:ok, config}
      nil -> Repo.insert(%Scenario{scenario_set_id: scenario_set_id})
    end
  end
  def ensure_one_scenario(_), do: raise ArgumentError, message: "you must supply a ScenarioSet"

  @doc """
  Updates a Scenario.
  Note: this method will not change the ScenarioSet a Scenario belongs to.

  ## Examples

      iex> update_scenario(scenario, %{field: new_value})
      {:ok, %Scenario{}}

      iex> update_scenario(scenario, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_scenario(%Scenario{} = scenario, %{} = attrs) do
    scenario
    |> Scenario.update_changeset(attrs)
    |> Repo.update()
  end

end
