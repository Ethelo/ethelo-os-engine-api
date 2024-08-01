defmodule EtheloApi.Graphql.Resolvers.OptionFilterTest do
  @moduledoc """
  Validations and basic access for OptionFilter resolver
  through graphql.
  Note: Functionality is provided through the OptionFilterResolver.OptionFilter context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Structure.OptionFilterTest`

  """
  use EtheloApi.DataCase
  @moduletag option_filter: true, graphql: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.OptionFilterHelper
  alias EtheloApi.Structure
  alias EtheloApi.Structure.OptionFilter
  alias EtheloApi.Graphql.Resolvers.OptionFilter, as: OptionFilterResolver

  def test_list_filtering(field_name) do
    %{option_filter: to_match, decision: decision} = create_option_detail_filter()
    test_list_filtering(field_name, to_match, decision)
  end

  def test_list_filtering(field_name, to_match, decision) do
    create_option_detail_filter(decision)

    parent = %{decision: decision}
    args = %{} |> Map.put(field_name, Map.get(to_match, field_name))
    result = OptionFilterResolver.list(parent, args, nil)

    assert {:ok, result} = result
    assert [%OptionFilter{}] = result
    assert_result_ids_match([to_match], result)
  end

  describe "list/2" do
    test "filters by decision_id" do
      %{option_filter: to_match1, decision: decision} = create_option_detail_filter()
      %{option_filter: to_match2} = create_option_detail_filter(decision)

      parent = %{decision: decision}
      args = %{}
      result = OptionFilterResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionFilter{}, %OptionFilter{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "filters by id" do
      test_list_filtering(:id)
    end

    test "filters by slug" do
      test_list_filtering(:slug)
    end

    test "filters by option_detail_id" do
      %{option_filter: to_match, decision: decision} = create_option_detail_filter()
      test_list_filtering(:option_detail_id, to_match, decision)
    end

    test "filters by option_category_id" do
      %{option_filter: to_match, decision: decision} = create_option_category_filter()
      test_list_filtering(:option_category_id, to_match, decision)
    end

    test "no matching records" do
      decision = create_decision()

      parent = %{decision: decision}
      args = %{}
      result = OptionFilterResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [] = result
    end
  end

  describe "create/2" do
    test "creates with valid data" do
      %{decision: decision} = deps = option_detail_filter_deps()

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = OptionFilterResolver.create(params, nil)
      assert {:ok, %OptionFilter{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "invalid data returns changeset" do
      %{decision: decision} = deps = option_detail_filter_deps()

      attrs = invalid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = OptionFilterResolver.create(params, nil)
      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> error_map()
      expected = [:title, :slug, :option_category_id, :option_detail_id, :match_mode]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "update/2" do
    test "updates with valid data" do
      %{decision: decision} = deps = create_option_detail_filter()

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = OptionFilterResolver.update(params, nil)
      assert {:ok, %OptionFilter{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "invalid OptionFilter returns error" do
      %{decision: decision, option_filter: to_delete} = deps = create_option_detail_filter()
      delete_option_filter(to_delete.id)

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = OptionFilterResolver.update(params, nil)
      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "Decision mismatch returns changeset" do
      deps = create_option_detail_filter()
      decision = create_decision()
      deps = Map.put(deps, :decision, decision)

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)
      result = OptionFilterResolver.update(params, nil)

      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "invalid data returns changeset" do
      %{decision: decision} = deps = create_option_category_filter()

      attrs = invalid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)
      result = OptionFilterResolver.update(params, nil)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> error_map()
      expected = [:title, :slug, :match_mode, :option_category_id, :option_detail_id]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "delete/2" do
    test "deletes" do
      %{decision: decision, option_filter: to_delete} = create_option_detail_filter()

      attrs = %{decision_id: decision.id, id: to_delete.id}
      params = to_graphql_input_params(attrs, decision)
      result = OptionFilterResolver.delete(params, nil)

      assert {:ok, %OptionFilter{}} = result
      assert nil == Structure.get_option_filter(to_delete.id, decision)
    end

    test "when record does not exist return successful nil" do
      %{decision: decision, option_filter: to_delete} = create_option_detail_filter()
      delete_option_filter(to_delete.id)

      attrs = %{decision_id: decision.id, id: to_delete.id}
      params = to_graphql_input_params(attrs, decision)
      result = OptionFilterResolver.delete(params, nil)

      assert {:ok, nil} = result
    end
  end
end
