defmodule EtheloApi.Graphql.Resolvers.ScenarioConfigTest do
  @moduledoc """
  Validations and basic access for ScenarioConfig resolver
  through graphql.
  Note: Functionality is provided through the ScenarioConfigResolver.ScenarioConfig context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Structure.ScenarioConfigTest`

  """
  use EtheloApi.DataCase
  @moduletag scenario_config: true, graphql: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.ScenarioConfigHelper

  alias EtheloApi.Graphql.Resolvers.ScenarioConfig, as: ScenarioConfigResolver
  alias EtheloApi.Invocation
  alias EtheloApi.Structure
  alias EtheloApi.Structure.ScenarioConfig

  def test_list_filtering(field_name) do
    %{scenario_config: to_match, decision: decision} = create_scenario_config()
    %{scenario_config: _excluded} = create_scenario_config(decision)
    test_list_filtering(field_name, to_match, decision)
  end

  def test_list_filtering(field_name, to_match, decision) do
    parent = %{decision: decision}
    args = %{} |> Map.put(field_name, Map.get(to_match, field_name))
    result = ScenarioConfigResolver.list(parent, args, nil)

    assert {:ok, result} = result
    assert [%ScenarioConfig{}] = result
    assert_result_ids_match([to_match], result)
  end

  describe "list/2" do
    test "filters by decision_id" do
      %{scenario_config: duplicate, decision: decision} = create_scenario_config()
      %{scenario_config: to_update} = create_scenario_config(decision)

      parent = %{decision: decision}
      args = %{}
      result = ScenarioConfigResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%ScenarioConfig{}, %ScenarioConfig{}] = result
      assert_result_ids_match([duplicate, to_update], result)
    end

    test "filters by id" do
      test_list_filtering(:id)
    end

    test "filters by slug" do
      test_list_filtering(:slug)
    end

    test "filters by enabled" do
      decision = create_decision()
      %{scenario_config: to_match} = create_scenario_config(decision, %{enabled: true})
      %{scenario_config: _excluded} = create_scenario_config(decision, %{enabled: false})
      test_list_filtering(:enabled, to_match, decision)
    end

    test "no matching records" do
      decision = create_decision()

      parent = %{decision: decision}
      args = %{}
      result = ScenarioConfigResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [] = result
    end
  end

  describe "create/2" do
    test "creates with valid data" do
      %{decision: decision} = deps = scenario_config_deps()

      attrs = deps |> valid_attrs()
      params = to_graphql_input_params(attrs, decision)

      result = ScenarioConfigResolver.create(params, nil)
      assert {:ok, %ScenarioConfig{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "invalid data returns changeset" do
      %{decision: decision} = deps = scenario_config_deps()

      attrs = deps |> invalid_attrs()
      params = to_graphql_input_params(attrs, decision)
      result = ScenarioConfigResolver.create(params, nil)

      assert {:error, %Changeset{} = changeset} = result

      errors = changeset |> error_map()

      expected = [
        :bins,
        :enabled,
        :engine_timeout,
        :max_scenarios,
        :normalize_influents,
        :normalize_satisfaction,
        :quadratic,
        :skip_solver,
        :slug,
        :support_only,
        :title,
        :ttl,
        :quad_user_seeds,
        :quad_total_available,
        :quad_cutoff,
        :quad_round_to,
        :quad_max_allocation,
        :quad_seed_percent,
        :quad_vote_percent,
        :ci,
        :tipping_point
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "update/2" do
    test "updates with valid data" do
      %{decision: decision} = deps = create_scenario_config()

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = ScenarioConfigResolver.update(params, nil)
      assert {:ok, %ScenarioConfig{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "invalid ScenarioConfig returns error" do
      %{decision: decision, scenario_config: to_delete} = deps = create_scenario_config()
      delete_scenario_config(to_delete.id)

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = ScenarioConfigResolver.update(params, nil)
      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "Decision mismatch returns changeset" do
      deps = create_scenario_config()
      decision = create_decision()
      deps = Map.put(deps, :decision, decision)

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = ScenarioConfigResolver.update(params, nil)
      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "invalid data returns changeset" do
      %{decision: decision} = deps = create_scenario_config()
      attrs = invalid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)
      result = ScenarioConfigResolver.update(params, nil)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> error_map()

      expected = [
        :bins,
        :enabled,
        :engine_timeout,
        :max_scenarios,
        :normalize_influents,
        :normalize_satisfaction,
        :quadratic,
        :skip_solver,
        :slug,
        :support_only,
        :title,
        :ttl,
        :quad_user_seeds,
        :quad_total_available,
        :quad_cutoff,
        :quad_round_to,
        :quad_max_allocation,
        :quad_seed_percent,
        :quad_vote_percent,
        :ci,
        :tipping_point
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "update_cache/2" do
    test "updates " do
      %{decision: decision, scenario_config: scenario_config} = create_scenario_config()

      attrs = %{decision_id: decision.id, id: scenario_config.id}
      params = to_graphql_input_params(attrs, decision)

      result = ScenarioConfigResolver.update_cache(params, nil)
      assert {:ok, %ScenarioConfig{}} = result
      refute nil == Invocation.get_scenario_config_cache_value(scenario_config.id, decision.id)
    end

    test "invalid ScenarioConfig returns error" do
      %{decision: decision, scenario_config: to_delete} = create_scenario_config()

      delete_scenario_config(to_delete.id)

      attrs = %{decision_id: decision.id, id: to_delete.id}
      params = to_graphql_input_params(attrs, decision)

      result = ScenarioConfigResolver.update(params, nil)
      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "Decision mismatch returns changeset" do
      %{scenario_config: scenario_config} = create_scenario_config()
      decision = create_decision()

      attrs = %{decision_id: decision.id, id: scenario_config.id}
      params = to_graphql_input_params(attrs, decision)

      result = ScenarioConfigResolver.update(params, nil)
      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end
  end

  describe "delete/2" do
    test "deletes" do
      %{decision: decision, scenario_config: _duplicate} = create_scenario_config()
      %{scenario_config: to_update} = create_scenario_config(decision)

      attrs = %{decision_id: decision.id, id: to_update.id}
      params = to_graphql_input_params(attrs, decision)
      result = ScenarioConfigResolver.delete(params, nil)

      assert {:ok, %ScenarioConfig{}} = result
      assert nil == Structure.get_scenario_config(to_update.id, decision)
    end

    test "when record does not exist return successful nil" do
      %{decision: decision, scenario_config: to_delete} = create_scenario_config()
      delete_scenario_config(to_delete.id)

      attrs = %{decision_id: decision.id, id: to_delete.id}
      params = to_graphql_input_params(attrs, decision)
      result = ScenarioConfigResolver.delete(params, nil)

      assert {:ok, nil} = result
    end

    test "deleting last ScenarioConfig returns changeset" do
      %{decision: decision, scenario_config: last_scenario_config} = create_scenario_config()

      attrs = %{decision_id: decision.id, id: last_scenario_config.id}
      params = to_graphql_input_params(attrs, decision)
      result = ScenarioConfigResolver.delete(params, nil)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "cannot be deleted" in errors.id
      refute nil == Structure.get_scenario_config(last_scenario_config.id, decision)
    end
  end
end
