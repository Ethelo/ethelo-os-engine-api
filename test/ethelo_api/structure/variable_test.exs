defmodule EtheloApi.Structure.VariableTest do
  @moduledoc """
  Validations and basic access for Variables
  Includes both the context EtheloApi.Structure, and specific functionality on the Variable schema
  """
  use EtheloApi.DataCase
  @moduletag variable: true, ecto: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.VariableHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Calculation
  alias EtheloApi.Structure.OptionDetail
  alias EtheloApi.Structure.OptionFilter
  alias EtheloApi.Structure.Variable

  describe "list_variables/1" do
    test "filters by decision_id" do
      %{variable: _excluded} = create_detail_variable()
      %{variable: to_match1, decision: decision} = create_detail_variable()

      %{filter_variable: to_match2, detail_variable: to_match3} =
        create_calculation_with_variables(decision)

      result = Structure.list_variables(decision)
      assert [%Variable{} = first_result | _] = result
      assert_result_ids_match([to_match1, to_match2, to_match3], result)
      assert Enum.count(result) == 3
      refute %Ecto.Association.NotLoaded{} == first_result.calculations
    end

    test "filters by id" do
      %{variable: to_match, decision: decision} = create_detail_variable()
      %{variable: _excluded} = create_detail_variable(decision)

      modifiers = %{id: to_match.id}
      result = Structure.list_variables(decision, modifiers)

      assert [%Variable{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by slug" do
      %{variable: to_match, decision: decision} = create_detail_variable()
      %{variable: _excluded} = create_detail_variable(decision)

      modifiers = %{slug: to_match.slug}
      result = Structure.list_variables(decision, modifiers)

      assert [%Variable{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by option_filter_id" do
      %{variable: to_match, decision: decision} = create_filter_variable()
      %{variable: _excluded} = create_filter_variable(decision)

      modifiers = %{option_filter_id: to_match.option_filter_id}
      result = Structure.list_variables(decision, modifiers)

      assert [%Variable{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by option_detail_id" do
      %{variable: to_match, decision: decision} = create_detail_variable()
      %{variable: _excluded} = create_detail_variable(decision)

      modifiers = %{option_detail_id: to_match.option_detail_id}
      result = Structure.list_variables(decision, modifiers)

      assert [%Variable{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Structure.list_variables(nil) end
    end
  end

  describe "suggested_variables/1" do
    # see EtheloApi.Structure.VariableBuilder for full tests, this just tests the interface

    test "returns suggested Variables for OptionDetail" do
      %{decision: decision} = create_option_detail(:float)

      result = Structure.suggested_variables(decision)

      assert [%Variable{}, %Variable{}] = result
    end

    test "returns suggested Variables for OptionFilter" do
      %{decision: decision} = create_option_category_filter()

      result = Structure.suggested_variables(decision)

      assert [%Variable{}] = result
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn ->
        Structure.suggested_variables(nil)
      end
    end
  end

  describe "get_variable/2" do
    test "filters by decision_id as struct" do
      %{filter_variable: to_match, decision: decision, calculation: calculation} =
        create_calculation_with_variables()

      calculation_id = calculation.id

      result = Structure.get_variable(to_match.id, decision)

      assert %Variable{} = result
      assert result.id == to_match.id

      with_calculations = result |> EtheloApi.Repo.preload([:calculations])

      assert [%Calculation{id: ^calculation_id}] = with_calculations.calculations
    end

    test "filters by decision_id" do
      %{variable: to_match, decision: decision} = create_detail_variable()

      result = Structure.get_variable(to_match.id, decision.id)

      assert %Variable{} = result
      assert result.id == to_match.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Structure.get_variable(1, nil) end
    end

    test "raises without a Variable id" do
      assert_raise ArgumentError, ~r/Variable/, fn ->
        Structure.get_variable(nil, create_decision())
      end
    end

    test "missing record returns nil" do
      decision = create_decision()

      result = Structure.get_variable(1929, decision.id)

      assert result == nil
    end

    test "invalid Decision returns nil" do
      %{variable: to_match} = create_detail_variable()
      decision2 = create_decision()

      result = Structure.get_variable(to_match.id, decision2)

      assert result == nil
    end
  end

  describe "create_variable/2" do
    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn ->
        Structure.create_variable(invalid_attrs(), nil)
      end
    end

    test "empty data returns changeset" do
      decision = create_decision()

      result = Structure.create_variable(empty_attrs(), decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "can't be blank" in errors.method
      assert hd(errors.option_filter_id) =~ ~r/must specify either/
      assert hd(errors.option_detail_id) =~ ~r/must specify either/

      expected = [:title, :slug, :method, :option_filter_id, :option_detail_id]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      decision = create_decision()

      attrs = invalid_attrs()
      result = Structure.create_variable(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert hd(errors.option_filter_id) =~ ~r/must specify either/
      assert hd(errors.option_detail_id) =~ ~r/must specify either/
      assert "is invalid" in errors.method
      expected = [:title, :slug, :method, :option_filter_id, :option_detail_id]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "both OptionDetail and OptionFilter defined with detail method returns changeset" do
      deps = detail_variable_deps()
      %{decision: decision} = deps
      %{option_filter: option_filter} = create_option_category_filter(decision)

      attrs = deps |> valid_attrs() |> Map.put(:option_filter_id, option_filter.id)

      result = Structure.create_variable(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert hd(errors.option_filter_id) =~ ~r/must be blank/
      expected = [:option_filter_id]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "create_variable/2 with OptionDetail" do
    test "creates with valid integer detail" do
      deps = create_option_detail(:integer)
      %{decision: decision} = deps

      attrs = valid_attrs(deps)
      result = Structure.create_variable(attrs, decision)

      assert {:ok, %Variable{} = new_record} = result
      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "creates with valid float detail" do
      deps = create_option_detail(:float)
      %{decision: decision} = deps

      attrs = valid_attrs(deps)
      result = Structure.create_variable(attrs, decision)

      assert {:ok, %Variable{} = new_record} = result
      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "duplicate config returns changeset" do
      deps = create_detail_variable()
      %{decision: decision, variable: existing} = deps
      attrs = valid_attrs(deps)

      attrs =
        attrs
        |> Map.put(:slug, "foobar")
        |> Map.put(:method, existing.method)

      result = Structure.create_variable(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.method
    end

    test "OptionDetail from different Decision returns changeset" do
      deps = detail_variable_deps()
      %{decision: decision} = deps
      %{option_detail: mismatch} = create_option_detail(:integer)

      attrs = deps |> Map.put(:option_detail, mismatch) |> valid_attrs()

      result = Structure.create_variable(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.option_detail_id
    end

    test "non number OptionDetails returns changeset" do
      deps = detail_variable_deps()
      %{decision: decision} = deps
      %{option_detail: option_detail_boolean} = create_option_detail(decision, :boolean)
      %{option_detail: option_detail_datetime} = create_option_detail(decision, :datetime)
      %{option_detail: option_detail_string} = create_option_detail(decision, :string)
      option_details = [option_detail_boolean, option_detail_datetime, option_detail_string]

      for option_detail <- option_details do
        attrs = valid_attrs(%{option_detail: option_detail})

        result = Structure.create_variable(attrs, decision)

        assert {:error, %Ecto.Changeset{} = changeset} = result
        errors = error_map(changeset)

        assert hd(errors.option_detail_id) =~ ~r/number format/
      end
    end
  end

  describe "create_variable/2 with OptionFilter" do
    test "creates with valid data" do
      deps = filter_variable_deps()
      %{decision: decision} = deps

      attrs = valid_attrs(deps)
      result = Structure.create_variable(attrs, decision)

      assert {:ok, %Variable{} = new_record} = result
      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "duplicate config returns changeset" do
      deps = create_filter_variable()
      %{decision: decision, variable: existing} = deps

      attrs =
        deps
        |> valid_attrs()
        |> Map.put(:slug, "foobar")
        |> Map.put(:method, existing.method)

      result = Structure.create_variable(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.method
    end

    test "OptionFilter from different Decision returns changeset" do
      %{decision: decision} = deps = filter_variable_deps()
      %{option_filter: mismatch} = create_option_category_filter()

      attrs = deps |> Map.put(:option_filter, mismatch) |> valid_attrs()
      result = Structure.create_variable(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.option_filter_id
    end
  end

  describe "create_variable/2 OptionDetail methods" do
    @detail_methods ~w(sum_selected sum_all mean_selected mean_all)

    test "allows with OptionDetail source" do
      deps = detail_variable_deps()
      %{decision: decision} = deps
      attrs = deps |> valid_attrs() |> Map.put(:slug, "")

      for method <- @detail_methods do
        attrs = %{attrs | method: method, title: method}

        result = Structure.create_variable(attrs, decision)

        assert {:ok, %Variable{}} = result
      end
    end

    test "disallows with OptionFilter source" do
      deps = filter_variable_deps()
      %{decision: decision} = deps
      attrs = deps |> valid_attrs() |> Map.put(:slug, "")

      for method <- @detail_methods do
        attrs = %{attrs | method: method, title: method}

        result = Structure.create_variable(attrs, decision)

        assert {:error, %Ecto.Changeset{} = changeset} = result
        errors = error_map(changeset) |> Map.keys()
        assert :option_filter_id in errors
      end
    end
  end

  describe "create_variable/2 OptionFilter methods" do
    @filter_methods ~w(count_selected count_all)

    test "allows with OptionFilter source" do
      deps = filter_variable_deps()
      %{decision: decision} = deps
      attrs = deps |> valid_attrs() |> Map.put(:slug, "")

      for method <- @filter_methods do
        attrs = %{attrs | method: method, title: method}

        result = Structure.create_variable(attrs, decision)

        assert {:ok, %Variable{}} = result
      end
    end

    test "disallows with OptionDetail source" do
      deps = detail_variable_deps()
      %{decision: decision} = deps
      attrs = deps |> valid_attrs() |> Map.put(:slug, "")

      for method <- @filter_methods do
        attrs = %{attrs | method: method, title: method}

        result = Structure.create_variable(attrs, decision)

        assert {:error, %Ecto.Changeset{} = changeset} = result

        errors = error_map(changeset) |> Map.keys()
        assert :option_detail_id in errors
      end
    end
  end

  describe "create_variable/2 slug checks" do
    test "duplicate title with no slug defined generates variant slug" do
      deps = create_detail_variable()
      %{variable: existing, decision: decision} = deps

      attrs = deps |> valid_attrs() |> Map.put(:title, existing.title) |> Map.drop([:slug])
      result = Structure.create_variable(attrs, decision)

      assert {:ok, %Variable{} = new_record} = result

      refute existing.slug == new_record.slug
    end

    test "duplicate slug returns changeset" do
      deps = create_detail_variable()
      %{variable: existing, decision: decision} = deps
      attrs = deps |> valid_attrs() |> Map.put(:slug, existing.slug)

      result = Structure.create_variable(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "update_variable/2" do
    test "empty data returns changeset" do
      %{variable: to_update} = create_detail_variable()

      result = Structure.update_variable(to_update, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "can't be blank" in errors.method
      assert hd(errors.option_detail_id) =~ ~r/must specify either/
      assert hd(errors.option_filter_id) =~ ~r/must specify either/

      expected = [:title, :method, :slug, :option_filter_id, :option_detail_id]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      %{variable: to_update} = create_detail_variable()

      attrs = invalid_attrs()
      result = Structure.update_variable(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.method
      assert hd(errors.option_filter_id) =~ ~r/must specify either/
      assert hd(errors.option_detail_id) =~ ~r/must specify either/
      expected = [:title, :slug, :method, :option_filter_id, :option_detail_id]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "both OptionDetail and OptionFilter defined with filter methodreturns changeset" do
      deps = create_filter_variable()
      %{variable: to_update, decision: decision} = deps
      %{option_detail: option_detail} = create_option_detail(decision)

      attrs = deps |> valid_attrs() |> Map.put(:option_detail_id, option_detail.id)
      result = Structure.update_variable(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert hd(errors.option_detail_id) =~ ~r/number format/
    end

    test "Decision update ignored" do
      %{variable: to_update} = create_detail_variable()
      decision2 = create_decision()

      attrs = %{title: "Updated Title", decision: decision2}
      result = Structure.update_variable(to_update, attrs)

      assert {:ok, updated} = result
      assert updated.title == attrs.title
      refute updated.decision.id == decision2.id
      assert updated.decision.id == to_update.decision_id
    end

    test "slug change with associated Calculation returns changeset" do
      %{filter_variable: to_update} = create_calculation_with_variables()

      attrs = %{slug: "i-want-a-new-slug"}
      result = Structure.update_variable(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "cannot be changed, Variable in use" in errors.slug
    end
  end

  describe "update_variable/2 with OptionDetail" do
    test "updates with valid data" do
      deps = create_detail_variable()
      %{variable: to_update} = deps
      attrs = valid_attrs(deps)

      result = Structure.update_variable(to_update, attrs)

      assert {:ok, %Variable{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "OptionDetail from different Decision returns changeset" do
      deps = create_detail_variable()
      %{variable: to_update} = deps
      %{option_detail: mismatch} = create_option_detail()
      attrs = deps |> Map.put(:option_detail, mismatch) |> valid_attrs()

      result = Structure.update_variable(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.option_detail_id
    end

    test "non number OptionDetails returns changeset" do
      deps = create_detail_variable()
      %{variable: to_update, decision: decision} = deps
      %{option_detail: option_detail_boolean} = create_option_detail(decision, :boolean)
      %{option_detail: option_detail_datetime} = create_option_detail(decision, :datetime)
      %{option_detail: option_detail_string} = create_option_detail(decision, :string)
      option_details = [option_detail_boolean, option_detail_datetime, option_detail_string]

      for option_detail <- option_details do
        attrs = valid_attrs(%{option_detail: option_detail})

        result = Structure.update_variable(to_update, attrs)

        assert {:error, %Ecto.Changeset{} = changeset} = result
        errors = error_map(changeset)
        assert hd(errors.option_detail_id) =~ ~r/number format/
      end
    end
  end

  describe "update_variable/2 with OptionFilter" do
    test "updates with valid data" do
      %{variable: to_update} = deps = create_filter_variable()

      attrs = valid_attrs(deps)
      result = Structure.update_variable(to_update, attrs)

      assert {:ok, %Variable{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "OptionFilter from different Decision returns changeset" do
      deps = create_filter_variable()
      %{variable: to_update} = deps
      %{option_filter: mismatch} = create_option_category_filter()
      attrs = deps |> Map.put(:option_filter, mismatch) |> valid_attrs()

      result = Structure.update_variable(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.option_filter_id
    end
  end

  describe "update_variable/2 slug checks" do
    test "duplicate title with no slug defined does not update slug" do
      %{variable: duplicate, decision: decision} = create_detail_variable()
      %{variable: to_update} = deps = create_detail_variable(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, duplicate.title) |> Map.drop([:slug])
      result = Structure.update_variable(to_update, attrs)

      assert {:ok, %Variable{} = updated} = result

      assert to_update.slug == updated.slug
    end

    test "duplicate title with nil slug defined generates variant slug" do
      %{variable: duplicate, decision: decision} = create_detail_variable()
      %{variable: to_update} = deps = create_detail_variable(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, duplicate.title) |> Map.put(:slug, nil)
      result = Structure.update_variable(to_update, attrs)

      assert {:ok, %Variable{} = updated} = result
      refute to_update.slug == updated.slug
      refute to_update.slug == duplicate.slug
    end

    test "duplicate slug returns changeset" do
      %{variable: duplicate, decision: decision} = create_detail_variable()
      %{variable: to_update} = deps = create_detail_variable(decision)

      attrs = deps |> valid_attrs() |> Map.put(:slug, duplicate.slug)
      result = Structure.update_variable(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "update_used_variable/2" do
    test "used Variables get swapped" do
      deps = create_calculation_with_variables()
      %{decision: decision, calculation: calculation} = deps
      %{filter_variable: to_update} = deps
      result = Structure.update_used_variable(to_update, %{slug: "new_slug"})

      assert {:ok, %Variable{} = updated} = result
      assert updated.slug != to_update.slug

      updated_calc = Structure.get_calculation(calculation.id, decision)
      assert calculation.expression != updated_calc.expression
    end
  end

  describe "delete_variable/2" do
    test "deletes detail Variable" do
      deps = create_detail_variable()
      %{variable: to_update, decision: decision, option_detail: option_detail} = deps

      to_delete = %Variable{id: to_update.id}
      result = Structure.delete_variable(to_delete, decision.id)

      assert {:ok, %Variable{}} = result
      assert nil == Repo.get(Variable, to_update.id)
      assert nil !== Repo.get(Decision, decision.id)
      assert nil !== Repo.get(OptionDetail, option_detail.id)
    end

    test "deletes OptonFilter Variable" do
      deps = create_filter_variable()
      %{variable: to_delete, decision: decision, option_filter: option_filter} = deps

      result = Structure.delete_variable(to_delete, decision.id)

      assert {:ok, %Variable{}} = result
      assert nil == Repo.get(Variable, to_delete.id)
      assert nil !== Repo.get(Decision, decision.id)
      assert nil !== Repo.get(OptionFilter, option_filter.id)
    end

    test "deleting Variable with Calculation returns changeset" do
      deps = create_calculation_with_variables()
      %{detail_variable: to_delete, decision: decision} = deps

      result = Structure.delete_variable(to_delete, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "cannot be deleted" in errors.id
      assert %Variable{} = Repo.get(Variable, to_delete.id)
      assert nil !== Repo.get(Decision, decision.id)
    end
  end

  describe "documentation" do
    test "has documentation module" do
      assert %{} = Variable.strings()
      assert %{} = Variable.examples()
      assert is_list(Variable.fields())
    end
  end
end
