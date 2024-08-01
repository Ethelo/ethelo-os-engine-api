defmodule EtheloApi.Structure.ConstraintTest do
  @moduledoc """
  Validations and basic access for Constraints
  Includes both the context EtheloApi.Structure, and specific functionality on the Constraint schema
  """
  use EtheloApi.DataCase
  @moduletag constraint: true, ecto: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.ConstraintHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Constraint
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Calculation
  alias EtheloApi.Structure.Variable

  describe "list_constraints/1" do
    test "filters by decision_id" do
      %{constraint: _excluded} = create_variable_constraint()
      %{constraint: to_match1, decision: decision} = create_variable_constraint()
      %{constraint: to_match2} = create_calculation_constraint(decision)

      result = Structure.list_constraints(decision)
      assert [%Constraint{} | _] = result
      assert_result_ids_match([to_match1, to_match2], result)
      assert Enum.count(result) == 2
    end

    test "filters by id" do
      %{constraint: to_match, decision: decision} = create_variable_constraint()
      %{constraint: _excluded} = create_variable_constraint(decision)

      modifiers = %{id: to_match.id}
      result = Structure.list_constraints(decision, modifiers)

      assert [%Constraint{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by slug" do
      %{constraint: to_match, decision: decision} = create_variable_constraint()
      %{constraint: _excluded} = create_variable_constraint(decision)

      modifiers = %{slug: to_match.slug}
      result = Structure.list_constraints(decision, modifiers)

      assert [%Constraint{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by calculation_id" do
      %{constraint: to_match, decision: decision} = create_calculation_constraint()
      %{constraint: _excluded} = create_calculation_constraint(decision)

      modifiers = %{calculation_id: to_match.calculation_id}
      result = Structure.list_constraints(decision, modifiers)

      assert [%Constraint{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by variable_id" do
      %{constraint: to_match, decision: decision} = create_variable_constraint()
      %{constraint: _excluded} = create_variable_constraint(decision)

      modifiers = %{variable_id: to_match.variable_id}
      result = Structure.list_constraints(decision, modifiers)

      assert [%Constraint{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by option_filter_id" do
      %{constraint: to_match, decision: decision} = create_variable_constraint()
      %{constraint: _excluded} = create_variable_constraint(decision)

      modifiers = %{option_filter_id: to_match.option_filter_id}
      result = Structure.list_constraints(decision, modifiers)

      assert [%Constraint{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Structure.list_constraints(nil) end
    end
  end

  describe "get_constraint/2" do
    test "filters by decision_id as struct" do
      %{constraint: to_match, decision: decision} = create_variable_constraint()

      result = Structure.get_constraint(to_match.id, decision)

      assert %Constraint{} = result
      assert to_match.id == result.id
    end

    test "filters by decision_id" do
      %{constraint: to_match, decision: decision} = create_variable_constraint()

      result = Structure.get_constraint(to_match.id, decision.id)

      assert %Constraint{} = result
      assert to_match.id == result.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Structure.get_constraint(1, nil) end
    end

    test "raises without a Constraint id" do
      assert_raise ArgumentError, ~r/Constraint/, fn ->
        Structure.get_constraint(nil, create_decision())
      end
    end

    test "missing record returns nil" do
      decision = create_decision()

      result = Structure.get_constraint(1929, decision.id)

      assert result == nil
    end

    test "invalid Decision returns nil" do
      %{constraint: to_match} = create_variable_constraint()
      decision2 = create_decision()

      result = Structure.get_constraint(to_match.id, decision2)

      assert result == nil
    end
  end

  describe "create_constraint/2" do
    test "empty data returns changeset" do
      decision = create_decision()

      result = Structure.create_constraint(empty_attrs(), decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "can't be blank" in errors.operator
      assert "can't be blank" in errors.rhs
      assert "can't be blank" in errors.option_filter_id
      assert hd(errors.calculation_id) =~ ~r/must specify either/
      assert hd(errors.variable_id) =~ ~r/must specify either/

      expected = [
        :title,
        :slug,
        :operator,
        :rhs,
        :option_filter_id,
        :calculation_id,
        :variable_id
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      decision = create_decision()

      attrs = invalid_attrs()
      result = Structure.create_constraint(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.relaxable
      assert "is invalid" in errors.operator
      assert "is invalid" in errors.rhs
      assert "is invalid" in errors.lhs
      assert "is invalid" in errors.enabled
      assert "does not exist" in errors.option_filter_id
      assert hd(errors.calculation_id) =~ ~r/must specify either/
      assert hd(errors.variable_id) =~ ~r/must specify either/

      expected = [
        :title,
        :slug,
        :operator,
        :rhs,
        :lhs,
        :option_filter_id,
        :calculation_id,
        :variable_id,
        :enabled,
        :relaxable
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "requires lhs with between operator" do
      deps = calculation_constraint_deps()
      %{decision: decision} = deps
      attrs = deps |> valid_between_attrs() |> Map.put(:lhs, nil)

      result = Structure.create_constraint(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.lhs
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn ->
        Structure.create_constraint(nil, %{title: "foo"})
      end
    end

    test "OptionFilter from different Decision returns changeset" do
      deps = variable_constraint_deps()
      %{decision: decision} = deps
      %{option_filter: mismatch} = create_option_category_filter()
      attrs = deps |> Map.put(:option_filter, mismatch) |> valid_attrs()

      result = Structure.create_constraint(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.option_filter_id
    end
  end

  describe "create_constraint/2 with Variable" do
    test "creates single boundary Constraint" do
      deps = variable_constraint_deps()
      %{decision: decision} = deps

      attrs = valid_attrs(deps)
      result = Structure.create_constraint(attrs, decision)

      assert {:ok, %Constraint{} = new_record} = result
      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "creates between Constraint with valid data" do
      deps = variable_constraint_deps()
      %{decision: decision} = deps
      attrs = valid_between_attrs(deps)

      result = Structure.create_constraint(attrs, decision)

      assert {:ok, %Constraint{} = new_record} = result
      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "Variable from different Decision returns changeset" do
      deps = variable_constraint_deps()
      %{decision: decision} = deps
      %{variable: mismatch} = create_detail_variable()

      attrs = deps |> Map.put(:variable, mismatch) |> valid_attrs()
      result = Structure.create_constraint(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.variable_id
    end
  end

  describe "create_constraint/2 with Calculation" do
    test "creates single boundary Constraint" do
      deps = calculation_constraint_deps()
      %{decision: decision} = deps

      attrs = valid_attrs(deps)
      result = Structure.create_constraint(attrs, decision)

      assert {:ok, %Constraint{} = new_record} = result
      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "creates between Constraint with valid data" do
      deps = calculation_constraint_deps()
      %{decision: decision} = deps
      attrs = valid_between_attrs(deps)

      result = Structure.create_constraint(attrs, decision)

      assert {:ok, %Constraint{} = new_record} = result
      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "Calculation from different Decision returns changeset" do
      %{decision: decision} = deps = calculation_constraint_deps()
      %{calculation: mismatch} = create_calculation()

      attrs = deps |> Map.put(:calculation, mismatch) |> valid_attrs()
      result = Structure.create_constraint(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.calculation_id
    end
  end

  describe "create_constraint/2 slug checks" do
    test "duplicate title with no slug defined generates variant slug" do
      deps = create_variable_constraint()
      %{constraint: existing, decision: decision} = deps

      attrs = deps |> valid_attrs() |> Map.put(:title, existing.title) |> Map.drop([:slug])
      result = Structure.create_constraint(attrs, decision)

      assert {:ok, %Constraint{} = new_record} = result

      refute existing.slug == new_record.slug
    end

    test "duplicate slug returns changeset" do
      deps = create_variable_constraint()
      %{constraint: existing, decision: decision} = deps
      attrs = deps |> valid_attrs() |> Map.put(:slug, existing.slug)

      result = Structure.create_constraint(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "update_constraint/2" do
    test "empty data returns changeset" do
      %{constraint: to_update} = create_variable_constraint()

      result = Structure.update_constraint(to_update, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "can't be blank" in errors.operator
      assert "can't be blank" in errors.rhs
      assert "can't be blank" in errors.option_filter_id
      assert hd(errors.variable_id) =~ ~r/must specify either/
      assert hd(errors.calculation_id) =~ ~r/must specify either/
      assert "must have numbers and/or letters" in errors.slug

      expected = [
        :title,
        :slug,
        :operator,
        :rhs,
        :option_filter_id,
        :calculation_id,
        :variable_id
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      %{constraint: to_update} = create_variable_constraint()

      attrs = invalid_attrs()
      result = Structure.update_constraint(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.relaxable
      assert "is invalid" in errors.operator
      assert "is invalid" in errors.rhs
      assert "is invalid" in errors.lhs
      assert "is invalid" in errors.enabled
      assert "does not exist" in errors.option_filter_id
      assert hd(errors.calculation_id) =~ ~r/must specify either/
      assert hd(errors.variable_id) =~ ~r/must specify either/

      expected = [
        :title,
        :slug,
        :operator,
        :rhs,
        :lhs,
        :option_filter_id,
        :calculation_id,
        :variable_id,
        :enabled,
        :relaxable
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "requires lhs with between operator" do
      deps = create_variable_constraint()
      %{constraint: to_update} = deps

      attrs = deps |> valid_between_attrs() |> Map.put(:lhs, nil)
      result = Structure.update_constraint(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.lhs
    end

    test "OptionFilter from different Decision returns changeset" do
      deps = create_variable_constraint()
      %{constraint: to_update} = deps
      %{option_filter: mismatch} = create_option_category_filter()

      attrs = deps |> Map.put(:option_filter, mismatch) |> valid_attrs()

      result = Structure.update_constraint(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.option_filter_id
    end

    test "both Variable and Calculation defined returns changeset" do
      deps = create_calculation_constraint()
      %{constraint: to_update, decision: decision} = deps
      %{variable: variable} = create_detail_variable(decision)

      attrs = deps |> valid_attrs() |> Map.put(:variable_id, variable.id)
      result = Structure.update_constraint(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert hd(errors.calculation_id) =~ ~r/must specify either/
      assert hd(errors.variable_id) =~ ~r/must specify either/
    end

    test "Decision update ignored" do
      %{constraint: to_update} = create_variable_constraint()
      decision2 = create_decision()

      attrs = %{title: "Updated Title", decision: decision2}
      result = Structure.update_constraint(to_update, attrs)

      assert {:ok, updated} = result
      assert updated.title == attrs.title
      refute updated.decision.id == decision2.id
      assert updated.decision.id == to_update.decision_id
    end
  end

  describe "update_constraint/2 with Variable" do
    test "updates Constraint with valid single boundary data" do
      deps = create_variable_constraint()
      %{constraint: to_update} = deps
      attrs = valid_attrs(deps)

      result = Structure.update_constraint(to_update, attrs)

      assert {:ok, %Constraint{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "updates Constraint with valid between data" do
      deps = create_variable_constraint()
      %{constraint: to_update} = deps

      attrs = valid_between_attrs(deps)
      result = Structure.update_constraint(to_update, attrs)

      assert {:ok, %Constraint{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "Variable from different Decision returns changeset" do
      deps = create_variable_constraint()
      %{constraint: to_update} = deps
      %{variable: mismatch} = create_detail_variable()

      attrs = deps |> Map.put(:variable, mismatch) |> valid_attrs()
      result = Structure.update_constraint(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.variable_id
    end
  end

  describe "update_constraint/2 with Calculation" do
    test "updates Constraint with valid single boundary data" do
      deps = create_calculation_constraint()
      %{constraint: to_update} = deps

      attrs = valid_attrs(deps)
      result = Structure.update_constraint(to_update, attrs)

      assert {:ok, %Constraint{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "updates Constraint with valid between data" do
      deps = create_calculation_constraint()
      %{constraint: to_update} = deps

      attrs = valid_between_attrs(deps)
      result = Structure.update_constraint(to_update, attrs)

      assert {:ok, %Constraint{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "Calculation from different Decision returns changeset" do
      deps = create_calculation_constraint()
      %{constraint: to_update} = deps
      %{calculation: mismatch} = create_calculation()

      attrs = deps |> Map.put(:calculation, mismatch) |> valid_attrs()
      result = Structure.update_constraint(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.calculation_id
    end
  end

  describe "update_constraint/2 slug checks" do
    test "duplicate title with no slug defined does not update slug" do
      %{constraint: duplicate, decision: decision} = create_variable_constraint()
      %{constraint: to_update} = deps = create_variable_constraint(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, duplicate.title) |> Map.drop([:slug])
      result = Structure.update_constraint(to_update, attrs)

      assert {:ok, %Constraint{} = updated} = result

      assert to_update.slug == updated.slug
    end

    test "duplicate title with nil slug defined generates variant slug" do
      %{constraint: duplicate, decision: decision} = create_variable_constraint()
      %{constraint: to_update} = deps = create_variable_constraint(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, duplicate.title) |> Map.put(:slug, nil)
      result = Structure.update_constraint(to_update, attrs)

      assert {:ok, %Constraint{} = updated} = result
      refute to_update.slug == updated.slug
      refute to_update.slug == duplicate.slug
    end

    test "duplicate slug returns changeset" do
      %{constraint: duplicate, decision: decision} = create_variable_constraint()
      %{constraint: to_update} = deps = create_variable_constraint(decision)

      attrs = deps |> valid_attrs() |> Map.put(:slug, duplicate.slug)
      result = Structure.update_constraint(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "delete_constraint/2" do
    test "deletes Variable Constraint" do
      deps = create_variable_constraint()
      %{constraint: to_delete, variable: variable, decision: decision} = deps

      result = Structure.delete_constraint(to_delete, decision.id)

      assert {:ok, %Constraint{}} = result
      assert nil == Repo.get(Constraint, to_delete.id)
      assert nil !== Repo.get(Variable, variable.id)
      assert nil !== Repo.get(Decision, decision.id)
    end

    test "deletes Calculation Constraint" do
      deps = create_calculation_constraint()
      %{constraint: to_delete, calculation: calculation, decision: decision} = deps

      result = Structure.delete_constraint(to_delete, decision.id)

      assert {:ok, %Constraint{}} = result
      assert nil == Repo.get(Constraint, to_delete.id)
      assert nil !== Repo.get(Calculation, calculation.id)
      assert nil !== Repo.get(Decision, decision.id)
    end
  end

  describe "documentation" do
    test "has documentation module" do
      assert %{} = Constraint.strings()
      assert %{} = Constraint.examples()
      assert is_list(Constraint.fields())
    end
  end
end
