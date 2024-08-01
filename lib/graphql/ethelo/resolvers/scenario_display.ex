defmodule GraphQL.EtheloApi.Resolvers.ScenarioDisplay do
  @moduledoc """
  Resolvers for graphql.
  """

  alias Engine.Scenarios
  alias Engine.Scenarios.Scenario
  
  import GraphQL.EtheloApi.ResolveHelper

  @doc """
  lists all scenario_displays in a scenario

  See `Engine.Scenarios.list_scenario_display/1` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%Scenario{} = scenario, modifiers, _resolution) do
    scenario |> Scenarios.list_scenario_displays(modifiers) |> success()
  end
  def list(_, _, _resolution), do: {:ok, []}
end
