defmodule EtheloApi.Graphql.Resolvers.Scenario do
  @moduledoc """
  Resolvers for graphql.
  """

  alias EtheloApi.Scenarios
  alias EtheloApi.Scenarios.ScenarioSet

  import EtheloApi.Helpers.ValidationHelper

  @doc """
  lists all Scenarios in a ScenarioSet

  See `EtheloApi.Scenarios.list_scenarios/1` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%ScenarioSet{} = scenario_set, modifiers, _resolution) do
    scenario_set |> Scenarios.list_scenarios(modifiers) |> success()
  end

  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  counts scenarios in a scenario_set
  """
  def count(%ScenarioSet{} = scenario_set, modifiers, _resolution) do
    scenario_set |> Scenarios.list_scenarios(modifiers) |> length |> success()
  end

  def count(_, _, _resolution), do: {:ok, 0}
end
