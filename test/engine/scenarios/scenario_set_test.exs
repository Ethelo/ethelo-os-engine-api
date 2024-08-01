defmodule Engine.Scenarios.ScenarioSetTest do
  @moduledoc """
  Validations and basic access for ScenarioSets
  Includes both the context Engine.Scenariosets, and specific functionality on the ScenarioSet schema
  """
  use EtheloApi.DataCase
  @moduletag scenario_set: true, ethelo: true, ecto: true
  import Engine.Scenarios.Factory
  import EtheloApi.Voting.Factory

  alias Engine.Scenarios
  alias EtheloApi.Structure.Decision
  alias Engine.Scenarios.ScenarioSet

  def valid_attrs(%{} = _deps) do
   %{
      status: "pending", engine_start: Time.utc_now(), engine_end: Time.utc_now()
    }
  end

  def assert_equivalent(expected, result) do
    assert expected.status == result.status
  end

  describe "list_scenario_sets/1" do

    test "returns records matching a Decision" do
      create_scenario_set() # should not be returned
      %{decision: decision, scenario_set: first} = create_scenario_set()
      %{scenario_set: second} = create_scenario_set(decision)

      result = Scenarios.list_scenario_sets(decision)
      assert [%ScenarioSet{}, %ScenarioSet{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "returns record matching id" do
      %{decision: decision, scenario_set: matching} = create_scenario_set()
      create_scenario_set(decision) # should not be returned

      filters = %{id: matching.id}
      result = Scenarios.list_scenario_sets(decision, filters)

      assert [%ScenarioSet{}] = result
      assert_result_ids_match([matching], result)
    end

    test "do not return participant ScenarioSets in listing" do
      %{participant: participant, decision: decision} = create_participant()
      %{scenario_set: first} = create_scenario_set(decision)
      create_scenario_set(decision, %{participant_id: participant.id}) # should not be returned

      result = Scenarios.list_scenario_sets(decision)
      assert [%ScenarioSet{}] = result
      assert_result_ids_match([first], result)
    end

    test "raises without a ScenarioSet" do
      assert_raise ArgumentError, ~r/ScenarioSet/,
        fn -> Scenarios.list_scenarios(nil) end
    end
  end

  describe "list_participant_scenario_sets/1" do

    test "returns records matching a Decision and Participant" do
      %{participant: participant, decision: decision} = create_participant()
      create_scenario_set() # should not be returned
      create_scenario_set(decision) # should not be returned
      %{scenario_set: first} = create_scenario_set(decision, %{participant_id: participant.id})

      result = Scenarios.list_participant_scenario_sets(decision, participant)
      assert [%ScenarioSet{}] = result
      assert_result_ids_match([first], result)
    end

    test "returns record matching id" do
      %{participant: participant, decision: decision} = create_participant()
      %{scenario_set: matching} = create_scenario_set(decision, %{participant_id: participant.id})
      create_scenario_set(decision, %{participant_id: participant.id}) # should not be returned

      filters = %{id: matching.id}
      result = Scenarios.list_participant_scenario_sets(decision, participant, filters)

      assert [%ScenarioSet{}] = result
      assert_result_ids_match([matching], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Scenarios.list_participant_scenario_sets(nil, nil) end
    end
  end

  describe "delete_scenario_set/2" do

    test "deletes" do
      %{scenario_set: existing, decision: decision} = create_scenario_set()
      create_scenario_set(decision)
      to_delete = %ScenarioSet{id: existing.id}

      result = Scenarios.delete_scenario_set(to_delete, decision.id)
      assert {:ok, %ScenarioSet{}} = result
      assert nil == Repo.get(ScenarioSet, existing.id)
      assert nil !== Repo.get(Decision, decision.id)
    end

  end

  describe "set_scenario_set_engine_start/2" do
    test "updates with timestamp" do
      deps = create_scenario_set()
      %{scenario_set: existing, decision: decision} = deps

      result = Scenarios.set_scenario_set_engine_start(existing, decision)

      assert {:ok, %ScenarioSet{} = updated} = result
      assert updated.engine_start != existing.engine_start
    end
  end

  describe "documentation" do
    test "has documentation module" do
      assert %{} = ScenarioSet.strings()
      assert %{} = ScenarioSet.examples()
      assert is_list(ScenarioSet.fields())
    end
  end
end
