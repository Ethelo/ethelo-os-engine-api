defmodule EtheloApi.Invocation.SolveAttemptTest do
  @moduledoc false
  use EtheloApi.DataCase
  @moduletag engine: true, scenarios: true, invocation: true, ecto: true

  alias EtheloApi.Invocation
  alias EtheloApi.Invocation.SolveAttempt
  alias EtheloApi.Scenarios
  alias EtheloApi.Scenarios.ScenarioSet
  alias EtheloApi.Invocation.ScenarioHashes
  alias EtheloApi.Scenarios.SolveDump
  alias AbsintheErrorPayload.ValidationMessage

  # alias EtheloApi.Invocation.InvocationSettings

  # todo test solve interval
  # todo test timeout
  # todo test match latest

  setup do
    context = EtheloApi.Blueprints.PizzaProject.build()
    # this serves to test these methods, so there is no separate cache test file
    Invocation.update_decision_cache(context.decision)
    Invocation.update_scenario_config_cache(context.scenario_config, context.decision)
    updated_decision = EtheloApi.Repo.get(EtheloApi.Structure.Decision, context.decision.id)

    %{context | decision: updated_decision}
  end

  test "invalid Decision returns simple error" do
    {status, _result} = SolveAttempt.solve(0, 0, [])
    assert status == :error
  end

  test "no ScenarioConfig returns simple error", context do
    %{decision: decision} = context

    {status, _result} = SolveAttempt.solve(decision.id, nil, [])
    assert status == :error
  end

  test "invalid ScenarioConfig returns simple error", context do
    %{decision: decision} = context

    {status, _result} = SolveAttempt.solve(decision.id, 0)
    assert status == :error
  end

  test "invalid Participant returns simple error", context do
    %{decision: decision, scenario_config: scenario_config} = context

    options = [participant_id: 0]
    {status, _result} = SolveAttempt.solve(decision.id, scenario_config.id, options)
    assert status == :error
  end

  test "missing DecisionCache returns ScenarioSet error" do
    %{decision: decision, scenario_config: scenario_config} =
      EtheloApi.Blueprints.SimpleDecision.build()

    options = [use_cache: true]

    assert {:error, error} = SolveAttempt.solve(decision.id, scenario_config.id, options)

    assert %ValidationMessage{} = error
    assert error.field == :use_cache
    assert error.code == :not_found
    assert error.message == "Decision cache does not exist"
  end

  test "missing ScenarioConfig cache returns error" do
    %{decision: decision, scenario_config: scenario_config} =
      EtheloApi.Blueprints.SimpleDecision.build()

    Invocation.update_decision_cache(decision)

    options = [use_cache: true]

    assert {:error, error} = SolveAttempt.solve(decision.id, scenario_config.id, options)

    assert %ValidationMessage{} = error
    assert error.field == :use_cache
    assert error.code == :not_found
    assert error.message == "ScenarioConfig cache does not exist"
  end

  test "no votes returns ScenarioSet error", context do
    %{decision: decision, scenario_config: scenario_config} = context
    participant = context[:participants][:no_votes]
    options = [participant_id: participant.id]

    assert {:ok, scenario_set} = SolveAttempt.solve(decision.id, scenario_config.id, options)
    assert scenario_set.status == "error"
    assert scenario_set.error !== nil
  end

  test "uses existing ScenarioSet", context do
    %{decision: decision, scenario_config: scenario_config} = context
    # refresh models in case hashes have changed due to other tests
    decision = EtheloApi.Repo.get(EtheloApi.Structure.Decision, decision.id)
    scenario_config = EtheloApi.Repo.get(EtheloApi.Structure.ScenarioConfig, scenario_config.id)

    {:ok, hash} =
      ScenarioHashes.get_group_scenario_hash(decision, scenario_config, true)

    attrs = %{
      scenario_config_id: scenario_config.id,
      cached_decision: true,
      hash: hash,
      status: "pending"
    }

    {:ok, scenario_set} = Scenarios.create_scenario_set(attrs, decision)

    options = [use_cache: true]

    assert {:ok, scenario_set2} = SolveAttempt.solve(decision.id, scenario_config.id, options)

    assert scenario_set.id == scenario_set2.id
  end

  test "dumps solve if enabled", context do
    %{decision: decision, scenario_config: scenario_config} = context

    options = [save_dump: true]

    result = Invocation.solve(decision.id, scenario_config.id, options)
    assert {:ok, %ScenarioSet{} = scenario_set} = result

    solve_dump =
      Scenarios.get_solve_dump(scenario_set)

    assert %SolveDump{} = solve_dump

    refute solve_dump.influents_json == ~c""
    refute solve_dump.response_json == ~c""
  end
end
