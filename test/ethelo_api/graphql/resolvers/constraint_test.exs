defmodule EtheloApi.Graphql.Resolvers.ConstraintTest do
  @moduledoc """
  Validations and basic access for Constraint resolver
  through graphql.
  Note: Functionality is provided through the ConstraintResolver.Constraint context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Structure.ConstraintTest`
  """
  use EtheloApi.DataCase
  @moduletag constraint: true, graphql: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.ConstraintHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Constraint
  alias EtheloApi.Graphql.Resolvers.Constraint, as: ConstraintResolver

  def test_list_filtering(field_name) do
    %{constraint: to_match, decision: decision} = create_variable_constraint()
    %{constraint: _excluded} = create_variable_constraint(decision)
    test_list_filtering(field_name, to_match, decision)
  end

  def test_list_filtering(field_name, to_match, decision) do
    parent = %{decision: decision}
    args = %{} |> Map.put(field_name, Map.get(to_match, field_name))
    result = ConstraintResolver.list(parent, args, nil)

    assert {:ok, result} = result
    assert [%Constraint{}] = result
    assert_result_ids_match([to_match], result)
  end

  describe "list/2" do
    test "filters by decision_id" do
      %{constraint: to_match1, decision: decision} = create_variable_constraint()
      %{constraint: to_match2} = create_variable_constraint(decision)
      %{constraint: _excluded} = create_variable_constraint()

      parent = %{decision: decision}
      args = %{}
      result = ConstraintResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Constraint{}, %Constraint{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "filters by id" do
      test_list_filtering(:id)
    end

    test "filters by slug" do
      test_list_filtering(:slug)
    end

    test "filters by variable_id" do
      %{constraint: to_match, decision: decision} = create_variable_constraint()
      %{constraint: _excluded} = create_variable_constraint(decision)

      test_list_filtering(:variable_id, to_match, decision)
    end

    test "filters by calculation_id" do
      %{constraint: to_match, decision: decision} = create_calculation_constraint()
      %{constraint: _excluded} = create_calculation_constraint(decision)

      test_list_filtering(:calculation_id, to_match, decision)
    end

    test "filters by option_filter_id" do
      %{constraint: to_match, decision: decision} = create_calculation_constraint()
      %{constraint: _excluded} = create_calculation_constraint(decision)
      test_list_filtering(:option_filter_id, to_match, decision)
    end

    test "no matching records" do
      decision = create_decision()

      parent = %{decision: decision}
      args = %{}
      result = ConstraintResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [] = result
    end
  end

  describe "create/2" do
    test "creates with valid data" do
      %{decision: decision} = deps = variable_constraint_deps()

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = ConstraintResolver.create(params, nil)

      assert {:ok, %Constraint{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "invalid data returns changeset" do
      %{decision: decision} = deps = variable_constraint_deps()
      delete_variable(deps.variable)
      delete_option_filter(deps.option_filter)

      attrs = deps |> invalid_attrs()
      params = to_graphql_input_params(attrs, decision)

      result = ConstraintResolver.create(params, nil)

      assert {:error, %Changeset{} = changeset} = result

      errors = changeset |> error_map()

      expected = [
        :calculation_id,
        :enabled,
        :lhs,
        :operator,
        :option_filter_id,
        :relaxable,
        :rhs,
        :slug,
        :title,
        :variable_id
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "update/2" do
    test "updates with valid data" do
      %{decision: decision} = deps = create_variable_constraint()

      attrs = deps |> valid_between_attrs()
      params = to_graphql_input_params(attrs, decision)

      result = ConstraintResolver.update(params, nil)

      assert {:ok, %Constraint{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "invalid Constraint returns error" do
      %{constraint: to_delete, decision: decision} = deps = create_variable_constraint()
      delete_constraint(to_delete.id)

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = ConstraintResolver.update(params, nil)

      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "Decision mismatch returns changeset" do
      deps = create_variable_constraint()
      decision = create_decision()
      deps = Map.put(deps, :decision, decision)

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = ConstraintResolver.update(params, nil)

      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "invalid data returns changeset" do
      %{decision: decision} = deps = create_calculation_constraint()
      %{option_filter: option_filter} = create_option_detail_filter()

      attrs =
        deps
        |> Map.put(:option_filter, option_filter)
        |> invalid_attrs()

      params = to_graphql_input_params(attrs, decision)

      result = ConstraintResolver.update(params, nil)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> error_map()

      expected = [
        :calculation_id,
        :enabled,
        :lhs,
        :operator,
        :option_filter_id,
        :relaxable,
        :rhs,
        :slug,
        :title,
        :variable_id
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "delete/2" do
    test "deletes" do
      %{constraint: to_delete, decision: decision} = create_variable_constraint()

      attrs = %{decision_id: decision.id, id: to_delete.id}
      params = to_graphql_input_params(attrs, decision)
      result = ConstraintResolver.delete(params, nil)

      assert {:ok, %Constraint{}} = result
      assert nil == Structure.get_constraint(to_delete.id, decision)
    end

    test "when record does not exist return successful nil" do
      %{constraint: to_delete, decision: decision} = create_variable_constraint()
      delete_constraint(to_delete.id)

      attrs = %{decision_id: decision.id, id: to_delete.id}
      params = to_graphql_input_params(attrs, decision)

      result = ConstraintResolver.delete(params, nil)

      assert {:ok, nil} = result
    end
  end
end
