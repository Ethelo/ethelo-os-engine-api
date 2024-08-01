defmodule GraphQL.EtheloApi.Resolvers.ConstraintTest do
  @moduledoc """
  Validations and basic access for "Constraint" resolver, used to load constraint records
  through graphql.
  Note: Functionality is provided through the ConstraintResolver.Constraint context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Structure.ConstraintTest`
  """
  use EtheloApi.DataCase
  @moduletag constraint: true, graphql: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.ConstraintHelper

  alias Kronky.ValidationMessage
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Constraint
  alias GraphQL.EtheloApi.Resolvers.Constraint, as: ConstraintResolver

  describe "list/2" do

    test "returns records matching a Decision" do
      %{constraint: first, decision: decision} = create_variable_constraint()
      %{constraint: second} = create_variable_constraint(decision)

      parent = %{decision: decision}
      args = %{}
      result = ConstraintResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Constraint{}, %Constraint{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "filters by Constraint.id" do
      %{constraint: matching, decision: decision} = create_variable_constraint()
      create_variable_constraint(decision)

      parent = %{decision: decision}
      args = %{id: matching.id}
      result = ConstraintResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Constraint{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by Constraint.slug" do
      %{constraint: matching, decision: decision} = create_variable_constraint()
      create_variable_constraint(decision)

      parent = %{decision: decision}
      args = %{slug: matching.slug}
      result = ConstraintResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Constraint{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by Constraint.variable_id" do
      %{constraint: matching, decision: decision} = create_variable_constraint()
      create_variable_constraint(decision)

      parent = %{decision: decision}
      args = %{variable_id: matching.variable_id}
      result = ConstraintResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Constraint{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by Constraint.calculation_id" do
      %{constraint: matching, decision: decision} = create_calculation_constraint()
      create_calculation_constraint(decision)

      parent = %{decision: decision}
      args = %{calculation_id: matching.calculation_id}
      result = ConstraintResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Constraint{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by Constraint.option_filter_id" do
      %{constraint: matching, decision: decision} = create_calculation_constraint()
      create_calculation_constraint(decision)

      parent = %{decision: decision}
      args = %{option_filter_id: matching.option_filter_id}
      result = ConstraintResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Constraint{}] = result
      assert_result_ids_match([matching], result)
    end

    test "no Constraint matches" do
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
      deps = variable_constraint_deps()
      %{decision: decision} = deps

      attrs = deps |> valid_attrs() |> to_graphql_attrs()
      result = ConstraintResolver.create(decision, attrs)

      assert {:ok, %Constraint{} = new_record} = result
      assert attrs.title == new_record.title
      assert_equivalent_slug(attrs.slug, new_record.slug)
      assert attrs.value == Map.get(new_record, :rhs, nil)
      assert nil == Map.get(new_record, :lhs, nil)
      assert attrs.operator == new_record.operator
      assert attrs.option_filter_id == new_record.option_filter_id
      assert attrs.calculation_id == new_record.calculation_id
      assert attrs.variable_id == new_record.variable_id
      assert attrs.enabled == new_record.enabled
      assert attrs.relaxable == new_record.relaxable
    end

    test "returns a list of errors with invalid data" do
      deps = variable_constraint_deps()
      %{decision: decision} = deps
      delete_variable(deps.variable)
      delete_option_filter(deps.option_filter)

      attrs = deps |> invalid_attrs() |> to_graphql_attrs()
      result = ConstraintResolver.create(decision, attrs)

      assert {:ok, {:error, [_|_] = errors}} = result

      error_fields = errors |> Enum.map(& &1.field)
      assert :title in error_fields
      assert :slug in error_fields
      assert :operator in error_fields
      assert :relaxable in error_fields
      assert :between_low in error_fields
      assert :variable_id in error_fields
      assert :calculation_id in error_fields
      assert :option_filter_id in error_fields
      assert :value in error_fields
      refute :rhs in error_fields
      refute :lhs in error_fields
      refute :between_high in error_fields
    assert [_, _, _, _, _, _, _, _, _, _] = error_fields
    end
  end

  describe "update/2" do

    test "updates with valid data" do
      deps = create_variable_constraint()
      %{decision: decision} = deps

      attrs = deps |> valid_between_attrs() |> to_graphql_attrs()
      result = ConstraintResolver.update(decision, attrs)

      assert {:ok, %Constraint{} = updated} = result
      assert attrs.title == updated.title
      assert_equivalent_slug(attrs.slug, updated.slug)
      assert attrs.between_low == Map.get(updated, :lhs, nil)
      assert attrs.between_high == Map.get(updated, :rhs, nil)
      assert attrs.operator == updated.operator
      assert attrs.option_filter_id == updated.option_filter_id
      assert attrs.calculation_id == updated.calculation_id
      assert attrs.variable_id == updated.variable_id
      assert attrs.enabled == updated.enabled
      assert attrs.relaxable == updated.relaxable
    end

    test "returns errors when Constraint does not exist" do
      deps = create_variable_constraint()
      %{constraint: constraint, decision: decision} = deps
      delete_constraint(constraint.id)

      attrs = deps |> valid_attrs() |> to_graphql_attrs()
      result = ConstraintResolver.update(decision, attrs)

      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "returns errors when Decision does not match" do
      deps = create_variable_constraint()
      decision = create_decision()

      attrs = deps |> valid_attrs() |> to_graphql_attrs()
      result = ConstraintResolver.update(decision, attrs)

      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "returns a list of errors with invalid data" do
      deps = create_calculation_constraint()
      %{decision: decision} = deps
      %{option_filter: option_filter} = create_option_detail_filter()

      attrs = deps
        |> Map.put(:option_filter, option_filter)
        |> invalid_attrs()
        |> Map.put(:operator, :between)
        |> to_graphql_attrs()

      result = ConstraintResolver.update(decision, attrs)

      assert {:ok, {:error, [_|_] = errors}} = result

      error_fields = errors |> Enum.map(& &1.field)
      assert :title in error_fields
      assert :slug in error_fields
      assert :between_high in error_fields
      assert :between_low in error_fields
      assert :calculation_id in error_fields
      assert :variable_id in error_fields
      assert :relaxable in error_fields
      assert :option_filter_id in error_fields
      refute :rhs in error_fields
      refute :lhs in error_fields
      assert [_, _, _, _, _, _, _, _, _] = error_fields
    end
  end

  describe "delete/2" do
    test "deletes" do
      deps = create_variable_constraint()
      %{constraint: constraint, decision: decision} = deps

      attrs = %{decision_id: decision.id, id: constraint.id}
      result = ConstraintResolver.delete(decision, attrs)

      assert {:ok, %Constraint{}} = result
      assert nil == Structure.get_constraint(constraint.id, decision)
    end

    test "delete/2 does not return errors when Constraint does not exist" do
      %{constraint: constraint, decision: decision} = create_variable_constraint()
      delete_constraint(constraint.id)

      attrs = %{decision_id: decision.id, id: constraint.id}
      result = ConstraintResolver.delete(decision, attrs)

      assert {:ok, nil} = result
    end
  end
end
