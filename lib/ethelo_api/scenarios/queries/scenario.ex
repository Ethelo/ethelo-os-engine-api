defmodule EtheloApi.Scenarios.Queries.Scenario do
  @moduledoc """
  Contains methods that will be delegated to inside EtheloApi.Scenarios.
  """

  alias EtheloApi.Graphql.Docs.Scenario
  alias EtheloApi.Repo
  alias EtheloApi.Scenarios.ScenarioSet
  alias EtheloApi.Scenarios.Scenario
  alias EtheloApi.Scenarios.Queries.ScenarioStats

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.EctoHelper

  def valid_filters() do
    [:id, :scenario_set_id, :status]
  end

  def match_query(scenario_set_id, modifiers) do
    global_rank = if Map.get(modifiers, :global, false), do: 0, else: nil
    rank = Map.get(modifiers, :rank, global_rank)
    status = Map.get(modifiers, :status, "success")

    modifiers =
      modifiers
      |> Map.put(:status, status)
      |> Map.put(:scenario_set_id, scenario_set_id)
      |> Map.delete(:rank)
      |> Map.delete(:global)
      |> Map.delete(:limit)

    query = Scenario |> filter_query(modifiers, valid_filters())

    cond do
      rank == 0 ->
        query |> where(global: true) |> limit(1)

      rank == nil ->
        query

      rank > 0 ->
        query |> where(global: false) |> limit(1)
    end
  end

  @doc """
  Returns a list of distinct (on Options & minimize) Scenarios for a ScenarioSet.

  Note: By default, this filters to status: "success" are listed unless an alternate :status filter is passed

  ## Examples

      iex> list_scenarios(scenario_set_id)
      [%Scenario{}, ...]

  """
  def list_scenarios(scenario_set, modifiers \\ %{})

  def list_scenarios(%ScenarioSet{} = scenario_set, modifiers),
    do: list_scenarios(scenario_set.id, modifiers)

  def list_scenarios(nil, _), do: raise(ArgumentError, message: "you must supply a ScenarioSet")

  def list_scenarios(scenario_set_id, modifiers) do
    limit = Map.get(modifiers, :limit, nil)
    rank = Map.get(modifiers, :rank, nil)

    scenario_set_id
    |> match_query(modifiers)
    |> Repo.all()
    |> order_by_ethelo(scenario_set_id)
    |> limit_scenarios(rank, limit)
  end

  defp limit_scenarios(list, nil, nil), do: list

  defp limit_scenarios(list, rank, _) when is_integer(rank) and rank > 0 do
    list |> Enum.slice(rank - 1, 1)
  end

  defp limit_scenarios(list, _, limit) when is_integer(limit) do
    list |> Enum.slice(0, limit)
  end

  defp limit_scenarios(list, _, _), do: list

  defp order_by_ethelo(list, scenario_set_id) do
    sort_order =
      scenario_set_id
      |> ScenarioStats.list_scenario_stats(%{issue_id: nil, option_id: nil, criteria_id: nil})
      |> Enum.sort_by(& &1.ethelo)
      |> Enum.reverse()
      |> Enum.map(&Map.get(&1, :scenario_id, false))
      |> Enum.filter(& &1)

    list
    |> Enum.sort_by(fn %Scenario{id: scenario_id} ->
      index = Enum.find_index(sort_order, fn x -> x == scenario_id end)

      if index == nil do
        # sort to end
        10_000
      else
        index
      end
    end)
  end

  @doc """
  Creates a Scenario.

  ## Examples

      iex> create_scenario( %{status: "success", scenario_set_id: 1, decision_id: 1})
      {:ok, %Scenario{}}

      iex> create_scenario(d %{scenario_set_id: 0}, decision)
      {:error, %Ecto.Changeset{}}

  """
  def create_scenario(%{} = attrs) do
    Scenario.create_changeset(attrs)
    |> Repo.insert()
  end

  def create_scenario(_, _), do: raise(ArgumentError, message: "you must supply a ScenarioSet Id")

  @doc """
  Creates a default Scenario if no Scenarios exist.


  This method should only be used internally and should never be exposed via api

  ## Examples

      iex> ensure_one_scenario(scenario_set)
      :ok

  """
  def ensure_one_scenario(%ScenarioSet{id: scenario_set_id, decision_id: decision_id}) do
    Scenario
    |> Repo.get_by(scenario_set_id: scenario_set_id)
    |> case do
      %Scenario{} = scenario -> {:ok, scenario}
      nil -> Repo.insert(%Scenario{scenario_set_id: scenario_set_id, decision_id: decision_id})
    end
  end

  def ensure_one_scenario(_), do: raise(ArgumentError, message: "you must supply a ScenarioSet")
end
