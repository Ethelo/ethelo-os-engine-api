defmodule EtheloApi.Scenarios.ScenarioTest do
  @moduledoc """
  Validations and basic access for Scenarios
  Includes both the context EtheloApi.Scenarios, and specific functionality on the Scenario schema
  """
  use EtheloApi.DataCase
  @moduletag scenario: true, ecto: true
  import EtheloApi.Scenarios.Factory
  import EtheloApi.Structure.Factory, only: [create_decision: 0]
  import Ecto.Query, warn: false
  import EtheloApi.Scenarios.TestHelper.ScenarioHelper

  alias EtheloApi.Scenarios
  alias EtheloApi.Scenarios.Scenario

  # TODO test for rank filter
  # TODO test for sort by ethelo separately

  describe "list_scenarios/1" do
    test "filters by scenario_set_id" do
      decision = create_decision()
      %{scenario: _excluded} = create_scenario(decision, %{status: "success"})

      %{scenario: to_match1, scenario_set: scenario_set} =
        create_scenario(decision, %{status: "success"})

      %{scenario: to_match2} = create_scenario(scenario_set, %{status: "success"})

      stats = [
        %{scenario_id: to_match1.id, ethelo: 0.2},
        %{scenario_id: to_match2.id, ethelo: 0.5}
      ]

      update_scenario_set_stats(scenario_set.id, stats)

      result = Scenarios.list_scenarios(scenario_set)
      [%Scenario{id: result1_id}, %Scenario{id: result2_id}] = result

      assert result1_id == to_match2.id
      assert result2_id == to_match1.id
    end

    test "filters by status: successful by default" do
      %{scenario_set: scenario_set} = create_scenario_set()
      %{scenario: _duplicate} = create_scenario(scenario_set, %{status: "pending"})
      %{scenario: to_update} = create_scenario(scenario_set, %{status: "success"})

      result = Scenarios.list_scenarios(scenario_set)
      assert [%Scenario{}] = result
      assert_result_ids_match([to_update], result)
    end

    test "filters by id" do
      decision = create_decision()

      %{scenario: to_match, scenario_set: scenario_set} =
        create_scenario(decision, %{status: "success"})

      %{scenario: _not_matching} = create_scenario(scenario_set, %{status: "success"})

      modifiers = %{id: to_match.id}
      result = Scenarios.list_scenarios(scenario_set, modifiers)

      assert [%Scenario{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by global" do
      decision = create_decision()

      %{scenario: to_match, scenario_set: scenario_set} =
        create_scenario(decision, %{status: "success", global: true})

      %{scenario: _not_matching} =
        create_scenario(scenario_set, %{status: "success", global: false})

      modifiers = %{global: true}
      result = Scenarios.list_scenarios(scenario_set, modifiers)

      assert [%Scenario{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by status" do
      decision = create_decision()

      %{scenario: to_match, scenario_set: scenario_set} =
        create_scenario(decision, %{status: "error"})

      %{scenario: _not_matching} = create_scenario(scenario_set, %{status: "pending"})

      modifiers = %{status: to_match.status}
      result = Scenarios.list_scenarios(scenario_set, modifiers)

      assert [%Scenario{}] = result
      assert_result_ids_match([to_match], result)
    end

    @tag skip: true
    test "filters by rank" do
    end

    test "limits query" do
      decision = create_decision()

      %{scenario: _, scenario_set: scenario_set} = create_scenario(decision, %{status: "success"})
      %{scenario: _} = create_scenario(scenario_set, %{status: "success"})
      %{scenario: _excluded} = create_scenario(scenario_set, %{status: "success"})

      modifiers = %{limit: 2}
      result = Scenarios.list_scenarios(scenario_set, modifiers)

      assert [_, _] = result
    end

    test "raises without a ScenarioSet" do
      assert_raise ArgumentError, ~r/ScenarioSet/, fn -> Scenarios.list_scenarios(nil) end
    end
  end

  describe "create_scenario/2" do
    test "creates with valid data" do
      deps = scenario_deps()
      attrs = valid_attrs(deps)

      result = Scenarios.create_scenario(attrs)

      assert {:ok, %Scenario{} = new_record} = result

      assert_equivalent(attrs, new_record)
    end

    test "empty data returns changeset" do
      attrs = empty_attrs()

      result = Scenarios.create_scenario(attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)

      expected = [
        :collective_identity,
        :decision_id,
        :global,
        :minimize,
        :scenario_set_id,
        :status,
        :tipping_point
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      deps = scenario_deps()
      attrs = invalid_attrs(deps)

      result = Scenarios.create_scenario(attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)

      expected = [
        :collective_identity,
        :global,
        :minimize,
        :status,
        :tipping_point
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "documentation" do
    test "has documentation module" do
      assert %{} = Scenario.strings()
      assert %{} = Scenario.examples()
      assert is_list(Scenario.fields())
    end
  end
end
