defmodule EtheloApi.Graphql.Resolvers.OptionCategoryTest do
  @moduledoc """
  Validations and basic access for OptionCategory resolver
  through graphql.
  Note: Functionality is provided through the OptionCategoryResolver.OptionCategory context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Structure.OptionCategoryTest`

  """
  use EtheloApi.DataCase
  @moduletag option_category: true, graphql: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.OptionCategoryHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.OptionCategory
  alias EtheloApi.Graphql.Resolvers.OptionCategory, as: OptionCategoryResolver

  def test_list_filtering(field_name) do
    %{option_category: to_match, decision: decision} = create_option_category()
    %{option_category: _excluded} = create_option_category(decision)

    parent = %{decision: decision}
    args = %{} |> Map.put(field_name, Map.get(to_match, field_name))
    result = OptionCategoryResolver.list(parent, args, nil)

    assert {:ok, result} = result
    assert [%OptionCategory{}] = result
    assert_result_ids_match([to_match], result)
  end

  describe "list/2" do
    test "filters by decision_id" do
      %{option_category: to_match1, decision: decision} = create_option_category()
      %{option_category: to_match2} = create_option_category(decision)
      %{option_category: _excluded} = create_option_category()

      parent = %{decision: decision}
      args = %{}
      result = OptionCategoryResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionCategory{}, %OptionCategory{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "filters by id" do
      test_list_filtering(:id)
    end

    test "filters by slug" do
      test_list_filtering(:slug)
    end

    test "no matching records" do
      decision = create_decision()

      parent = %{decision: decision}
      args = %{}
      result = OptionCategoryResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [] = result
    end
  end

  describe "create/2" do
    test "creates with valid data" do
      %{decision: decision} = deps = option_category_deps()

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = OptionCategoryResolver.create(params, nil)
      assert {:ok, %OptionCategory{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "invalid data returns changeset" do
      %{decision: decision} = deps = option_category_deps()

      attrs = invalid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)
      result = OptionCategoryResolver.create(params, nil)

      assert {:error, %Changeset{} = changeset} = result

      errors = changeset |> error_map()

      expected =
        [
          :apply_participant_weights,
          :budget_percent,
          :flat_fee,
          :info,
          :keywords,
          :quadratic,
          :results_title,
          :scoring_mode,
          :slug,
          :sort,
          :title,
          :triangle_base,
          :vote_on_percent,
          :voting_style,
          :weighting,
          :xor
        ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "update/2" do
    test "updates with valid data" do
      %{decision: decision} = deps = create_option_category()

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = OptionCategoryResolver.update(params, nil)
      assert {:ok, %OptionCategory{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "invalid OptionCategory returns error" do
      %{decision: decision, option_category: to_delete} = deps = create_option_category()
      delete_option_category(to_delete.id)

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = OptionCategoryResolver.update(params, nil)
      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "Decision mismatch returns changeset" do
      deps = create_option_category()
      decision = create_decision()
      deps = Map.put(deps, :decision, decision)

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = OptionCategoryResolver.update(params, nil)
      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "invalid data returns changeset" do
      %{decision: decision} = deps = create_option_category()

      attrs = invalid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)
      result = OptionCategoryResolver.update(params, nil)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> error_map()

      expected =
        [
          :apply_participant_weights,
          :budget_percent,
          :flat_fee,
          :info,
          :keywords,
          :quadratic,
          :results_title,
          :scoring_mode,
          :slug,
          :sort,
          :title,
          :triangle_base,
          :vote_on_percent,
          :voting_style,
          :weighting,
          :xor
        ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "delete/2" do
    test "deletes" do
      %{decision: decision, option_category: to_delete} = create_option_category()

      attrs = %{decision_id: decision.id, id: to_delete.id}
      params = to_graphql_input_params(attrs, decision)
      result = OptionCategoryResolver.delete(params, nil)

      assert {:ok, %OptionCategory{}} = result
      assert nil == Structure.get_option_category(to_delete.id, decision)
    end

    test "when record does not exist return successful nil" do
      %{decision: decision, option_category: to_delete} = create_option_category()
      delete_option_category(to_delete.id)

      attrs = %{decision_id: decision.id, id: to_delete.id}
      params = to_graphql_input_params(attrs, decision)
      result = OptionCategoryResolver.delete(params, nil)

      assert {:ok, nil} = result
    end
  end
end
