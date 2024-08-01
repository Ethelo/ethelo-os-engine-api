defmodule EtheloApi.Structure.VariableTest do
  @moduledoc """
  Validations and basic access for Variables
  Includes both the context EtheloApi.Structure, and specific functionality on the Variable schema
  """
  use EtheloApi.DataCase
  @moduletag variable: true, ethelo: true, ecto: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.VariableHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Calculation
  alias EtheloApi.Structure.OptionDetail
  alias EtheloApi.Structure.OptionFilter
  alias EtheloApi.Structure.Variable

  describe "list_variables/1" do

    test "returns all records matching a Decision" do
      create_detail_variable() # should not be returned
      %{variable: first, decision: decision} = create_detail_variable()
      %{filter_variable: second, detail_variable: third} = create_calculation_with_variables(decision)

      result = Structure.list_variables(decision)
      assert [%Variable{} = first_result | _] = result
      assert_result_ids_match([first, second, third], result)
      assert Enum.count(result) == 3
      refute %Ecto.Association.NotLoaded{} == first_result.calculations
    end

    test "returns record matching id" do
      %{variable: matching, decision: decision} = create_detail_variable()
      %{variable: _not_matching} = create_detail_variable(decision)

      filters = %{id: matching.id}
      result = Structure.list_variables(decision, filters)

      assert [%Variable{}] = result
      assert_result_ids_match([matching], result)
    end

    test "returns record matching slug" do
      %{variable: matching, decision: decision} = create_detail_variable()
      %{variable: _not_matching} = create_detail_variable(decision)

      filters = %{slug: matching.slug}
      result = Structure.list_variables(decision, filters)

      assert [%Variable{}] = result
      assert_result_ids_match([matching], result)
    end

    test "returns records matching an OptionFilter" do
      %{variable: matching, decision: decision} = create_filter_variable()
      %{variable: _not_matching} = create_filter_variable(decision)

      filters = %{option_filter_id: matching.option_filter_id}
      result = Structure.list_variables(decision, filters)

      assert [%Variable{}] = result
      assert_result_ids_match([matching], result)
    end

    test "returns records matching an OptionDetail" do
      %{variable: matching, decision: decision} = create_detail_variable()
      %{variable: _not_matching} = create_detail_variable(decision)

      filters = %{option_detail_id: matching.option_detail_id}
      result = Structure.list_variables(decision, filters)

      assert [%Variable{}] = result
      assert_result_ids_match([matching], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Structure.list_variables(nil) end
    end
  end

  describe "suggested_variables/1" do
    # see EtheloApi.Constraints.VariableBuilder for full tests, this just tests the interface

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

    test "returns the matching record by Decision object" do
      %{filter_variable: record, decision: decision, calculation: calculation} = create_calculation_with_variables()
      calculation_id = calculation.id

      result = Structure.get_variable(record.id, decision)

      assert %Variable{} = result
      assert result.id == record.id
      assert [%Calculation{id: ^calculation_id}] = result.calculations
    end

    test "returns the matching record by Decision.id" do
      %{variable: record, decision: decision} = create_detail_variable()

      result = Structure.get_variable(record.id, decision.id)

      assert %Variable{} = result
      assert result.id == record.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Structure.get_variable(1, nil) end
    end

    test "raises without an Variable id" do
      assert_raise ArgumentError, ~r/Variable/,
        fn -> Structure.get_variable(nil, create_decision()) end
    end

    test "returns nil if id does not exist" do
      decision = create_decision()

      result = Structure.get_variable(1929, decision.id)

      assert result == nil
    end

    test "returns nil with invalid decision id " do
      %{variable: record} = create_detail_variable()
      decision2 = create_decision()

      result = Structure.get_variable(record.id, decision2)

      assert result == nil
    end
  end

  describe "create_variable/2" do
    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Structure.create_variable(nil, invalid_attrs()) end
    end

    test "with empty data returns errors" do
      decision = create_decision()

      result = Structure.create_variable(decision, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert hd(errors.option_filter_id) =~ ~r/can't be blank/
      assert hd(errors.option_detail_id) =~ ~r/can't be blank/
      assert "can't be blank" in errors.title
      assert "can't be blank" in errors.method
      assert [_, _, _, _, _] = Map.keys(errors)
    end

    test "with invalid data returns errors" do
      decision = create_decision()

      attrs = invalid_attrs()
      result = Structure.create_variable(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "must include at least one word" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert hd(errors.option_filter_id) =~ ~r/can't be blank/
      assert hd(errors.option_detail_id) =~ ~r/can't be blank/
      assert "is invalid" in errors.method
      assert [_, _, _, _, _] = Map.keys(errors)
    end

    test "with both OptionDetail and OptionFilter defined returns errors" do
      deps = detail_variable_deps()
      %{decision: decision} = deps
      %{option_filter: option_filter} = create_option_category_filter(decision)

      attrs = deps |> valid_attrs() |> Map.put(:option_filter_id, option_filter.id)

      result = Structure.create_variable(decision,  attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert hd(errors.option_filter_id) =~ ~r/must be blank/
      assert hd(errors.option_detail_id) =~ ~r/must be blank/
      assert [_, _] = Map.keys(errors)
    end
  end

  describe "create_variable/2 with OptionDetail" do
    test "creates with valid integer detail" do
      deps = create_option_detail(:integer)
      %{decision: decision} = deps

      attrs = valid_attrs(deps)
      result = Structure.create_variable(decision, attrs)

      assert {:ok, %Variable{} = new_record} = result
      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "creates with valid float detail" do
      deps = create_option_detail(:float)
      %{decision: decision} = deps

      attrs = valid_attrs(deps)
      result = Structure.create_variable(decision, attrs)

      assert {:ok, %Variable{} = new_record} = result
      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "a duplicate config returns errors" do
      deps = create_detail_variable()
      %{decision: decision, variable: existing} = deps
      attrs = valid_attrs(deps)

      attrs = attrs
        |> Map.put(:slug, "foobar")
        |> Map.put(:method, existing.method)
      result = Structure.create_variable(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.method
    end

    test "an OptionDetail from different decision returns errors" do
      deps = detail_variable_deps()
      %{decision: decision} = deps
      %{option_detail: option_detail} = create_option_detail(:integer)

      attrs =  deps |> Map.put(:option_detail, option_detail) |> valid_attrs()

      result = Structure.create_variable(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.option_detail_id
    end

    test "non number OptionDetails returns errors" do
      deps = detail_variable_deps()
      %{decision: decision} = deps
      %{option_detail: option_detail_boolean} = create_option_detail(decision, :boolean)
      %{option_detail: option_detail_datetime} = create_option_detail(decision, :datetime)
      %{option_detail: option_detail_string} = create_option_detail(decision, :string)
      option_details = [option_detail_boolean, option_detail_datetime, option_detail_string]

      for option_detail <- option_details do
        attrs =  valid_attrs(%{option_detail: option_detail})

        result = Structure.create_variable(decision, attrs)

        assert {:error, %Ecto.Changeset{} = changeset} = result
        errors = errors_on(changeset)
        assert "must be a number detail" in errors.option_detail_id
      end
    end
  end

  describe "create_variable/2 with OptionFilter" do
    test "creates with valid data" do
      deps = filter_variable_deps()
      %{decision: decision} = deps

      attrs = valid_attrs(deps)
      result = Structure.create_variable(decision, attrs)

      assert {:ok, %Variable{} = new_record} = result
      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "a duplicate config returns errors" do
      deps = create_filter_variable()
      %{decision: decision, variable: existing} = deps

      attrs = deps
        |> valid_attrs()
        |> Map.put(:slug, "foobar")
        |> Map.put(:method, existing.method)
      result = Structure.create_variable(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.method
    end

    test "an OptionFilter from different decision returns errors" do
      %{decision: decision} = deps = filter_variable_deps()
      %{option_filter: option_filter} = create_option_category_filter()

      attrs = deps |> Map.put(:option_filter, option_filter) |> valid_attrs()
      result = Structure.create_variable(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
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

        result = Structure.create_variable(decision, attrs)

        assert {:ok, %Variable{}} = result
      end
    end

    test "disallows with OptionFilter source" do
      deps = filter_variable_deps()
      %{decision: decision} = deps
      attrs = deps |> valid_attrs() |> Map.put(:slug, "")

      for method <- @detail_methods do
        attrs = %{attrs | method: method, title: method}

        result = Structure.create_variable(decision, attrs)

        assert {:error, %Ecto.Changeset{} = changeset} = result
        errors = errors_on(changeset)
        assert "is invalid" in errors.method
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

        result = Structure.create_variable(decision, attrs)

        assert {:ok, %Variable{}} = result
      end
    end

    test "disallows with OptionDetail source" do
      deps = detail_variable_deps()
      %{decision: decision} = deps
      attrs = deps |> valid_attrs() |> Map.put(:slug, "")

      for method <- @filter_methods do
        attrs = %{attrs | method: method, title: method}

        result = Structure.create_variable(decision, attrs)

        assert {:error, %Ecto.Changeset{} = changeset} = result
        errors = errors_on(changeset)
        assert "is invalid" in errors.method
      end
    end
  end

  describe "create_variable/2 slug checks" do

    test "duplicate title with no slug defined generates variant slug" do
      deps = create_detail_variable()
      %{variable: existing, decision: decision} = deps

      attrs = deps |> valid_attrs() |> Map.put(:title, existing.title) |> Map.drop([:slug])
      result = Structure.create_variable(decision, attrs)

      assert {:ok, %Variable{} = new_record} = result

      refute existing.slug == new_record.slug
    end

    test "duplicate slug returns errors" do
      deps = create_detail_variable()
      %{variable: existing, decision: decision} = deps
      attrs = deps |> valid_attrs() |> Map.put(:slug, existing.slug)

      result = Structure.create_variable(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "update_variable/2" do
    test "empty data returns errors" do
      %{variable: existing} = create_detail_variable()

      result = Structure.update_variable(existing, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "can't be blank" in errors.title
      assert "can't be blank" in errors.method
      assert hd(errors.option_detail_id) =~ ~r/can't be blank/
      assert hd(errors.option_filter_id) =~ ~r/can't be blank/
      assert "must have numbers and/or letters" in errors.slug
      assert [_, _, _, _, _] = Map.keys(errors)
    end

    test "invalid data returns errors" do
      %{variable: existing} = create_detail_variable()

      attrs = invalid_attrs()
      result = Structure.update_variable(existing, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "must include at least one word" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.method
      assert hd(errors.option_filter_id) =~ ~r/can't be blank/
      assert hd(errors.option_detail_id) =~ ~r/can't be blank/
      assert [_, _, _, _, _] = Map.keys(errors)
    end

    test "with both OptionDetail and OptionFilter defined returns errors" do
      deps = create_filter_variable()
      %{variable: variable, decision: decision} = deps
      %{option_detail: option_detail} = create_option_detail(decision)

      attrs = deps |> valid_attrs() |> Map.put(:option_detail_id, option_detail.id)
      result = Structure.update_variable(variable, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert hd(errors.option_filter_id) =~ ~r/must be blank/
      assert hd(errors.option_detail_id) =~ ~r/must be blank/
    end

    test "Decision update ignored" do
      %{variable: existing} = create_detail_variable()
      decision2 = create_decision()

      attrs = %{title: "Updated Title", decision: decision2}
      result = Structure.update_variable(existing, attrs)

      assert {:ok, updated} = result
      assert updated.title == attrs.title
      refute updated.decision.id == decision2.id
      assert updated.decision.id == existing.decision_id
    end

    test "slug change with associated Calculation returns errors" do
      %{filter_variable: existing} = create_calculation_with_variables()

      attrs = %{slug: "i-want-a-new-slug"}
      result = Structure.update_variable(existing, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "cannot be changed, variable in use" in errors.slug
    end
  end

  describe "update_variable/2 with OptionDetail" do
    test "updates with valid data" do
      deps = create_detail_variable()
      %{variable: existing} = deps
      attrs = valid_attrs(deps)

      result = Structure.update_variable(existing, attrs)

      assert {:ok, %Variable{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "OptionDetail from different decision returns errors" do
      deps = create_detail_variable()
      %{variable: variable} = deps
      %{option_detail: option_detail} = create_option_detail()
      attrs = deps |> Map.put(:option_detail, option_detail) |> valid_attrs()

      result = Structure.update_variable(variable, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.option_detail_id
    end

    test "non number OptionDetails returns errors" do
      deps = create_detail_variable()
      %{variable: variable, decision: decision} = deps
      %{option_detail: option_detail_boolean} = create_option_detail(decision, :boolean)
      %{option_detail: option_detail_datetime} = create_option_detail(decision, :datetime)
      %{option_detail: option_detail_string} = create_option_detail(decision, :string)
      option_details = [option_detail_boolean, option_detail_datetime, option_detail_string]

      for option_detail <- option_details do
        attrs =  valid_attrs(%{option_detail: option_detail})

        result = Structure.update_variable(variable, attrs)

        assert {:error, %Ecto.Changeset{} = changeset} = result
        errors = errors_on(changeset)
        assert "must be a number detail" in errors.option_detail_id
      end
    end
  end

  describe "update_variable/2 with OptionFilter" do
    test "updates with valid data" do
      %{variable: existing} = deps = create_filter_variable()

      attrs = valid_attrs(deps)
      result = Structure.update_variable(existing, attrs)

      assert {:ok, %Variable{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "OptionFilter from different decision returns errors" do
      deps = create_filter_variable()
      %{variable: variable} = deps
      %{option_filter: option_filter} = create_option_category_filter()
      attrs = deps |> Map.put(:option_filter, option_filter) |> valid_attrs()

      result = Structure.update_variable(variable, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.option_filter_id
    end
  end

  describe "update_variable/2 slug checks" do

    test "a duplicate title with no slug defined does not update slug" do
      %{variable: first, decision: decision} = create_detail_variable()
      %{variable: second} = deps = create_detail_variable(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, first.title) |> Map.drop([:slug])
      result = Structure.update_variable(second, attrs)

      assert {:ok, %Variable{} = updated} = result

      assert second.slug == updated.slug
    end

    test "a duplicate title with nil slug defined generates variant slug" do
      %{variable: first, decision: decision} = create_detail_variable()
      %{variable: second} = deps = create_detail_variable(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, first.title) |> Map.put(:slug, nil)
      result = Structure.update_variable(second, attrs)

      assert {:ok, %Variable{} = updated} = result
      refute second.slug == updated.slug
      refute second.slug == first.slug
    end

    test "a duplicate slug returns errors" do
      %{variable: first, decision: decision} = create_detail_variable()
      %{variable: second} = deps = create_detail_variable(decision)

      attrs = deps |> valid_attrs() |> Map.put(:slug, first.slug)
      result = Structure.update_variable(second, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.slug
    end
  end
  describe "update_used_variable/2 " do

    test "used variables get swapped" do
      deps = create_calculation_with_variables()
      %{decision: decision, calculation: calculation} = deps
      %{filter_variable: filter_variable} = deps
      result = Structure.update_used_variable(filter_variable, %{slug: "new_slug"})

      assert {:ok, %Variable{} = updated} = result
      assert updated.slug != filter_variable.slug

      updated_calc = Structure.get_calculation(calculation.id, decision)
      assert calculation.expression != updated_calc.expression

    end
  end

  describe "delete_variable/2" do

    test "deletes delete variable" do
      deps = create_detail_variable()
      %{variable: existing, decision: decision, option_detail: option_detail} = deps

      to_delete = %Variable{id: existing.id}
      result = Structure.delete_variable(to_delete, decision.id)

      assert {:ok, %Variable{}} = result
      assert nil == Repo.get(Variable, existing.id)
      assert nil !== Repo.get(Decision, decision.id)
      assert nil !== Repo.get(OptionDetail, option_detail.id)
    end

    test "deletes filter variable" do
      deps = create_filter_variable()
      %{variable: existing, decision: decision, option_filter: option_filter} = deps

      to_delete = %Variable{id: existing.id}
      result = Structure.delete_variable(to_delete, decision.id)

      assert {:ok, %Variable{}} = result
      assert nil == Repo.get(Variable, existing.id)
      assert nil !== Repo.get(Decision, decision.id)
      assert nil !== Repo.get(OptionFilter, option_filter.id)
    end

    test "deleting Variable with Calculation returns error" do
      deps = create_calculation_with_variables()
      %{detail_variable: variable, decision: decision} = deps

      to_delete = %Variable{id: variable.id}
      result = Structure.delete_variable(to_delete, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "cannot be deleted" in errors.id
      assert %Variable{} = Repo.get(Variable, variable.id)
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
