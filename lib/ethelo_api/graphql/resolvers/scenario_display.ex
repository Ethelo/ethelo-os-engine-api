defmodule EtheloApi.Graphql.Resolvers.ScenarioDisplay do
  @moduledoc """
  Resolvers for graphql.
  """

  alias EtheloApi.Scenarios
  alias EtheloApi.Scenarios.Scenario

  import EtheloApi.Helpers.ValidationHelper

  @doc """
  lists all Scenario Displays in a Scenario

  See `EtheloApi.Scenarios.list_scenario_display/1` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%Scenario{} = scenario, modifiers, _resolution) do
    scenario |> Scenarios.list_scenario_displays(modifiers) |> success()
  end

  def list(_, _, _resolution), do: {:ok, []}
end
