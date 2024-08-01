defmodule GraphQL.EtheloApi.Resolvers.ScenarioConfigTest do
  @moduledoc """
  Validations and basic access for "ScenarioConfig" resolver, used to load scenario_config records
  through graphql.
  Note: Functionality is provided through the ScenarioConfigResolver.ScenarioConfig context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `Engine.Scenarios.ScenarioConfigTest`

  """
  use EtheloApi.DataCase
  @moduletag scenario_config: true, graphql: true

  import EtheloApi.Structure.Factory
  import Engine.Scenarios.Factory
  import EtheloApi.Structure.TestHelper.ScenarioConfigHelper
  alias Kronky.ValidationMessage
  alias Engine.Scenarios
  alias Engine.Scenarios.ScenarioConfig
  alias Ecto.Changeset
  alias GraphQL.EtheloApi.Resolvers.ScenarioConfig, as: ScenarioConfigResolver

  describe "list/2" do
    test "returns all ScenarioConfigs for a Decision" do
      %{scenario_config: first, decision: decision} = create_scenario_config()
      %{scenario_config: second} = create_scenario_config(decision)

      parent = %{decision: decision}
      args = %{}
      result = ScenarioConfigResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%ScenarioConfig{}, %ScenarioConfig{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "filters by ScenarioConfig.id" do
      %{scenario_config: matching, decision: decision} = create_scenario_config()
      create_scenario_config(decision)

      parent = %{decision: decision}
      args = %{id: matching.id}
      result = ScenarioConfigResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%ScenarioConfig{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by ScenarioConfig.slug" do
      %{scenario_config: matching, decision: decision} = create_scenario_config()
      create_scenario_config(decision)

      parent = %{decision: decision}
      args = %{slug: matching.slug}
      result = ScenarioConfigResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%ScenarioConfig{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by ScenarioConfig.enabled" do
      decision = create_decision()
      %{scenario_config: matching} = create_scenario_config(decision, %{enabled: true})
      %{scenario_config: _not_matching} = create_scenario_config(decision, %{enabled: false})

      parent = %{decision: decision}
      args = %{enabled: matching.enabled}
      result = ScenarioConfigResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%ScenarioConfig{}] = result
      assert_result_ids_match([matching], result)
    end

    test "no ScenarioConfig matches" do
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
      %{decision: decision} = scenario_config_deps()

      attrs = valid_attrs(decision)
      result = ScenarioConfigResolver.create(decision, attrs)

      assert {:ok, %ScenarioConfig{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "returns a changeset with invalid data" do
       %{decision: decision} = scenario_config_deps()

      attrs = invalid_attrs()
      result = ScenarioConfigResolver.create(decision, attrs)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> errors_on() |> Map.keys()
      assert :title in errors
      assert :slug in errors
    end
  end

  describe "update/2" do

    test "updates with valid data" do
      %{decision: decision, scenario_config: existing} = create_scenario_config()

      attrs = valid_attrs(decision, existing)

      result = ScenarioConfigResolver.update(decision, attrs)
      assert {:ok, %ScenarioConfig{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "returns errors when ScenarioConfig does not exist" do
      %{decision: decision, scenario_config: existing} = create_scenario_config()
      delete_scenario_config(existing.id)

      attrs = valid_attrs(decision, existing)
      result = ScenarioConfigResolver.update(decision, attrs)

      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "returns errors when Decision does not match" do
      %{scenario_config: existing} = create_scenario_config()
      decision = create_decision()

      attrs = valid_attrs(decision, existing)
      result = ScenarioConfigResolver.update(decision, attrs)

      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "returns a changeset with invalid data" do
      %{decision: decision, scenario_config: existing} = create_scenario_config()

      attrs = invalid_attrs() |>  Map.put(:id, existing.id)
      result = ScenarioConfigResolver.update(decision, attrs)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> errors_on() |> Map.keys()
      assert :title in errors
      assert :slug in errors
    end
  end

  describe "delete/2" do
    test "deletes" do
      %{decision: decision, scenario_config: _first} = create_scenario_config()
      %{scenario_config: second} = create_scenario_config(decision)

      attrs = %{decision_id: decision.id, id: second.id}
      result = ScenarioConfigResolver.delete(decision, attrs)

      assert {:ok, %ScenarioConfig{}} = result
      assert nil == Scenarios.get_scenario_config(second.id, decision)
    end

    test "delete/2 does not return errors when ScenarioConfig does not exist" do
      %{decision: decision, scenario_config: existing} = create_scenario_config()
      delete_scenario_config(existing.id)

      attrs = %{decision_id: decision.id, id: existing.id}
      result = ScenarioConfigResolver.delete(decision, attrs)

      assert {:ok, nil} = result
    end

    test "returns error if deleting last scenario_config" do
      %{decision: decision, scenario_config: existing} = create_scenario_config()

      attrs = %{decision_id: decision.id, id: existing.id}
      result = ScenarioConfigResolver.delete(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "cannot be deleted" in errors.id
      refute nil == Scenarios.get_scenario_config(existing.id, decision)
    end
  end
end
