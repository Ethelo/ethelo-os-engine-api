defmodule EtheloApi.Graphql.Resolvers.DecisionTest do
  @moduledoc """
  Validations and basic access for Decision resolver
  through graphql.
  Note: Functionality is provided through the DecisionResolver.Decision context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Structure.DecisionTest`

  """
  use EtheloApi.DataCase
  @moduletag decision: true, graphql: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.DecisionHelper
  import EtheloApi.TestHelper.ImportHelper, only: [valid_import: 0, invalid_import: 0]

  alias Ecto.Changeset
  alias EtheloApi.Blueprints.SimpleDecision
  alias EtheloApi.Graphql.Resolvers.Decision, as: DecisionResolver
  alias EtheloApi.Invocation
  alias EtheloApi.Scenarios.Factory, as: ScenariosFactory
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision

  def test_list_filtering(field_name) do
    to_match = create_decision()
    _excluded = create_decision()

    args = %{} |> Map.put(field_name, Map.get(to_match, field_name))

    result = DecisionResolver.list(args, nil)

    assert {:ok, result} = result
    assert [%Decision{}] = result
    assert_result_ids_match([to_match], result)
  end

  describe "list/2" do
    test "without filter returns all records" do
      to_match1 = create_decision()
      to_match2 = create_decision()

      params = %{}
      result = DecisionResolver.list(params, nil)

      assert {:ok, result} = result
      assert [%Decision{}, %Decision{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "filters by id" do
      test_list_filtering(:id)
    end

    test "filters by slug" do
      test_list_filtering(:slug)
    end

    test "filters by keywords" do
      to_match = create_decision(%{keywords: ["foo"]})
      # not an exact match
      create_decision(%{keywords: ["foo_bar"]})
      create_decision()

      params = %{keywords: ["foo"]}
      result = DecisionResolver.list(params, nil)

      assert {:ok, result} = result
      assert [%Decision{}] = result
      assert_result_ids_match([to_match], result)
    end
  end

  describe "calculated fields" do
    test "export" do
      decision = create_decision()

      result = DecisionResolver.export(decision, nil, nil)

      assert {:ok, json} = result
      assert is_binary(json)
    end

    test "Solve Files" do
      %{
        decision: decision,
        scenario_config: scenario_config,
        participants: %{one: participant}
      } = SimpleDecision.build()

      params =
        %{
          decision_id: decision.id,
          scenario_config_id: scenario_config.id,
          use_cache: false,
          participant_id: participant.id
        }

      result = DecisionResolver.solve_files(decision, params, nil)

      assert {:ok, solve_files} = result

      refute is_nil(Map.get(solve_files, :config_json))
      refute is_nil(Map.get(solve_files, :decision_json))
      refute is_nil(Map.get(solve_files, :influents_json))
      refute is_nil(Map.get(solve_files, :weights_json))
      refute is_nil(Map.get(solve_files, :hash))
    end

    test "Decision cache exists" do
      decision = create_decision()

      ScenariosFactory.create_cache(decision, %{
        key: Invocation.decision_key(),
        value: "fobar"
      })

      result = DecisionResolver.decision_cache_exists(decision, nil, nil)
      assert {:ok, true} = result
    end

    test "Decision cache missing" do
      decision = create_decision()
      result = DecisionResolver.decision_cache_exists(decision, nil, nil)
      assert {:ok, false} = result
    end

    test "ScenarioConfig cache exists" do
      %{decision: decision, scenario_config: scenario_config} = create_scenario_config()

      ScenariosFactory.create_cache(decision, %{
        key: Invocation.scenario_config_key(scenario_config.id),
        value: "fobar"
      })

      result =
        DecisionResolver.config_cache_exists(
          decision,
          %{scenario_config_id: scenario_config.id},
          nil
        )

      assert {:ok, true} == result
    end

    test "ScenarioConfig cache missing" do
      %{decision: decision, scenario_config: scenario_config} = create_scenario_config()

      result =
        DecisionResolver.config_cache_exists(
          decision,
          %{scenario_config_id: scenario_config.id},
          nil
        )

      assert {:ok, false} == result
    end
  end

  describe "create/2" do
    test "creates with valid data" do
      attrs = valid_attrs()
      params = %{input: attrs}
      result = DecisionResolver.create(params, nil)

      assert {:ok, %Decision{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "invalid data returns changeset" do
      params = %{input: invalid_attrs()}
      result = DecisionResolver.create(params, nil)

      assert {:ok, %Ecto.Changeset{} = changeset} = result
      errors = changeset |> error_map()

      expected = [:title, :slug, :copyable, :max_users, :language, :keywords]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "imports/2" do
    test "imports with valid data and import" do
      attrs = valid_attrs() |> Map.put(:json_data, valid_import())
      params = %{input: attrs}
      result = DecisionResolver.import(params, nil)

      assert {:ok, %Decision{} = new_record} = result

      assert attrs.title == new_record.title
      assert attrs.slug == new_record.slug
      assert attrs.keywords == new_record.keywords
      assert attrs.language == new_record.language
      assert attrs.info == new_record.info

      refute nil == Structure.get_decision(new_record.id)
    end

    test "invalid attrs returns error list" do
      attrs = valid_attrs() |> Map.put(:title, " ") |> Map.put(:json_data, valid_import())
      params = %{input: attrs}

      result = DecisionResolver.import(params, nil)

      assert {:error, [error]} = result

      assert :title == error.field
      assert :required == error.code
      assert "can't be blank" == error.message
    end

    test "invalid import returns error list" do
      attrs = valid_attrs() |> Map.put(:json_data, invalid_import())
      params = %{input: attrs}

      result = DecisionResolver.import(params, nil)

      assert {:error, [error]} = result

      assert :options == error.field
      assert :import_error == error.code
      expected = "Could Not Import options: Input 1 option_category_id can't be blank"
      assert expected == error.message
    end
  end

  describe "copy/2" do
    test "copies with valid data" do
      decision = create_decision()

      attrs = valid_attrs() |> Map.put(:decision, decision)
      params = %{input: attrs}
      result = DecisionResolver.copy(params, nil)

      assert {:ok, %Decision{} = new_record} = result

      assert attrs.title == new_record.title
      assert attrs.slug == new_record.slug
      assert attrs.keywords == new_record.keywords
      assert attrs.language == new_record.language
      assert attrs.info == new_record.info

      refute nil == Structure.get_decision(new_record.id)
    end

    test "invalid attrs returns error list" do
      decision = create_decision()

      attrs = valid_attrs() |> Map.put(:title, " ") |> Map.put(:decision, decision)

      params = %{input: attrs}

      result = DecisionResolver.copy(params, nil)

      assert {:error, [%ValidationMessage{} = error]} = result
      assert :title == error.field
      assert :required == error.code
      assert "can't be blank" == error.message
    end
  end

  describe "update/2" do
    test "updates with valid data" do
      decision = create_decision()
      attrs = valid_attrs() |> Map.put(:id, decision.id)
      params = %{input: attrs}
      result = DecisionResolver.update(params, nil)

      assert {:ok, %Decision{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "invalid data returns changeset" do
      decision = create_decision()
      attrs = invalid_attrs() |> Map.put(:id, decision.id)

      params = %{input: attrs}
      result = DecisionResolver.update(params, nil)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> error_map()
      expected = [:title, :slug, :copyable, :max_users, :language, :keywords]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "update_cache/2" do
    test "updates" do
      decision = create_decision()
      params = %{input: %{id: decision.id}}
      result = DecisionResolver.update_cache(params, nil)

      assert {:ok, decision} = result
      refute nil == Invocation.get_decision_cache_value(decision.id)
    end
  end

  describe "delete/2" do
    test "deletes" do
      to_delete = create_decision()

      params = %{input: %{id: to_delete.id}}
      result = DecisionResolver.delete(params, nil)

      assert {:ok, %Decision{}} = result
      assert nil == Structure.get_decision(to_delete.id)
    end

    test "when record does not exist return successful nil" do
      to_delete = create_decision()
      delete_decision(to_delete.id)
      params = %{input: %{id: to_delete.id}}
      result = DecisionResolver.delete(params, nil)
      assert {:ok, nil} = result
    end
  end
end
