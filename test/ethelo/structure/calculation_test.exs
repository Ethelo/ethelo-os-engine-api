defmodule EtheloApi.Structure.CalculationTest do
  @moduledoc """
  Validations and basic access for Calculations
  Includes both the context EtheloApi.Structure, and specific functionality on the Calculation schema
  """
  use EtheloApi.DataCase
  @moduletag calculation: true, ethelo: true, ecto: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.CalculationHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Variable
  alias EtheloApi.Structure.Calculation

  describe "list_calculations/1" do

    test "returns all records matching a Decision" do
      deps = create_calculation_with_variables()
      %{calculation: first, decision: decision} = deps
      %{filter_variable: filter_variable, detail_variable: detail_variable} = deps
      variables = [filter_variable, detail_variable]
      %{calculation: second} = create_calculation(decision)

      result = Structure.list_calculations(decision)
      assert [%Calculation{} = first_result, second_result] = result
      assert_result_ids_match([first, second], result)
      refute %Ecto.Association.NotLoaded{} == first_result.variables
      assert_variables_in_result(variables, first_result.variables ++ second_result.variables)
    end

    test "returns record matching id" do
      %{calculation: matching, decision: decision} = create_calculation()
      %{calculation: _not_matching} = create_calculation(decision)

      filters = %{id: matching.id}
      result = Structure.list_calculations(decision, filters)

      assert [%Calculation{}] = result
      assert_result_ids_match([matching], result)
    end

    test "returns record matching slug" do
      %{calculation: matching, decision: decision} = create_calculation()
      %{calculation: _not_matching} = create_calculation(decision)

      filters = %{slug: matching.slug}
      result = Structure.list_calculations(decision, filters)

      assert [%Calculation{}] = result
      assert_result_ids_match([matching], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Structure.list_calculations(nil) end
    end
  end

  describe "get_calculation/2" do

    test "returns the matching record by Decision object" do
      deps = create_calculation_with_variables()
      %{calculation: record, decision: decision} = deps
      %{filter_variable: filter_variable, detail_variable: detail_variable} = deps
      variables = [filter_variable, detail_variable]

      result = Structure.get_calculation(record.id, decision)

      assert %Calculation{} = result
      assert result.id == record.id
      assert_variables_in_result(variables, result.variables)
    end

    test "returns the matching record by Decision.id" do
      deps = create_calculation_with_variables()
      %{calculation: record, decision: decision} = deps

      result = Structure.get_calculation(record.id, decision.id)

      assert %Calculation{} = result
      assert result.id == record.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Structure.get_calculation(1, nil) end
    end

    test "raises without an Calculation id" do
      assert_raise ArgumentError, ~r/Calculation/,
        fn -> Structure.get_calculation(nil, create_decision()) end
    end

    test "returns nil if id does not exist" do
      decision = create_decision()

      result = Structure.get_calculation(1929, decision.id)

      assert result == nil
    end

    test "returns nil if Decision does not match" do
      %{calculation: record} = create_calculation()
      decision2 = create_decision()

      result = Structure.get_calculation(record.id, decision2)

      assert result == nil
    end
  end

  describe "create_calculation/2" do
    test "creates with valid data" do
      deps = calculation_deps()
      %{decision: decision} = deps

      attrs = valid_attrs()
      result = Structure.create_calculation(decision, attrs)

      assert {:ok, %Calculation{} = new_record} = result
      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "identifies and links variables" do
      deps = create_calculation_with_variables()
      %{decision: decision} = deps
      %{filter_variable: filter_variable, detail_variable: detail_variable} = deps
      variables = [filter_variable, detail_variable]

      attrs = %{valid_attrs() | expression: "#{detail_variable.slug} + #{filter_variable.slug}"}

      result = Structure.create_calculation(decision, attrs)

      assert {:ok, %Calculation{} = new_record} = result
      assert_variables_in_result(variables, new_record.variables)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Structure.create_calculation(nil, invalid_attrs()) end
    end

    test "with empty data returns errors" do
      decision = create_decision()

      result = Structure.create_calculation(decision, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "can't be blank" in errors.title
      refute :sort in Map.keys(errors)
    end

    test "with invalid data returns errors" do
      decision = create_decision()

      attrs = invalid_attrs()
      result = Structure.create_calculation(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "must include at least one word" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.public
      assert "is invalid" in errors.sort
      assert hd(errors.expression) =~ ~r/number or variable/
      assert [_, _, _, _, _] = Map.keys(errors)
    end

    test "Nonexistent variable returns errors" do
      deps = calculation_deps()
      %{decision: decision} = deps

      attrs = %{valid_attrs() | expression: "not_a_var"}
      result = Structure.create_calculation(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert hd(errors.expression) =~ ~r/not_a_var/
    end

    test "a Variable from different decision returns errors" do
      deps = calculation_deps()
      %{decision: decision} = deps
      %{variable: variable} = create_detail_variable()
      slug = variable.slug

      attrs = %{valid_attrs() | expression: slug}
      result = Structure.create_calculation(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert hd(errors.expression) =~ ~r/#{slug}/
    end
  end

  describe "create_calculation/2 slug checks" do

    test "duplicate title with no slug defined generates variant slug" do
      deps = create_calculation()
      %{calculation: existing, decision: decision} = deps

      attrs = valid_attrs() |> Map.put(:title, existing.title) |> Map.drop([:slug])
      result = Structure.create_calculation(decision, attrs)

      assert {:ok, %Calculation{} = new_record} = result

      refute existing.slug == new_record.slug
    end

    test "duplicate slug returns errors" do
      deps = create_calculation()
      %{calculation: existing, decision: decision} = deps
      attrs = valid_attrs() |> Map.put(:slug, existing.slug)

      result = Structure.create_calculation(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "update_calculation/2" do
    test "updates with valid data" do
      deps = create_calculation()
      %{calculation: existing} = deps

      attrs = valid_attrs()
      result = Structure.update_calculation(existing, attrs)

      assert {:ok, %Calculation{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "identifies and links variables" do
      deps = create_calculation_with_variables()
      %{calculation: calculation, decision: decision} = deps
      %{variable: variable} = create_detail_variable(decision)

      attrs = %{expression: "#{variable.slug}"}
      result = Structure.update_calculation(calculation, attrs)

      assert {:ok, %Calculation{} = updated} = result
      assert_variables_in_result([variable], updated.variables)
    end


    test "empty data returns errors" do
      %{calculation: existing} = create_calculation()

      result = Structure.update_calculation(existing, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "can't be blank" in errors.title
      assert "can't be blank" in errors.expression
      assert "must have numbers and/or letters" in errors.slug
      assert [_, _, _] = Map.keys(errors)
    end

    test "invalid data returns errors" do
      %{calculation: existing} = create_calculation()

      attrs = invalid_attrs()
      result = Structure.update_calculation(existing, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "must include at least one word" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.public
      assert "is invalid" in errors.sort
      assert hd(errors.expression) =~ ~r/number or variable/
      assert [_, _, _, _, _] = Map.keys(errors)
    end

    test "Nonexistent variable returns errors" do
      %{calculation: existing} = create_calculation()

      attrs = %{valid_attrs() | expression: "not_a_var"}
      result = Structure.update_calculation(existing, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert hd(errors.expression) =~ ~r/not_a_var/
    end

    test "a Variable from different decision returns errors" do
      %{calculation: existing} = create_calculation()
      %{variable: variable} = create_detail_variable()
      slug = variable.slug

      attrs = %{valid_attrs() | expression: slug}
      result = Structure.update_calculation(existing, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert hd(errors.expression) =~ ~r/#{slug}/
    end

    test "Decision update ignored" do
      %{calculation: existing} = create_calculation()
      decision2 = create_decision()

      attrs = %{title: "Updated Title", decision: decision2}
      result = Structure.update_calculation(existing, attrs)

      assert {:ok, updated} = result
      assert updated.title == attrs.title
      refute updated.decision.id == decision2.id
      assert updated.decision.id == existing.decision_id
    end

  end

  describe "update_calculation/2 slug checks" do

    test "a duplicate title with no slug defined does not update slug" do
      %{calculation: first, decision: decision} = create_calculation()
      %{calculation: second}  = create_calculation(decision)

      attrs = valid_attrs() |> Map.put(:title, first.title) |> Map.drop([:slug])
      result = Structure.update_calculation(second, attrs)

      assert {:ok, %Calculation{} = updated} = result

      assert second.slug == updated.slug
    end

    test "a duplicate title with nil slug defined generates variant slug" do
      %{calculation: first, decision: decision} = create_calculation()
      %{calculation: second} = create_calculation(decision)

      attrs = valid_attrs() |> Map.put(:title, first.title) |> Map.put(:slug, nil)
      result = Structure.update_calculation(second, attrs)

      assert {:ok, %Calculation{} = updated} = result
      refute second.slug == updated.slug
      refute second.slug == first.slug
    end

    test "a duplicate slug returns errors" do
      %{calculation: first, decision: decision} = create_calculation()
      %{calculation: second} = create_calculation(decision)

      attrs = valid_attrs() |> Map.put(:slug, first.slug)
      result = Structure.update_calculation(second, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "delete_calculation/2" do

    test "deletes simple calculation" do
      deps = create_calculation()
      %{calculation: existing, decision: decision} = deps

      to_delete = %Calculation{id: existing.id}
      result = Structure.delete_calculation(to_delete, decision.id)

      assert {:ok, %Calculation{}} = result
      assert nil == Repo.get(Calculation, existing.id)
      assert nil !== Repo.get(Decision, decision.id)
    end

    test "deletes calculation with variable" do
      deps = create_calculation_with_variables()
      %{calculation: existing, decision: decision} = deps
      %{filter_variable: filter_variable, detail_variable: detail_variable} = deps

      to_delete = %Calculation{id: existing.id}
      result = Structure.delete_calculation(to_delete, decision.id)

      assert {:ok, %Calculation{}} = result
      assert nil == Repo.get(Calculation, existing.id)
      assert nil !== Repo.get(Decision, decision.id)
      assert nil !== Repo.get(Variable, filter_variable.id)
      assert nil !== Repo.get(Variable, detail_variable.id)
    end
  end

  describe "documentation" do
    test "has documentation module" do
      assert %{} = Calculation.strings()
      assert %{} = Calculation.examples()
      assert is_list(Calculation.fields())
    end
  end
end
