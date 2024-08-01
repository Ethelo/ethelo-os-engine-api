defmodule EtheloApi.Structure.ConstraintTest do
  @moduledoc """
  Validations and basic access for Constraints
  Includes both the context EtheloApi.Structure, and specific functionality on the Constraint schema
  """
  use EtheloApi.DataCase
  @moduletag constraint: true, ethelo: true, ecto: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.ConstraintHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Constraint
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Calculation
  alias EtheloApi.Structure.Variable

  describe "list_constraints/1" do

    test "returns all records matching a Decision" do
      create_variable_constraint() # should not be returned
      %{constraint: first, decision: decision} = create_variable_constraint()
      %{constraint: second} = create_calculation_constraint(decision)

      result = Structure.list_constraints(decision)
      assert [%Constraint{} | _] = result
      assert_result_ids_match([first, second], result)
      assert Enum.count(result) == 2
    end

    test "returns record matching id" do
      %{constraint: matching, decision: decision} = create_variable_constraint()
      %{constraint: _not_matching} = create_variable_constraint(decision)

      filters = %{id: matching.id}
      result = Structure.list_constraints(decision, filters)

      assert [%Constraint{}] = result
      assert_result_ids_match([matching], result)
    end

    test "returns record matching slug" do
      %{constraint: matching, decision: decision} = create_variable_constraint()
      %{constraint: _not_matching} = create_variable_constraint(decision)

      filters = %{slug: matching.slug}
      result = Structure.list_constraints(decision, filters)

      assert [%Constraint{}] = result
      assert_result_ids_match([matching], result)
    end

    test "returns records matching a Calculation" do
      %{constraint: matching, decision: decision} = create_calculation_constraint()
      %{constraint: _not_matching} = create_calculation_constraint(decision)

      filters = %{calculation_id: matching.calculation_id}
      result = Structure.list_constraints(decision, filters)

      assert [%Constraint{}] = result
      assert_result_ids_match([matching], result)
    end

    test "returns records matching an Variable" do
      %{constraint: matching, decision: decision} = create_variable_constraint()
      %{constraint: _not_matching} = create_variable_constraint(decision)

      filters = %{variable_id: matching.variable_id}
      result = Structure.list_constraints(decision, filters)

      assert [%Constraint{}] = result
      assert_result_ids_match([matching], result)
    end

    test "returns records matching an OptionFilter" do
      %{constraint: matching, decision: decision} = create_variable_constraint()
      %{constraint: _not_matching} = create_variable_constraint(decision)

      filters = %{option_filter_id: matching.option_filter_id}
      result = Structure.list_constraints(decision, filters)

      assert [%Constraint{}] = result
      assert_result_ids_match([matching], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Structure.list_constraints(nil) end
    end
  end

  describe "get_constraint/2" do

    test "returns the matching record by Decision object" do
      %{constraint: record, decision: decision} = create_variable_constraint()

      result = Structure.get_constraint(record.id, decision)

      assert %Constraint{} = result
      assert record.id == result.id
    end

    test "returns the matching record by Decision.id" do
      %{constraint: record, decision: decision} = create_variable_constraint()

      result = Structure.get_constraint(record.id, decision.id)

      assert %Constraint{} = result
      assert record.id == result.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Structure.get_constraint(1, nil) end
    end

    test "raises without an Constraint id" do
      assert_raise ArgumentError, ~r/Constraint/,
        fn -> Structure.get_constraint(nil, create_decision()) end
    end

    test "returns nil if id does not exist" do
      decision = create_decision()

      result = Structure.get_constraint(1929, decision.id)

      assert result == nil
    end

    test "returns nil with invalid decision id " do
      %{constraint: record} = create_variable_constraint()
      decision2 = create_decision()

      result = Structure.get_constraint(record.id, decision2)

      assert result == nil
    end
  end

  describe "create_constraint/2" do
    test "with empty data returns errors" do
      decision = create_decision()

      result = Structure.create_constraint(decision, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "can't be blank" in errors.title
      assert "can't be blank" in errors.operator
      assert "can't be blank" in errors.rhs
      assert "can't be blank" in errors.option_filter_id
      assert hd(errors.calculation_id) =~ ~r/can't be blank/
      assert hd(errors.variable_id) =~ ~r/can't be blank/
      refute :lhs in Map.keys(errors)
      refute :enabled in Map.keys(errors)
      assert [_, _, _, _, _, _, _] = Map.keys(errors)
    end

    test "with invalid data returns errors" do
      decision = create_decision()

      attrs = invalid_attrs()
      result = Structure.create_constraint(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "must include at least one word" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.relaxable
      assert "is invalid" in errors.operator
      assert "is invalid" in errors.rhs
      assert "is invalid" in errors.lhs
      assert "is invalid" in errors.enabled
      assert "does not exist" in errors.option_filter_id
      assert hd(errors.calculation_id) =~ ~r/must be blank/
      assert hd(errors.variable_id) =~ ~r/must be blank/
      assert [_, _, _, _, _, _, _, _, _, _] = Map.keys(errors)
    end

    test "requires lhs with between operator" do
      deps = calculation_constraint_deps()
      %{decision: decision} = deps
      attrs = deps |> valid_between_attrs() |> Map.put(:lhs, nil)

      result = Structure.create_constraint(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "can't be blank" in errors.lhs
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn ->
        Structure.create_constraint(nil, %{title: "foo"})
      end
    end

    test "an OptionFilter from different Decision returns errors" do
      deps = variable_constraint_deps()
      %{decision: decision} = deps
      %{option_filter: option_filter} = create_option_category_filter()
      attrs = deps |> Map.put(:option_filter, option_filter) |> valid_attrs()

      result = Structure.create_constraint(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.option_filter_id
    end
  end

  describe "create_constraint/2 with Variable " do

    test "creates single boundary constraint" do
      deps = variable_constraint_deps()
      %{decision: decision} = deps

      attrs = valid_attrs(deps)
      result = Structure.create_constraint(decision, attrs)

      assert {:ok, %Constraint{} = new_record} = result
      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "creates between constraint with valid data" do
      deps = variable_constraint_deps()
      %{decision: decision} = deps
      attrs = valid_between_attrs(deps)

      result = Structure.create_constraint(decision, attrs)

      assert {:ok, %Constraint{} = new_record} = result
      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "a Variable from different Decision returns errors" do
      deps = variable_constraint_deps()
      %{decision: decision} = deps
      %{variable: variable} = create_detail_variable()

      attrs =  deps |> Map.put(:variable, variable) |> valid_attrs()
      result = Structure.create_constraint(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.variable_id
    end
  end

  describe "create_constraint/2 with Calculation " do

    test "creates single boundary constraint" do
      deps = calculation_constraint_deps()
      %{decision: decision} = deps

      attrs = valid_attrs(deps)
      result = Structure.create_constraint(decision, attrs)

      assert {:ok, %Constraint{} = new_record} = result
      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "creates between constraint with valid data" do
      deps = calculation_constraint_deps()
      %{decision: decision} = deps
      attrs = valid_between_attrs(deps)

      result = Structure.create_constraint(decision, attrs)

      assert {:ok, %Constraint{} = new_record} = result
      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "a Calculation from different Decision returns errors" do
      %{decision: decision} = deps = calculation_constraint_deps()
      %{calculation: calculation} = create_calculation()

      attrs = deps |> Map.put(:calculation, calculation) |> valid_attrs()
      result = Structure.create_constraint(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.calculation_id
    end
  end

  describe "create_constraint/2 slug checks" do
    test "duplicate title with no slug defined generates variant slug" do
      deps = create_variable_constraint()
      %{constraint: existing, decision: decision} = deps

      attrs = deps |> valid_attrs() |> Map.put(:title, existing.title) |> Map.drop([:slug])
      result = Structure.create_constraint(decision, attrs)

      assert {:ok, %Constraint{} = new_record} = result

      refute existing.slug == new_record.slug
    end

    test "duplicate slug returns errors" do
      deps = create_variable_constraint()
      %{constraint: existing, decision: decision} = deps
      attrs = deps |> valid_attrs() |> Map.put(:slug, existing.slug)

      result = Structure.create_constraint(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "update_constraint/2" do
    test "empty data returns errors" do
      %{constraint: existing} = create_variable_constraint()

      result = Structure.update_constraint(existing, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "can't be blank" in errors.title
      assert "can't be blank" in errors.operator
      assert "can't be blank" in errors.rhs
      assert "can't be blank" in errors.option_filter_id
      assert hd(errors.variable_id) =~ ~r/can't be blank/
      assert hd(errors.calculation_id) =~ ~r/can't be blank/
      assert "must have numbers and/or letters" in errors.slug
      refute :lhs in Map.keys(errors)
      refute :enabled in Map.keys(errors)
      assert [_, _, _, _, _, _, _] = Map.keys(errors)
    end

    test "invalid data returns errors" do
      %{constraint: existing} = create_variable_constraint()

      attrs = invalid_attrs()
      result = Structure.update_constraint(existing, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "must include at least one word" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.relaxable
      assert "is invalid" in errors.operator
      assert "is invalid" in errors.rhs
      assert "is invalid" in errors.lhs
      assert "is invalid" in errors.enabled
      assert "does not exist" in errors.option_filter_id
      assert hd(errors.calculation_id) =~ ~r/must be blank/
      assert hd(errors.variable_id) =~ ~r/must be blank/
      assert [_, _, _, _, _, _, _, _, _, _] = Map.keys(errors)
    end

    test "requires lhs with between operator" do
      deps = create_variable_constraint()
      %{constraint: constraint} = deps

      attrs = deps |> valid_between_attrs() |> Map.put(:lhs, nil)
      result = Structure.update_constraint(constraint, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "can't be blank" in errors.lhs
    end

    test "OptionFilter from different decision returns errors" do
      deps = create_variable_constraint()
      %{constraint: constraint} = deps
      %{option_filter: option_filter} = create_option_category_filter()

      attrs = deps |> Map.put(:option_filter, option_filter) |> valid_attrs()

      result = Structure.update_constraint(constraint, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.option_filter_id
    end


    test "with both Variable and Calculation defined returns errors" do
      deps = create_calculation_constraint()
      %{constraint: constraint, decision: decision} = deps
      %{variable: variable} = create_detail_variable(decision)

      attrs = deps |> valid_attrs() |> Map.put(:variable_id, variable.id)
      result = Structure.update_constraint(constraint, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert hd(errors.calculation_id) =~ ~r/must be blank/
      assert hd(errors.variable_id) =~ ~r/must be blank/
    end

    test "Decision update ignored" do
      %{constraint: existing} = create_variable_constraint()
      decision2 = create_decision()

      attrs = %{title: "Updated Title", decision: decision2}
      result = Structure.update_constraint(existing, attrs)

      assert {:ok, updated} = result
      assert updated.title == attrs.title
      refute updated.decision.id == decision2.id
      assert updated.decision.id == existing.decision_id
    end
  end

  describe "update_constraint/2 with Variable" do

    test "updates constraint with valid single boundary data" do
      deps = create_variable_constraint()
      %{constraint: existing} = deps
      attrs = valid_attrs(deps)

      result = Structure.update_constraint(existing, attrs)

      assert {:ok, %Constraint{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "updates constraint with valid between data" do
      deps = create_variable_constraint()
      %{constraint: constraint} = deps

      attrs = valid_between_attrs(deps)
      result = Structure.update_constraint(constraint, attrs)

      assert {:ok, %Constraint{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "Variable from different decision returns errors" do
      deps = create_variable_constraint()
      %{constraint: constraint} = deps
      %{variable: variable} = create_detail_variable()

      attrs = deps |> Map.put(:variable, variable) |> valid_attrs()
      result = Structure.update_constraint(constraint, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.variable_id
    end

  end

  describe "update_constraint/2 with Calculation" do

    test "updates constraint with valid single boundary data" do
      deps = create_calculation_constraint()
      %{constraint: constraint} = deps

      attrs = valid_attrs(deps)
      result = Structure.update_constraint(constraint, attrs)

      assert {:ok, %Constraint{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "updates constraint with valid between data" do
      deps = create_calculation_constraint()
      %{constraint: constraint} = deps

      attrs = valid_between_attrs(deps)
      result = Structure.update_constraint(constraint, attrs)

      assert {:ok, %Constraint{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "Calculation from different decision returns errors" do
      deps = create_calculation_constraint()
      %{constraint: constraint} = deps
      %{calculation: calculation} = create_calculation()

      attrs = deps |> Map.put(:calculation, calculation) |> valid_attrs()
      result = Structure.update_constraint(constraint, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.calculation_id
    end

  end

  describe "update_constraint/2 slug checks" do

    test "a duplicate title with no slug defined does not update slug" do
      %{constraint: first, decision: decision} = create_variable_constraint()
      %{constraint: second} = deps = create_variable_constraint(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, first.title) |> Map.drop([:slug])
      result = Structure.update_constraint(second, attrs)

      assert {:ok, %Constraint{} = updated} = result

      assert second.slug == updated.slug
    end

    test "a duplicate title with nil slug defined generates variant slug" do
      %{constraint: first, decision: decision} = create_variable_constraint()
      %{constraint: second} = deps = create_variable_constraint(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, first.title) |> Map.put(:slug, nil)
      result = Structure.update_constraint(second, attrs)

      assert {:ok, %Constraint{} = updated} = result
      refute second.slug == updated.slug
      refute second.slug == first.slug
    end

    test "a duplicate slug returns errors" do
      %{constraint: first, decision: decision} = create_variable_constraint()
      %{constraint: second} = deps = create_variable_constraint(decision)

      attrs = deps |> valid_attrs() |> Map.put(:slug, first.slug)
      result = Structure.update_constraint(second, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "delete_constraint/2" do

    test "deletes variable constraint" do
      deps = create_variable_constraint()
      %{constraint: existing, variable: variable, decision: decision} = deps

      to_delete = %Constraint{id: existing.id}
      result = Structure.delete_constraint(to_delete, decision.id)

      assert {:ok, %Constraint{}} = result
      assert nil == Repo.get(Constraint, existing.id)
      assert nil !== Repo.get(Variable, variable.id)
      assert nil !== Repo.get(Decision, decision.id)
    end

    test "deletes calculation constraint" do
      deps = create_calculation_constraint()
      %{constraint: existing, calculation: calculation, decision: decision} = deps

      to_delete = %Constraint{id: existing.id}
      result = Structure.delete_constraint(to_delete, decision.id)

      assert {:ok, %Constraint{}} = result
      assert nil == Repo.get(Constraint, existing.id)
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
