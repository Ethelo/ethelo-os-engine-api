defmodule EtheloApi.Graphql.Resolvers.ScenarioStats do
  @moduledoc """
  Resolvers for graphql.
  """

  alias EtheloApi.Scenarios
  alias EtheloApi.Scenarios.Scenario
  alias EtheloApi.Scenarios.ScenarioSet
  import EtheloApi.Helpers.ValidationHelper

  @doc """
  lists all ScenarioStats in a ScenarioSet

  See `EtheloApi.Scenarios.list_scenario_stats/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%ScenarioSet{} = scenario_set, modifiers, _resolution) do
    scenario_set
    |> Scenarios.list_scenario_stats(modifiers)
    |> success()
  end

  def list(_, _, _resolution), do: {:ok, []}

  def for_scenario(%Scenario{} = scenario, _modifiers, _resolution) do
    results =
      scenario.scenario_set_id
      |> Scenarios.list_scenario_stats(%{
        scenario_id: scenario.id,
        issue_id: nil,
        option_id: nil,
        criteria_id: nil
      })
      |> Enum.take(1)

    case results do
      [stats] -> stats
      [] -> nil
    end
    |> success()
  end

  def for_scenario(_, _, _resolution), do: {:ok, nil}
end
