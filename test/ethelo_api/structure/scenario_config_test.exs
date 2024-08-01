defmodule EtheloApi.Structure.ScenarioConfigTest do
  @moduledoc """
  Validations and basic access for ScenarioConfigs
  Includes both the context EtheloApi.Structure, and specific functionality on the ScenarioConfig schema
  """
  use EtheloApi.DataCase
  @moduletag scenario_config: true, ecto: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.ScenarioConfigHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.ScenarioConfig
  alias EtheloApi.Structure.Decision

  describe "list_scenario_configs/1" do
    test "filters by decision_id" do
      _excluded = create_scenario_config()
      %{scenario_config: to_match1, decision: decision} = create_scenario_config()
      %{scenario_config: to_match2} = create_scenario_config(decision)

      result = Structure.list_scenario_configs(decision)
      assert [%ScenarioConfig{}, %ScenarioConfig{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "filters by id" do
      %{scenario_config: to_match, decision: decision} = create_scenario_config()
      %{scenario_config: _excluded} = create_scenario_config(decision)

      modifiers = %{id: to_match.id}
      result = Structure.list_scenario_configs(decision, modifiers)

      assert [%ScenarioConfig{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by slug" do
      %{scenario_config: to_match, decision: decision} = create_scenario_config()
      %{scenario_config: _excluded} = create_scenario_config(decision)

      modifiers = %{slug: to_match.slug}
      result = Structure.list_scenario_configs(decision, modifiers)

      assert [%ScenarioConfig{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by enabled" do
      decision = create_decision()
      %{scenario_config: to_match} = create_scenario_config(decision, %{enabled: true})
      %{scenario_config: _excluded} = create_scenario_config(decision, %{enabled: false})

      modifiers = %{enabled: to_match.enabled}
      result = Structure.list_scenario_configs(decision, modifiers)

      assert [%ScenarioConfig{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Structure.list_scenario_configs(nil) end
    end
  end

  describe "get_scenario_config/2" do
    test "filters by decision_id as struct" do
      %{scenario_config: to_match, decision: decision} = create_scenario_config()

      result = Structure.get_scenario_config(to_match.id, decision)

      assert %ScenarioConfig{} = result
      assert result.id == to_match.id
    end

    test "filters by decision_id" do
      %{scenario_config: to_match, decision: decision} = create_scenario_config()

      result = Structure.get_scenario_config(to_match.id, decision.id)

      assert %ScenarioConfig{} = result
      assert result.id == to_match.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Structure.get_scenario_config(1, nil) end
    end

    test "raises without a ScenarioConfig id" do
      assert_raise ArgumentError, ~r/ScenarioConfig/, fn ->
        Structure.get_scenario_config(nil, create_decision())
      end
    end

    test "missing record returns nil" do
      decision = create_decision()

      result = Structure.get_scenario_config(1929, decision.id)
      assert result == nil
    end

    test "invalid Decision returns nil" do
      %{scenario_config: to_match} = create_scenario_config()
      decision2 = create_decision()

      result = Structure.get_scenario_config(to_match.id, decision2)

      assert result == nil
    end
  end

  describe "create_scenario_config/2" do
    test "creates with valid data" do
      deps = scenario_config_deps()
      %{decision: decision} = deps
      attrs = valid_attrs(deps)

      result = Structure.create_scenario_config(attrs, decision)

      assert {:ok, %ScenarioConfig{} = new_record} = result

      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn ->
        Structure.create_scenario_config(invalid_attrs(), nil)
      end
    end

    test "empty data returns changeset" do
      decision = create_decision()

      result = Structure.create_scenario_config(empty_attrs(), decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
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
        :ttl
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      decision = create_decision()
      attrs = invalid_attrs()

      result = Structure.create_scenario_config(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert_invalid_data_errors(errors)
    end

    test "invalid quad data returns changeset" do
      decision = create_decision()
      attrs = invalid_quad_attrs()

      result = Structure.create_scenario_config(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "must be greater than 1" in errors.quad_user_seeds
      assert "must be greater than 1" in errors.quad_total_available
      assert "must be greater than 1" in errors.quad_cutoff
      assert "must be greater than 1" in errors.quad_round_to
      assert "can't be blank" in errors.quad_max_allocation
      assert "can't be blank" in errors.quad_seed_percent
      assert "can't be blank" in errors.quad_vote_percent

      expected = [
        :quad_cutoff,
        :quad_max_allocation,
        :quad_round_to,
        :quad_seed_percent,
        :quad_total_available,
        :quad_user_seeds,
        :quad_vote_percent
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "duplicate title with no slug defined generates variant slug" do
      %{scenario_config: existing, decision: decision} = deps = create_scenario_config()

      attrs = deps |> valid_attrs() |> Map.put(:title, existing.title) |> Map.drop([:slug])
      result = Structure.create_scenario_config(attrs, decision)

      assert {:ok, %ScenarioConfig{} = new_record} = result

      refute existing.slug == new_record.slug
    end

    test "duplicate slug returns changeset" do
      %{scenario_config: existing, decision: decision} = deps = create_scenario_config()
      attrs = deps |> valid_attrs() |> Map.put(:slug, existing.slug)

      result = Structure.create_scenario_config(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "update_scenario_config/2" do
    test "updates with valid data" do
      %{scenario_config: to_update} = deps = create_scenario_config()

      attrs = valid_attrs(deps)

      result = Structure.update_scenario_config(to_update, attrs)

      assert {:ok, %ScenarioConfig{} = updated} = result

      assert_equivalent(attrs, updated)
    end

    test "empty data returns changeset" do
      %{scenario_config: to_update} = create_scenario_config()

      result = Structure.update_scenario_config(to_update, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
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
        :ttl
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      %{scenario_config: to_update} = create_scenario_config()
      attrs = invalid_attrs()

      result = Structure.update_scenario_config(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert_invalid_data_errors(errors)
    end

    test "ci checks error correctly" do
      %{scenario_config: to_update} = create_scenario_config()

      attrs = %{
        max_scenarios: -0.8,
        ci: Decimal.from_float(-0.3),
        tipping_point: Decimal.from_float(-0.1)
      }

      result = Structure.update_scenario_config(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "is invalid" in errors.max_scenarios
      assert "must be greater than or equal to 0" in errors.ci
      assert "must be greater than or equal to 0" in errors.tipping_point
    end

    test "Decision update ignored" do
      %{scenario_config: to_update} = create_scenario_config()
      decision2 = create_decision()

      attrs = %{title: "foo", decision: decision2}
      result = Structure.update_scenario_config(to_update, attrs)

      assert {:ok, updated} = result
      assert updated.title == attrs.title
      refute updated.decision.id == decision2.id
      assert updated.decision.id == to_update.decision_id
    end

    test "duplicate title with no slug defined does not update slug" do
      %{scenario_config: duplicate, decision: decision} = create_scenario_config()
      %{scenario_config: to_update} = deps = create_scenario_config(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, duplicate.title) |> Map.drop([:slug])
      result = Structure.update_scenario_config(to_update, attrs)

      assert {:ok, %ScenarioConfig{} = updated} = result

      assert to_update.slug == updated.slug
    end

    test "duplicate title with nil slug defined generates variant slug" do
      %{scenario_config: duplicate, decision: decision} = create_scenario_config()
      %{scenario_config: to_update} = deps = create_scenario_config(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, duplicate.title) |> Map.put(:slug, nil)
      result = Structure.update_scenario_config(to_update, attrs)

      assert {:ok, %ScenarioConfig{} = updated} = result
      refute to_update.slug == updated.slug
      refute to_update.slug == duplicate.slug
    end

    test "duplicate slug returns changeset" do
      %{scenario_config: duplicate, decision: decision} = create_scenario_config()
      %{scenario_config: to_update} = deps = create_scenario_config(decision)

      attrs = deps |> valid_attrs() |> Map.put(:slug, duplicate.slug)
      result = Structure.update_scenario_config(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "delete_scenario_config/2" do
    test "deletes if is not last " do
      %{scenario_config: _, decision: decision} = create_scenario_config()
      %{scenario_config: to_delete} = create_scenario_config(decision)

      result = Structure.delete_scenario_config(to_delete, decision.id)
      assert {:ok, %ScenarioConfig{}} = result
      assert nil == Repo.get(ScenarioConfig, to_delete.id)
      assert nil !== Repo.get(Decision, decision.id)
    end

    test "deleting last ScenarioConfig returns changeset" do
      %{scenario_config: to_delete, decision: decision} = create_scenario_config()

      result = Structure.delete_scenario_config(to_delete, decision.id)
      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "cannot be deleted" in errors.id
      refute nil == Repo.get(ScenarioConfig, to_delete.id)
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
