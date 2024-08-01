defmodule Engine.Scenarios.ScenarioTest do
  @moduledoc """
  Validations and basic access for Scenarios
  Includes both the context Engine.Scenarios, and specific functionality on the Scenario schema
  """
  use EtheloApi.DataCase
  @moduletag scenario: true, ethelo: true, ecto: true
  import Engine.Scenarios.Factory
  import Ecto.Query, warn: false

  alias Engine.Scenarios
  alias Engine.Scenarios.Scenario
  alias Engine.Scenarios.ScenarioSet

  def valid_attrs(%{} = _deps) do
   %{
      collective_identity: 0.0,
      tipping_point: 0.44,
      minimize: false,
      global: false,
      status: "pending"
    }
  end

  @nil_attrs %{
    collective_identity: nil,
    tipping_point: nil,
    minimize: nil,
    global: nil,
    status: nil
  }

  @invalid_attrs %{
    collective_identity: "e",
    tipping_point: "",
    minimize: "",
    global: "",
    status: ""
  }

  @defaults %{
    collective_identity: 0.5,
    tipping_point: 0.333,
    minimize: false,
    global: false,
    status: "pending"
  }

  def assert_equivalent(expected, result) do
    assert expected.status == result.status
    assert expected.collective_identity == result.collective_identity
    assert expected.tipping_point == result.tipping_point
    assert expected.minimize == result.minimize
  end

  describe "list_scenarios/1" do

    test "returns records matching a ScenarioSet" do
      create_scenario() # should not be returned

      %{scenario: first, scenario_set: scenario_set, decision: decision} = create_scenario()
      first_id = first.id
      %{scenario: second} = create_scenario(scenario_set)
      second_id = second.id

      json_stats = "
      [ {\"scenario_id\": #{first_id},  \"ethelo\": 0.2},  {\"scenario_id\": #{second_id},  \"ethelo\": 0.5 }]
      "

      ScenarioSet |> where(id: ^scenario_set.id) |> Repo.update_all(set: [json_stats: json_stats])
      scenario_set = Scenarios.get_scenario_set(scenario_set.id, decision)

      result = Scenarios.list_scenarios(scenario_set, %{all: true})
      assert [%Scenario{id: ^second_id}, %Scenario{id: ^first_id}] = result
    end

    test "returns record matching id" do
      %{scenario: matching, scenario_set: scenario_set} = create_scenario()
      %{scenario: _not_matching} = create_scenario(scenario_set)

      filters = %{id: matching.id, all: true}
      result = Scenarios.list_scenarios(scenario_set, filters)

      assert [%Scenario{}] = result
      assert_result_ids_match([matching], result)
    end

    test "returns only successful scenarios by default" do
      %{scenario_set: scenario_set} = create_scenario_set()
      %{scenario: _first} = create_scenario(scenario_set, %{status: "pending"}) # should not be returned
      %{scenario: second} = create_scenario(scenario_set, %{status: "success"})

      result = Scenarios.list_scenarios(scenario_set)
      assert [%Scenario{}] = result
      assert_result_ids_match([second], result)
    end

    test "returns all scenarios with all flag" do
      %{scenario_set: scenario_set} = create_scenario_set()
      %{scenario: first} = create_scenario(scenario_set, %{status: "pending"})
      %{scenario: second} = create_scenario(scenario_set, %{status: "success"})

      result = Scenarios.list_scenarios(scenario_set, %{all: true})
      assert [%Scenario{}, %Scenario{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "raises without a ScenarioSet" do
      assert_raise ArgumentError, ~r/ScenarioSet/,
        fn -> Scenarios.list_scenarios(nil) end
    end
  end

  describe "get_global_scenario/1" do

    test "returns global record in a ScenarioSet" do
      %{scenario_set: scenario_set} = create_scenario_set()
      create_scenario(scenario_set, %{global: false}) # should not be returned

      %{scenario: scenario} = create_scenario(scenario_set, %{global: true})

      %{scenario_set: scenario_set2} = create_scenario_set()
      create_scenario(scenario_set2) # should not be returned

      result = Scenarios.get_global_scenario(scenario_set)
      assert %Scenario{} = result
      assert_result_ids_match([scenario], [result])
    end

    test "raises without a ScenarioSet" do
      assert_raise ArgumentError, ~r/ScenarioSet/,
        fn -> Scenarios.get_global_scenario(nil) end
    end
  end

  describe "get_scenario/2" do
    test "returns the matching record by ScenarioSet object" do
      %{scenario: record, scenario_set: scenario_set} = create_scenario()

      result = Scenarios.get_scenario(record.id, scenario_set)

      assert %Scenario{} = result
      assert result.id == record.id
    end

    test "returns the matching record by ScenarioSet.id" do
      %{scenario: record, scenario_set: scenario_set} = create_scenario()

      result = Scenarios.get_scenario(record.id, scenario_set.id)

      assert %Scenario{} = result
      assert result.id == record.id
    end

    test "raises without a ScenarioSet" do
      assert_raise ArgumentError, ~r/ScenarioSet/,
        fn -> Scenarios.get_scenario(1, nil) end
    end

    test "raises without a Scenario id" do
      %{scenario_set: scenario_set} = create_scenario_set()
      assert_raise ArgumentError, ~r/Scenario/,
        fn -> Scenarios.get_scenario(nil, scenario_set) end
    end

    test "returns nil if id does not exist" do
      %{scenario_set: scenario_set} = create_scenario_set()

      result = Scenarios.get_scenario(1929, scenario_set.id)
      assert result == nil
    end

    test "returns nil with invalid scenario_set id " do
      %{scenario: record} = create_scenario()
      %{scenario_set: scenario_set} = create_scenario_set()

      result = Scenarios.get_scenario(record.id, scenario_set)

      assert result == nil
    end
  end

  describe "create_scenario/2" do
    test "creates with valid data" do
      deps = scenario_deps()
      %{scenario_set: scenario_set} = deps
      attrs = valid_attrs(deps)

      result = Scenarios.create_scenario(scenario_set, attrs)

      assert {:ok, %Scenario{} = new_record} = result

      assert_equivalent(attrs, new_record)
      assert new_record.scenario_set_id == scenario_set.id
    end

    test "creates with default data" do
      deps = scenario_deps()
      %{scenario_set: scenario_set} = deps
      attrs = %{collective_identity: 0.5, tipping_point: 0.333, minimize: false, global: false, status: "pending"}

      result = Scenarios.create_scenario(scenario_set, attrs)

      assert {:ok, %Scenario{collective_identity: 0.5, tipping_point: 0.333, minimize: false, global: false, status: "pending"} = new_record} = result
      expected = Map.merge(attrs, @defaults)

      assert_equivalent(expected, new_record)
      assert new_record.scenario_set.id == scenario_set.id
    end

    test "raises without a ScenarioSet" do
      assert_raise ArgumentError, ~r/ScenarioSet/,
        fn -> Scenarios.create_scenario(nil, @invalid_attrs) end
    end

    test "with nil data returns errors" do
      %{scenario_set: scenario_set} = create_scenario_set()
      attrs = @nil_attrs

      result = Scenarios.create_scenario(scenario_set, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      refute :slug in Map.keys(errors)
      assert [_, _, _, _, _] = Map.keys(errors)
    end

    test "with invalid data returns errors" do
      %{scenario_set: scenario_set} = create_scenario_set()
      attrs = @invalid_attrs

      result = Scenarios.create_scenario(scenario_set, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert [_, _, _, _, _] = Map.keys(errors)
    end
  end

  describe "update_scenario/2" do
    test "updates with valid data" do
      deps = create_scenario()
      %{scenario: existing} = deps

      attrs = valid_attrs(deps)

      result = Scenarios.update_scenario(existing, attrs)

      assert {:ok, %Scenario{} = updated} = result

      assert_equivalent(attrs, updated)
    end

    test "nil data returns errors" do
      deps = create_scenario()
      %{scenario: existing} = deps
     attrs = @nil_attrs

      result = Scenarios.update_scenario(existing, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert [_, _, _, _, _] = Map.keys(errors)
    end

    test "invalid data returns errors" do
      %{scenario: existing} = create_scenario()
      attrs = @invalid_attrs

      result = Scenarios.update_scenario(existing, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert [_, _, _, _, _] = Map.keys(errors)
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
