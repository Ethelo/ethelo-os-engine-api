defmodule EtheloApi.Invocation.IntegrationTest do
  @moduledoc false
  use EtheloApi.DataCase
  @moduletag engine: true, scenarios: true, ecto: true, skip: true

  alias EtheloApi.Invocation
  alias EtheloApi.Scenarios
  alias EtheloApi.Scenarios.ScenarioSet

  setup do
    context = EtheloApi.Blueprints.PizzaProject.build()
    Invocation.update_decision_cache(context.decision)
    Invocation.update_scenario_config_cache(context.scenario_config, context.decision)

    context
  end

  test "group solve", context do
    %{decision: decision, scenario_config: scenario_config} = context

    assert {:ok, scenario_set} = Invocation.solve(decision.id, scenario_config.id)
    assert %ScenarioSet{} = scenario_set
    assert %{status: "success", error: nil} = scenario_set

    solve_dump = Scenarios.get_solve_dump(scenario_set.id)

    assert nil == solve_dump
  end

  test "Participant solve", context do
    %{decision: decision, scenario_config: scenario_config} = context

    participant = context[:participants][:one]

    options = [participant_id: participant.id]
    result = Invocation.solve(decision.id, scenario_config.id, options)
    assert {:ok, %ScenarioSet{} = scenario_set} = result
    assert %{status: "success", error: nil} = scenario_set
  end
end
