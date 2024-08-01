defmodule GraphQL.EtheloApi.Resolvers.ScenarioStats do
  @moduledoc """
  Resolvers for graphql.
  """

  alias Engine.Scenarios
  alias Engine.Scenarios.Scenario
  alias Engine.Scenarios.ScenarioSet

  import GraphQL.EtheloApi.ResolveHelper

  @doc """
  lists all scenario_stats in a scenario_set

  See `Engine.Scenarios.list_scenario_stats/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%ScenarioSet{} = scenario_set, modifiers, _resolution) do
    scenario_set
    |> Scenarios.list_scenario_stats(modifiers)
    |> success()
  end
  def list(_, _, _resolution), do: {:ok, []}

  def get_scenario_stats(%Scenario{} = scenario, _modifiers, _resolution) do
    results = scenario.scenario_set_id
    |> Scenarios.list_scenario_stats(%{scenario_id: scenario.id, issue_id: nil, option_id: nil, criteria_id: nil})
    |> Enum.take(1)

    case results do
      [stats] -> stats
      [] -> nil
    end |> success()
  end
  def get_scenario_stats(_, _, _resolution), do: {:ok, nil}

  def extract_filters(%{} = args) do
    filters = %{}
    filters = if Map.has_key?(args, :scenario_set_id), do: Map.put(filters, :id, args.scenario_set_id), else: filters
    filters
  end

end
