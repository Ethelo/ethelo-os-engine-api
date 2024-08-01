defmodule EtheloApi.Graphql.Resolvers.VariableTest do
  @moduledoc """
  Validations and basic access for Variable resolver
  through graphql.
  Note: Functionality is provided through the VariableResolver.Variable context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Structure.VariableTest`
  """
  use EtheloApi.DataCase
  @moduletag variable: true, graphql: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.VariableHelper
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Variable
  alias EtheloApi.Graphql.Resolvers.Variable, as: VariableResolver

  def test_list_filtering(field_name) do
    %{variable: to_match, decision: decision} = create_detail_variable()
    %{variable: _excluded} = create_detail_variable(decision)
    test_list_filtering(field_name, to_match, decision)
  end

  def test_list_filtering(field_name, to_match, decision) do
    parent = %{decision: decision}
    args = %{} |> Map.put(field_name, Map.get(to_match, field_name))
    result = VariableResolver.list(parent, args, nil)

    assert {:ok, result} = result
    assert [%Variable{}] = result
    assert_result_ids_match([to_match], result)
  end

  describe "list/2" do
    test "filters by decision_id" do
      %{variable: to_match1, decision: decision} = create_detail_variable()
      %{variable: to_match2} = create_filter_variable(decision)
      %{variable: _excluded} = create_detail_variable()

      parent = %{decision: decision}
      args = %{}
      result = VariableResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Variable{}, %Variable{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "filters by id" do
      test_list_filtering(:id)
    end

    test "filters by slug" do
      test_list_filtering(:slug)
    end

    test "filters by option_detail_id" do
      %{variable: to_match, decision: decision} = create_detail_variable()
      %{variable: _excluded} = create_detail_variable(decision)
      test_list_filtering(:option_detail_id, to_match, decision)
    end

    test "filters by option_filter_id" do
      %{variable: to_match, decision: decision} = create_filter_variable()
      %{variable: _excluded} = create_filter_variable(decision)
      test_list_filtering(:option_filter_id, to_match, decision)
    end

    test "no matching records" do
      decision = create_decision()

      parent = %{decision: decision}
      args = %{}
      result = VariableResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [] = result
    end
  end

  describe "create/2" do
    test "creates with valid data" do
      %{decision: decision} = deps = detail_variable_deps()

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = VariableResolver.create(params, nil)
      assert {:ok, %Variable{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "invalid data returns changeset" do
      %{option_detail: option_detail, decision: decision} = deps = detail_variable_deps()
      delete_option_detail(option_detail.id)

      attrs = invalid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)
      result = VariableResolver.create(params, nil)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> error_map()
      expected = [:title, :method, :slug, :option_detail_id]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "update/2" do
    test "updates with valid data" do
      %{decision: decision} = deps = create_detail_variable()

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = VariableResolver.update(params, nil)
      assert {:ok, %Variable{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "invalid Variable returns error" do
      %{decision: decision, variable: to_delete} = deps = create_detail_variable()
      delete_variable(to_delete.id)

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = VariableResolver.update(params, nil)
      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "Decision mismatch returns changeset" do
      deps = create_detail_variable()
      decision = create_decision()
      deps = Map.put(deps, :decision, decision)

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = VariableResolver.update(params, nil)
      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "invalid data returns changeset" do
      %{decision: decision} = deps = create_filter_variable()

      attrs = invalid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)
      result = VariableResolver.update(params, nil)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> error_map()
      expected = [:title, :method, :slug]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "delete/2" do
    test "deletes" do
      %{decision: decision, variable: to_delete} = create_detail_variable()

      attrs = %{decision_id: decision.id, id: to_delete.id}
      params = to_graphql_input_params(attrs, decision)
      result = VariableResolver.delete(params, nil)

      assert {:ok, %Variable{}} = result
      assert nil == Structure.get_variable(to_delete.id, decision)
    end

    test "when record does not exist return successful nil" do
      %{decision: decision, variable: to_delete} = create_detail_variable()
      delete_variable(to_delete.id)

      attrs = %{decision_id: decision.id, id: to_delete.id}
      params = to_graphql_input_params(attrs, decision)
      result = VariableResolver.delete(params, nil)

      assert {:ok, nil} = result
    end
  end
end
