defmodule EtheloApi.Scenarios.ScenarioSetTest do
  @moduledoc """
  Validations and basic access for ScenarioSets
  Includes both the context EtheloApi.Scenariosets, and specific functionality on the ScenarioSet schema
  """
  use EtheloApi.DataCase
  @moduletag scenario_set: true, ecto: true
  import EtheloApi.Scenarios.Factory
  import EtheloApi.Voting.Factory
  import EtheloApi.Scenarios.TestHelper.ScenarioSetHelper

  alias EtheloApi.Scenarios
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Scenarios.ScenarioSet

  describe "list_scenario_sets/1" do
    test "filters by decision_id" do
      %{scenario_set: _excluded} = create_scenario_set()
      %{decision: decision, scenario_set: to_match1} = create_scenario_set()
      %{scenario_set: to_match2} = create_scenario_set(decision)

      result = Scenarios.list_scenario_sets(decision)
      assert [%ScenarioSet{}, %ScenarioSet{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "filters by id" do
      %{decision: decision, scenario_set: to_match} = create_scenario_set()
      %{scenario_set: _excluded} = create_scenario_set()

      modifiers = %{id: to_match.id}
      result = Scenarios.list_scenario_sets(decision, modifiers)

      assert [%ScenarioSet{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "do not return Participant ScenarioSets in listing" do
      %{participant: participant, decision: decision} = create_participant()
      %{scenario_set: to_match} = create_scenario_set(decision)

      %{scenario_set: _excluded} =
        create_scenario_set(decision, %{participant_id: participant.id})

      result = Scenarios.list_scenario_sets(decision)
      assert [%ScenarioSet{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by decision_id and participant_id" do
      %{participant: participant, decision: decision} = create_participant()
      %{scenario_set: _excluded1} = create_scenario_set()
      %{scenario_set: _excluded2} = create_scenario_set(decision)
      %{scenario_set: to_match} = create_scenario_set(decision, %{participant_id: participant.id})

      result = Scenarios.list_scenario_sets(decision, %{participant_id: participant.id})
      assert [%ScenarioSet{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn ->
        Scenarios.list_scenario_sets(nil)
      end
    end
  end

  describe "get_scenario_set/2" do
    test "filters by decision_id" do
      %{scenario_set: to_match, decision: decision} = create_scenario_set()

      result = Scenarios.get_scenario_set(to_match.id, decision)

      assert %ScenarioSet{} = result
      assert result.id == to_match.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Scenarios.get_scenario_set(1, nil) end
    end

    test "raises without a ScenarioSet id" do
      assert_raise ArgumentError, ~r/ScenarioSet/, fn ->
        Scenarios.get_scenario_set(nil, create_decision())
      end
    end

    test "missing record returns nil" do
      decision = create_decision()

      result = Scenarios.get_scenario_set(1929, decision.id)
      assert result == nil
    end

    test "invalid Decision returns nil" do
      %{scenario_set: to_match} = create_scenario_set()
      decision2 = create_decision()

      result = Scenarios.get_scenario_set(to_match.id, decision2)

      assert result == nil
    end
  end

  describe "create_scenario_set/2" do
    test "creates with valid data" do
      deps = scenario_set_deps()
      %{decision: decision} = deps
      attrs = valid_attrs(deps)

      result = Scenarios.create_scenario_set(attrs, decision)

      assert {:ok, %ScenarioSet{} = new_record} = result

      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn ->
        Scenarios.create_scenario_set(invalid_attrs(), nil)
      end
    end

    test "empty data returns changeset" do
      decision = create_decision()
      attrs = empty_attrs()

      result = Scenarios.create_scenario_set(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)

      assert "can't be blank" in errors.status

      expected = [:status]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      decision = create_decision()
      attrs = invalid_attrs()

      result = Scenarios.create_scenario_set(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "is invalid" in errors.scenario_config_id
      assert "is invalid" in errors.participant_id
      assert "is invalid" in errors.status
      assert "is invalid" in errors.json_stats
      assert "is invalid" in errors.hash
      assert "is invalid" in errors.error
      assert "is invalid" in errors.cached_decision
      assert "is invalid" in errors.updated_at
      assert "is invalid" in errors.engine_start
      assert "is invalid" in errors.engine_end

      expected = [
        :scenario_config_id,
        :participant_id,
        :status,
        :json_stats,
        :hash,
        :error,
        :cached_decision,
        :updated_at,
        :engine_start,
        :engine_end
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "update_scenario_set/2" do
    test "updates with valid data" do
      deps = create_scenario_set()
      %{scenario_set: to_update} = deps

      attrs = valid_attrs(deps)

      result = Scenarios.update_scenario_set(to_update, attrs)

      assert {:ok, %ScenarioSet{} = updated} = result

      assert_equivalent(attrs, updated)
    end

    test "empty data returns changeset" do
      deps = create_scenario_set()
      %{scenario_set: to_update} = deps
      attrs = empty_attrs()

      result = Scenarios.update_scenario_set(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.status

      expected = [:status]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      %{scenario_set: to_update} = create_scenario_set()
      attrs = invalid_attrs()

      result = Scenarios.update_scenario_set(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)

      assert "is invalid" in errors.scenario_config_id
      assert "is invalid" in errors.participant_id
      assert "is invalid" in errors.status
      assert "is invalid" in errors.json_stats
      assert "is invalid" in errors.hash
      assert "is invalid" in errors.error
      assert "is invalid" in errors.cached_decision
      assert "is invalid" in errors.updated_at
      assert "is invalid" in errors.engine_start
      assert "is invalid" in errors.engine_end

      expected = [
        :scenario_config_id,
        :participant_id,
        :status,
        :json_stats,
        :hash,
        :error,
        :cached_decision,
        :updated_at,
        :engine_start,
        :engine_end
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "Decision update ignored" do
      %{scenario_set: to_update} = create_scenario_set()
      decision2 = create_decision()

      attrs = %{status: "foo", decision: decision2}
      result = Scenarios.update_scenario_set(to_update, attrs)

      assert {:ok, updated} = result
      assert updated.status == attrs.status
      refute updated.decision.id == decision2.id
      assert updated.decision.id == to_update.decision_id
    end
  end

  describe "delete_scenario_set/2" do
    test "deletes" do
      %{scenario_set: to_delete, decision: decision} = create_scenario_set()
      create_scenario_set(decision)

      result = Scenarios.delete_scenario_set(to_delete, decision.id)
      assert {:ok, %ScenarioSet{}} = result
      assert nil == Repo.get(ScenarioSet, to_delete.id)
      assert nil !== Repo.get(Decision, decision.id)
    end
  end

  describe "set_scenario_set_engine_start/2" do
    test "updates with timestamp" do
      deps = create_scenario_set()
      %{scenario_set: to_update, decision: decision} = deps

      result = Scenarios.set_scenario_set_engine_start(to_update, decision)

      assert {:ok, %ScenarioSet{} = updated} = result
      assert updated.engine_start != to_update.engine_start
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
