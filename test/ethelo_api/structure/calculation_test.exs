defmodule EtheloApi.Structure.CalculationTest do
  @moduledoc """
  Validations and basic access for Calculations
  Includes both the context EtheloApi.Structure, and specific functionality on the Calculation schema
  """
  use EtheloApi.DataCase
  @moduletag calculation: true, ecto: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.CalculationHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Variable
  alias EtheloApi.Structure.Calculation

  describe "list_calculations/1" do
    test "filters by decision_id" do
      deps = create_calculation_with_variables()
      %{calculation: to_match1, decision: decision} = deps
      %{filter_variable: filter_variable, detail_variable: detail_variable} = deps
      variables = [filter_variable, detail_variable]
      %{calculation: to_match2} = create_calculation(decision)

      result = Structure.list_calculations(decision)
      assert [%Calculation{} = first_result, second_result] = result
      assert_result_ids_match([to_match1, to_match2], result)
      refute %Ecto.Association.NotLoaded{} == first_result.variables
      assert_variables_in_result(variables, first_result.variables ++ second_result.variables)
    end

    test "filters by id" do
      %{calculation: to_match, decision: decision} = create_calculation()
      %{calculation: _excluded} = create_calculation(decision)

      modifiers = %{id: to_match.id}
      result = Structure.list_calculations(decision, modifiers)

      assert [%Calculation{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by slug" do
      %{calculation: to_match, decision: decision} = create_calculation()
      %{calculation: _excluded} = create_calculation(decision)

      modifiers = %{slug: to_match.slug}
      result = Structure.list_calculations(decision, modifiers)

      assert [%Calculation{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Structure.list_calculations(nil) end
    end
  end

  describe "get_calculation/2" do
    test "filters by decision_id as struct" do
      deps = create_calculation_with_variables()
      %{calculation: to_match, decision: decision} = deps
      %{filter_variable: filter_variable, detail_variable: detail_variable} = deps
      variables = [filter_variable, detail_variable]

      result = Structure.get_calculation(to_match.id, decision)

      assert %Calculation{} = result
      assert result.id == to_match.id
      assert_variables_in_result(variables, result.variables)
    end

    test "filters by decision_id" do
      deps = create_calculation_with_variables()
      %{calculation: to_match, decision: decision} = deps

      result = Structure.get_calculation(to_match.id, decision.id)

      assert %Calculation{} = result
      assert result.id == to_match.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Structure.get_calculation(1, nil) end
    end

    test "raises without a Calculation id" do
      assert_raise ArgumentError, ~r/Calculation/, fn ->
        Structure.get_calculation(nil, create_decision())
      end
    end

    test "missing record returns nil" do
      decision = create_decision()

      result = Structure.get_calculation(1929, decision.id)

      assert result == nil
    end

    test "Decision mismatch returns nil" do
      %{calculation: to_match} = create_calculation()
      decision2 = create_decision()

      result = Structure.get_calculation(to_match.id, decision2)

      assert result == nil
    end
  end

  describe "create_calculation/2" do
    test "creates with valid data" do
      deps = calculation_deps()
      %{decision: decision} = deps

      attrs = valid_attrs()
      result = Structure.create_calculation(attrs, decision)

      assert {:ok, %Calculation{} = new_record} = result
      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "identifies and links Variables" do
      deps = create_calculation_with_variables()
      %{decision: decision} = deps
      %{filter_variable: filter_variable, detail_variable: detail_variable} = deps
      variables = [filter_variable, detail_variable]

      attrs = %{valid_attrs() | expression: "#{detail_variable.slug} + #{filter_variable.slug}"}

      result = Structure.create_calculation(attrs, decision)

      assert {:ok, %Calculation{} = new_record} = result
      assert_variables_in_result(variables, new_record.variables)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn ->
        Structure.create_calculation(invalid_attrs(), nil)
      end
    end

    test "empty data returns changeset" do
      decision = create_decision()

      result = Structure.create_calculation(empty_attrs(), decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      expected = [:title, :slug, :expression]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      decision = create_decision()

      attrs = invalid_attrs()
      result = Structure.create_calculation(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.public
      assert "is invalid" in errors.sort
      assert hd(errors.expression) =~ ~r/number or Variable/
      expected = [:title, :slug, :public, :sort, :expression]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "Nonexistent Variable returns changeset" do
      deps = calculation_deps()
      %{decision: decision} = deps

      attrs = %{valid_attrs() | expression: "not_a_var"}
      result = Structure.create_calculation(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert hd(errors.expression) =~ ~r/not_a_var/
    end

    test "Variable from different Decision returns changeset" do
      deps = calculation_deps()
      %{decision: decision} = deps
      %{variable: mismatch} = create_detail_variable()
      slug = mismatch.slug

      attrs = %{valid_attrs() | expression: slug}
      result = Structure.create_calculation(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert hd(errors.expression) =~ ~r/#{slug}/
    end
  end

  describe "create_calculation/2 slug checks" do
    test "duplicate title with no slug defined generates variant slug" do
      deps = create_calculation()
      %{calculation: existing, decision: decision} = deps

      attrs = valid_attrs() |> Map.put(:title, existing.title) |> Map.drop([:slug])
      result = Structure.create_calculation(attrs, decision)

      assert {:ok, %Calculation{} = new_record} = result

      refute existing.slug == new_record.slug
    end

    test "duplicate slug returns changeset" do
      deps = create_calculation()
      %{calculation: existing, decision: decision} = deps
      attrs = valid_attrs() |> Map.put(:slug, existing.slug)

      result = Structure.create_calculation(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "update_calculation/2" do
    test "updates with valid data" do
      deps = create_calculation()
      %{calculation: to_update} = deps

      attrs = valid_attrs()
      result = Structure.update_calculation(to_update, attrs)

      assert {:ok, %Calculation{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "identifies and links Variables" do
      deps = create_calculation_with_variables()
      %{calculation: calculation, decision: decision} = deps
      %{variable: variable} = create_detail_variable(decision)

      attrs = %{expression: "#{variable.slug}"}
      result = Structure.update_calculation(calculation, attrs)

      assert {:ok, %Calculation{} = updated} = result
      assert_variables_in_result([variable], updated.variables)
    end

    test "empty data returns changeset" do
      %{calculation: to_update} = create_calculation()

      result = Structure.update_calculation(to_update, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "can't be blank" in errors.expression
      assert "must have numbers and/or letters" in errors.slug
      expected = [:title, :slug, :expression]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      %{calculation: to_update} = create_calculation()

      attrs = invalid_attrs()
      result = Structure.update_calculation(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.public
      assert "is invalid" in errors.sort
      assert hd(errors.expression) =~ ~r/number or Variable/

      expected = [:title, :slug, :expression, :public, :sort]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "Nonexistent Variable returns changeset" do
      %{calculation: to_update} = create_calculation()

      attrs = %{valid_attrs() | expression: "not_a_var"}
      result = Structure.update_calculation(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert hd(errors.expression) =~ ~r/not_a_var/
    end

    test "Variable from different Decision returns changeset" do
      %{calculation: to_update} = create_calculation()
      %{variable: mismatch} = create_detail_variable()
      slug = mismatch.slug

      attrs = %{valid_attrs() | expression: slug}
      result = Structure.update_calculation(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert hd(errors.expression) =~ ~r/#{slug}/
    end

    test "Decision update ignored" do
      %{calculation: to_update} = create_calculation()
      decision2 = create_decision()

      attrs = %{title: "Updated Title", decision: decision2}
      result = Structure.update_calculation(to_update, attrs)

      assert {:ok, updated} = result
      assert updated.title == attrs.title
      refute updated.decision.id == decision2.id
      assert updated.decision.id == to_update.decision_id
    end
  end

  describe "update_calculation/2 slug checks" do
    test "duplicate title with no slug defined does not update slug" do
      %{calculation: duplicate, decision: decision} = create_calculation()
      %{calculation: to_update} = create_calculation(decision)

      attrs = valid_attrs() |> Map.put(:title, duplicate.title) |> Map.drop([:slug])
      result = Structure.update_calculation(to_update, attrs)

      assert {:ok, %Calculation{} = updated} = result

      assert to_update.slug == updated.slug
    end

    test "duplicate title with nil slug defined generates variant slug" do
      %{calculation: duplicate, decision: decision} = create_calculation()
      %{calculation: to_update} = create_calculation(decision)

      attrs = valid_attrs() |> Map.put(:title, duplicate.title) |> Map.put(:slug, nil)
      result = Structure.update_calculation(to_update, attrs)

      assert {:ok, %Calculation{} = updated} = result
      refute to_update.slug == updated.slug
      refute to_update.slug == duplicate.slug
    end

    test "duplicate slug returns changeset" do
      %{calculation: duplicate, decision: decision} = create_calculation()
      %{calculation: to_update} = create_calculation(decision)

      attrs = valid_attrs() |> Map.put(:slug, duplicate.slug)
      result = Structure.update_calculation(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "delete_calculation/2" do
    test "deletes simple calculation" do
      deps = create_calculation()
      %{calculation: to_delete, decision: decision} = deps

      result = Structure.delete_calculation(to_delete, decision.id)

      assert {:ok, %Calculation{}} = result
      assert nil == Repo.get(Calculation, to_delete.id)
      assert nil !== Repo.get(Decision, decision.id)
    end

    test "deletes calculation with Variable" do
      deps = create_calculation_with_variables()
      %{calculation: to_delete, decision: decision} = deps
      %{filter_variable: filter_variable, detail_variable: detail_variable} = deps

      result = Structure.delete_calculation(to_delete, decision.id)

      assert {:ok, %Calculation{}} = result
      assert nil == Repo.get(Calculation, to_delete.id)
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
