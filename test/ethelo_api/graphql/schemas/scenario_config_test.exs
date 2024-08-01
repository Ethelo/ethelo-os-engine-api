defmodule EtheloApi.Graphql.Schemas.ScenarioConfigTest do
  @moduledoc """
  Test graphql queries for ScenarioConfigs
  """
  use EtheloApi.Graphql.SchemaCase
  @moduletag scenario_config: true, graphql: true

  alias EtheloApi.Structure
  alias EtheloApi.Invocation
  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.ScenarioConfigHelper

  describe "decision => scenario_configs query" do
    test "without filter returns all records" do
      %{scenario_config: to_match1, decision: decision} = create_scenario_config()
      %{scenario_config: to_match2} = create_scenario_config(decision)
      %{scenario_config: _excluded} = create_scenario_config()

      to_match1 = to_match1 |> rename_ci() |> decimals_to_floats()
      to_match2 = to_match2 |> rename_ci() |> decimals_to_floats()

      assert_list_many_query(
        "scenarioConfigs",
        decision.id,
        %{},
        [to_match1, to_match2],
        fields()
      )
    end

    test "filters by id" do
      %{scenario_config: to_match, decision: decision} = create_scenario_config()
      %{scenario_config: _excluded} = create_scenario_config(decision)
      to_match = to_match |> rename_ci() |> decimals_to_floats()

      assert_list_one_query("scenarioConfigs", to_match, [:id], fields([:id]))
    end

    test "filters by slug" do
      %{scenario_config: to_match, decision: decision} = create_scenario_config()
      %{scenario_config: _excluded} = create_scenario_config(decision)

      assert_list_one_query("scenarioConfigs", to_match, [:slug], fields([:slug]))
    end

    test "no matching records" do
      decision = create_decision()

      assert_list_none_query("scenarioConfigs", %{decision_id: decision.id}, [:id])
    end
  end

  describe "createScenarioConfig mutation" do
    test "creates with valid data" do
      %{decision: decision} = deps = scenario_config_deps()

      field_names = input_field_names()

      attrs =
        deps |> valid_attrs() |> rename_ci() |> decimals_to_floats() |> Map.take(field_names)

      requested_fields = Map.keys(attrs) ++ [:id]

      payload = run_mutate_one_query("createScenarioConfig", decision.id, attrs, requested_fields)

      assert_mutation_success(attrs, payload, fields(field_names))
      refute nil == get_in(payload, ["result", "id"])
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = scenario_config_deps()

      invalid = Map.take(invalid_attrs(), [:title])
      field_names = input_field_names()

      attrs =
        deps
        |> valid_attrs()
        |> Map.merge(invalid)
        |> rename_ci()
        |> decimals_to_floats()
        |> Map.take(field_names)

      requested_fields = Map.keys(attrs) ++ [:id]

      payload = run_mutate_one_query("createScenarioConfig", decision.id, attrs, requested_fields)

      expected = [%ValidationMessage{code: :required, field: :title}]
      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid Decision returns error" do
      %{decision: decision} = deps = scenario_config_deps()
      delete_decision(decision)

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("createScenarioConfig", decision.id, attrs)

      expected = [%ValidationMessage{code: :not_found, field: "decisionId"}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "updateScenarioConfig mutation" do
    test "updates with valid data" do
      %{decision: decision} = deps = create_scenario_config()

      field_names = input_field_names() ++ [:id]

      attrs =
        deps
        |> valid_attrs()
        |> rename_ci()
        |> decimals_to_floats()
        |> Map.take(field_names)

      payload = run_mutate_one_query("updateScenarioConfig", decision.id, attrs)

      assert_mutation_success(attrs, payload, fields(field_names))
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = create_scenario_config()
      invalid = Map.take(invalid_attrs(), [:title])

      field_names = [:title, :slug, :id]
      attrs = deps |> valid_attrs() |> Map.merge(invalid) |> Map.take(field_names)

      payload = run_mutate_one_query("updateScenarioConfig", decision.id, attrs)

      expected = [%ValidationMessage{code: :required, field: :title}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid ScenarioConfig returns error" do
      %{scenario_config: to_delete, decision: decision} = deps = create_scenario_config()
      delete_scenario_config(to_delete)

      field_names = [:id, :title]
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("updateScenarioConfig", decision.id, attrs)

      expected = [%ValidationMessage{code: "not_found", field: :id}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "cacheScenarioConfig mutation" do
    test "updates" do
      %{decision: decision, scenario_config: scenario_config} = create_scenario_config()

      attrs = %{id: scenario_config.id}

      payload = run_mutate_one_query("cacheScenarioConfig", decision.id, attrs)

      assert_mutation_success(
        %{cache_present: true},
        payload,
        fields([:cache_present])
      )

      refute nil == Invocation.get_scenario_config_cache_value(scenario_config.id, decision.id)
    end

    test "invalid ScenarioConfig returns error" do
      %{scenario_config: to_delete, decision: decision} = create_scenario_config()
      delete_scenario_config(to_delete)

      attrs = %{id: to_delete.id}

      payload = run_mutate_one_query("cacheScenarioConfig", decision.id, attrs)

      expected = [%ValidationMessage{code: "not_found", field: :id}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "deleteScenarioConfig mutation" do
    test "deletes when is not only ScenarioConfig" do
      %{decision: decision, scenario_config: _first} = create_scenario_config()
      %{scenario_config: to_delete} = create_scenario_config(decision)

      attrs = to_delete |> Map.take([:id])
      payload = run_mutate_one_query("deleteScenarioConfig", decision.id, attrs)
      assert_mutation_success(%{}, payload, %{})

      assert nil == Structure.get_scenario_config(to_delete.id, decision)
    end

    test "deleting only ScenarioConfig returns errors" do
      %{decision: decision, scenario_config: last_scenario_config} = create_scenario_config()

      attrs = last_scenario_config |> Map.take([:id])
      payload = run_mutate_one_query("deleteScenarioConfig", decision.id, attrs)
      expected = [%ValidationMessage{code: :protected_record, field: :id}]

      assert_mutation_failure(expected, payload, [:field, :code])
      refute nil == Structure.get_scenario_config(last_scenario_config.id, decision)
    end
  end
end
