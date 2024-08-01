defmodule Engine.Invocation.IntegrationTest do
  @moduledoc false
  use EtheloApi.DataCase
  @moduletag engine: true, scenarios: true, ethelo: true, ecto: true

  alias Engine.Invocation
  alias Engine.Invocation.Builder
  alias Engine.Invocation.SolveSettings
  alias Engine.Scenarios
  alias Engine.Scenarios.ScenarioSet
  alias Engine.Scenarios.SolveDump

  setup do
    context = EtheloApi.Blueprints.PizzaProject.build()
    Invocation.update_decision_cache(context.decision.id)
    context
  end

  def read_test_file(filename) do
    File.read!(Path.join("#{:code.priv_dir(:ethelo)}", "tests/#{filename}"))
  end

  test "test direct with sample files" do
    decision_json = read_test_file("pizza/decision_json.json")
    refute decision_json == ''

    influents_json = read_test_file("pizza/influents_json.json")
    refute influents_json == ''

    weights_json = read_test_file("pizza/weights_json.json")
    refute weights_json == ''

    config_json = read_test_file("pizza/config_json.json")
    refute config_json == ''

    {status, result} =
      Engine.Driver.call(
        :solve,
        {decision_json, influents_json, weights_json, config_json, ""}
      )

    refute result == ''

    assert status == :ok
  end

  test "direct invocation works", context do
    %{decision: decision, scenario_config: scenario_config} = context

    options = [scenario_config_id: scenario_config.id]
    result = Invocation.invocation_jsons(decision.id, options)
    assert {:ok, files} = result

    args = {files.decision_json, files.influents_json, files.weights_json, files.config_json, ""}
    {status, result} = Engine.Driver.call(:solve, args)
    refute result == ''

    assert status == :ok
  end

  test "group solve without cache", context do
    %{decision: decision, scenario_config: scenario_config} = context

    options = [scenario_config_id: scenario_config.id]
    assert {:ok, settings} = Invocation.build_solve_settings(decision.id, options)
    assert settings.is_new_solve == true

    assert {:ok, scenario_set} = Invocation.solve_decision(settings)
    assert %ScenarioSet{} = scenario_set
    assert %{status: "success", error: nil} = scenario_set

    dumps =
      Scenarios.list_solve_dumps(settings.decision, %{scenario_set_id: settings.scenario_set.id})

    assert [] == dumps
  end

  test "group solve loads cached scenario set", context do
    %{decision: decision, scenario_config: scenario_config} = context

    options = [scenario_config_id: scenario_config.id]

    result = Builder.build_solve_settings(decision.id, options)
    assert {:ok, %SolveSettings{scenario_set: scenario_set} = settings} = result

    result = Builder.add_scenario_set(settings)

    assert {:ok, %SolveSettings{scenario_set: %ScenarioSet{id: scenario_set2_id}} = settings2} =
             result

    assert settings2.is_new_solve == false
    assert scenario_set.id == scenario_set2_id

    result = Invocation.solve_decision(settings)
    assert {:ok, %ScenarioSet{} = scenario_set} = result
    assert %{status: "success", error: nil} = scenario_set
  end

  test "participant solve", context do
    %{decision: decision, scenario_config: scenario_config} = context

    participant = context[:participants][:one]

    options = [scenario_config_id: scenario_config.id, participant_id: participant.id]

    assert {:ok, settings} = Invocation.build_solve_settings(decision.id, options)
    assert settings.is_new_solve == true
    assert settings.scenario_set != nil

    result = Invocation.solve_decision(settings)
    assert {:ok, %ScenarioSet{} = scenario_set} = result
    assert %{status: "success", error: nil} = scenario_set
  end

  test "participant solve full call", context do
    %{decision: decision, scenario_config: scenario_config} = context

    participant = context[:participants][:one]

    options = [scenario_config_id: scenario_config.id, participant_id: participant.id]
    result = Invocation.solve_decision(decision.id, options)
    assert {:ok, %ScenarioSet{} = scenario_set} = result
    assert %{status: "success", error: nil} = scenario_set
  end

  test "participant solve no votes", context do
    %{decision: decision, scenario_config: scenario_config} = context

    participant = context[:participants][:no_votes]

    options = [scenario_config_id: scenario_config.id, participant_id: participant.id]
    result = Invocation.solve_decision(decision.id, options)
    assert {:ok, %ScenarioSet{} = scenario_set} = result
    assert %{status: "error"} = scenario_set
  end

  test "dumps solve if enabled", context do
    %{decision: decision, scenario_config: scenario_config} = context

    options = [scenario_config_id: scenario_config.id, save_dump: true]
    result = Builder.build_solve_settings(decision.id, options)
    assert {:ok, %SolveSettings{} = settings} = result

    result = Invocation.solve_decision(settings)
    assert {:ok, %ScenarioSet{} = _scenario_set} = result

    dumps =
      Scenarios.list_solve_dumps(settings.decision, %{scenario_set_id: settings.scenario_set.id})

    assert [%SolveDump{} = dump] = dumps

    refute dump.influents_json == ''
    refute dump.response_json == ''
  end
end
