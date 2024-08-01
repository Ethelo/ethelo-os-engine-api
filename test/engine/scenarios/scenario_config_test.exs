defmodule Engine.Scenarios.ScenarioConfigTest do
  @moduledoc """
  Validations and basic access for ScenarioConfigs
  Includes both the context Engine.Scenarios, and specific functionality on the ScenarioConfig schema
  """
  use EtheloApi.DataCase
  @moduletag scenario_config: true, ethelo: true, ecto: true
  
  import EtheloApi.Structure.Factory
  import Engine.Scenarios.Factory
  import EtheloApi.Structure.TestHelper.ScenarioConfigHelper

  alias Engine.Scenarios
  alias EtheloApi.Structure.Decision
  alias Engine.Scenarios.ScenarioConfig


  describe "list_scenario_configs/1" do

    test "returns records matching a Decision" do
      create_scenario_config() # should not be returned
      %{scenario_config: first, decision: decision} = create_scenario_config()
      %{scenario_config: second} = create_scenario_config(decision)

      result = Scenarios.list_scenario_configs(decision)
      assert [%ScenarioConfig{}, %ScenarioConfig{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "returns record matching id" do
      %{scenario_config: matching, decision: decision} = create_scenario_config()
      %{scenario_config: _not_matching} = create_scenario_config(decision)

      filters = %{id: matching.id}
      result = Scenarios.list_scenario_configs(decision, filters)

      assert [%ScenarioConfig{}] = result
      assert_result_ids_match([matching], result)
    end

    test "returns record matching slug" do
      %{scenario_config: matching, decision: decision} = create_scenario_config()
      %{scenario_config: _not_matching} = create_scenario_config(decision)

      filters = %{slug: matching.slug}
      result = Scenarios.list_scenario_configs(decision, filters)

      assert [%ScenarioConfig{}] = result
      assert_result_ids_match([matching], result)
    end

    test "returns record matching enabled" do
      decision = create_decision()
      %{scenario_config: matching} = create_scenario_config(decision, %{enabled: true})
      %{scenario_config: _not_matching} = create_scenario_config(decision, %{enabled: false})

      filters = %{enabled: matching.enabled}
      result = Scenarios.list_scenario_configs(decision, filters)

      assert [%ScenarioConfig{}] = result
      assert_result_ids_match([matching], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Scenarios.list_scenario_configs(nil) end
    end
  end

  describe "get_scenario_config/2" do
    test "returns the matching record by Decision object" do
      %{scenario_config: record, decision: decision} = create_scenario_config()

      result = Scenarios.get_scenario_config(record.id, decision)

      assert %ScenarioConfig{} = result
      assert result.id == record.id
    end

    test "returns the matching record by Decision.id" do
      %{scenario_config: record, decision: decision} = create_scenario_config()

      result = Scenarios.get_scenario_config(record.id, decision.id)

      assert %ScenarioConfig{} = result
      assert result.id == record.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Scenarios.get_scenario_config(1, nil) end
    end

    test "raises without a ScenarioConfig id" do
      assert_raise ArgumentError, ~r/ScenarioConfig/,
        fn -> Scenarios.get_scenario_config(nil, create_decision()) end
    end

    test "returns nil if id does not exist" do
      decision = create_decision()

      result = Scenarios.get_scenario_config(1929, decision.id)
      assert result == nil
    end

    test "returns nil with invalid decision id " do
      %{scenario_config: record} = create_scenario_config()
      decision2 = create_decision()

      result = Scenarios.get_scenario_config(record.id, decision2)

      assert result == nil
    end
  end

  describe "create_scenario_config/2" do
    test "creates with valid data" do
      deps = scenario_config_deps()
      %{decision: decision} = deps
      attrs = valid_attrs(deps)

      result = Scenarios.create_scenario_config(decision, attrs)

      assert {:ok, %ScenarioConfig{} = new_record} = result

      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "creates with default data" do
      deps = scenario_config_deps()
      %{decision: decision} = deps
      attrs = %{title: "foo", slug: "foo"}

      result = Scenarios.create_scenario_config(decision, attrs)

      assert {:ok, %ScenarioConfig{} = new_record} = result
      expected = Map.merge(default_attrs(), attrs)

      assert_equivalent(expected, new_record)
      assert new_record.decision.id == decision.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Scenarios.create_scenario_config(nil, invalid_attrs()) end
    end

    test "with nil data returns errors" do
      decision = create_decision()
      attrs = empty_attrs()

      result = Scenarios.create_scenario_config(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "can't be blank" in errors.title
      assert "can't be blank" in errors.bins
      assert "can't be blank" in errors.support_only
      assert "can't be blank" in errors.quadratic
      assert "can't be blank" in errors.normalize_satisfaction
      assert "can't be blank" in errors.normalize_influents
      assert "can't be blank" in errors.skip_solver
      assert "can't be blank" in errors.max_scenarios
      assert "can't be blank" in errors.enabled
      assert "can't be blank" in errors.ttl
      assert "can't be blank" in errors.engine_timeout
      assert [:bins, :enabled, :engine_timeout, :max_scenarios,
             :normalize_influents, :normalize_satisfaction, :quadratic,
             :skip_solver, :slug, :support_only, :title, :ttl] = Map.keys(errors) #12
    end

    test "with invalid data returns errors" do
      decision = create_decision()
      attrs = invalid_attrs()

      result = Scenarios.create_scenario_config(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert_invalid_data_errors(errors)
    end

    test "with invalid quad data returns errors" do
      decision = create_decision()
      attrs = invalid_quad()

      result = Scenarios.create_scenario_config(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "must be greater than 1" in errors.quad_user_seeds
      assert "must be greater than 1" in errors.quad_total_available
      assert "must be greater than 1" in errors.quad_cutoff
      assert "must be greater than 1" in errors.quad_round_to
      assert "can't be blank" in errors.quad_max_allocation
      assert "can't be blank" in errors.quad_seed_percent
      assert "can't be blank" in errors.quad_vote_percent
        assert [:quad_cutoff, :quad_max_allocation, :quad_round_to,
             :quad_seed_percent, :quad_total_available, :quad_user_seeds,
             :quad_vote_percent] = Map.keys(errors) #7
    end

    test "duplicate title with no slug defined generates variant slug" do
      %{scenario_config: existing, decision: decision} = deps = create_scenario_config()

      attrs = deps |> valid_attrs() |> Map.put(:title, existing.title) |> Map.drop([:slug])
      result = Scenarios.create_scenario_config(decision, attrs)

      assert {:ok, %ScenarioConfig{} = new_record} = result

      refute existing.slug == new_record.slug
    end

    test "duplicate slug returns errors" do
      %{scenario_config: existing, decision: decision} = deps = create_scenario_config()
      attrs = deps |> valid_attrs() |> Map.put(:slug, existing.slug)

      result = Scenarios.create_scenario_config(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "update_scenario_config/2" do
    test "updates with valid data" do
      deps = create_scenario_config()
      %{scenario_config: existing} = deps

      attrs = valid_attrs(deps)

      result = Scenarios.update_scenario_config(existing, attrs)

      assert {:ok, %ScenarioConfig{} = updated} = result

      assert_equivalent(attrs, updated)
    end

    test "nil data returns errors" do
      deps = create_scenario_config()
      %{scenario_config: existing} = deps
     attrs = empty_attrs()

      result = Scenarios.update_scenario_config(existing, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "can't be blank" in errors.bins
      assert "can't be blank" in errors.support_only
      assert "can't be blank" in errors.quadratic
      assert "can't be blank" in errors.normalize_satisfaction
      assert "can't be blank" in errors.normalize_influents
      assert "can't be blank" in errors.max_scenarios
      assert "can't be blank" in errors.skip_solver
      assert "can't be blank" in errors.ttl
      assert "can't be blank" in errors.engine_timeout
      assert "can't be blank" in errors.enabled
      assert [:bins, :enabled, :engine_timeout, :max_scenarios,
             :normalize_influents, :normalize_satisfaction, :quadratic,
             :skip_solver, :slug, :support_only, :title, :ttl] = Map.keys(errors) #14
    end

    test "invalid data returns errors" do
      %{scenario_config: existing} = create_scenario_config()
      attrs = invalid_attrs()

      result = Scenarios.update_scenario_config(existing, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert_invalid_data_errors(errors)
    end

    test "ci checks error correctly" do
     %{scenario_config: scenario_config} = create_scenario_config()
     attrs = %{max_scenarios: -0.8, ci: Decimal.from_float(-0.3), tipping_point: Decimal.from_float(-0.1)}

      result = Scenarios.update_scenario_config(scenario_config, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "is invalid" in errors.max_scenarios
      assert "must be greater than or equal to 0" in errors.ci
      assert "must be greater than or equal to 0" in errors.tipping_point

    end

    test "Decision update ignored" do
      %{scenario_config: existing} = create_scenario_config()
      decision2 = create_decision()

      attrs = %{title: "foo", decision: decision2}
      result = Scenarios.update_scenario_config(existing, attrs)

      assert {:ok, updated} = result
      assert updated.title == attrs.title
      refute updated.decision.id == decision2.id
      assert updated.decision.id == existing.decision_id
    end

    test "duplicate title with no slug defined does not update slug" do
      %{scenario_config: first, decision: decision} = create_scenario_config()
      %{scenario_config: second} = deps = create_scenario_config(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, first.title) |> Map.drop([:slug])
      result = Scenarios.update_scenario_config(second, attrs)

      assert {:ok, %ScenarioConfig{} = updated} = result

      assert second.slug == updated.slug
    end

    test "duplicate title with nil slug defined generates variant slug" do
      %{scenario_config: first, decision: decision} = create_scenario_config()
      %{scenario_config: second} = deps = create_scenario_config(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, first.title) |> Map.put(:slug, nil)
      result = Scenarios.update_scenario_config(second, attrs)

      assert {:ok, %ScenarioConfig{} = updated} = result
      refute second.slug == updated.slug
      refute second.slug == first.slug
    end

    test "duplicate slug returns errors" do
      %{scenario_config: first, decision: decision} = create_scenario_config()
      %{scenario_config: second} = deps = create_scenario_config(decision)

      attrs = deps |> valid_attrs() |> Map.put(:slug, first.slug)
      result = Scenarios.update_scenario_config(second, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "delete_scenario_config/2" do

    test "deletes" do
      %{scenario_config: _first, decision: decision} = create_scenario_config()
      %{scenario_config: second} = create_scenario_config(decision)
      to_delete = %ScenarioConfig{id: second.id}

      result = Scenarios.delete_scenario_config(to_delete, decision.id)
      assert {:ok, %ScenarioConfig{}} = result
      assert nil == Repo.get(ScenarioConfig, second.id)
      assert nil !== Repo.get(Decision, decision.id)
    end

    test "deleting only ScenarioConfig returns error" do
      %{scenario_config: existing, decision: decision} = create_scenario_config()
      to_delete = %ScenarioConfig{id: existing.id}

      result = Scenarios.delete_scenario_config(to_delete, decision.id)
      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "cannot be deleted" in errors.id
      refute nil == Repo.get(ScenarioConfig, existing.id)
      assert nil !== Repo.get(Decision, decision.id)
    end
  end

  describe "documentation" do
    test "has documentation module" do
      assert %{} = ScenarioConfig.strings()
      assert %{} = ScenarioConfig.examples()
      assert is_list(ScenarioConfig.fields())
    end
  end
end
