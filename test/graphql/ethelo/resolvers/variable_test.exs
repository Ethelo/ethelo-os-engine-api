defmodule GraphQL.EtheloApi.Resolvers.VariableTest do
  @moduledoc """
  Validations and basic access for "Variable" resolver, used to load variable records
  through graphql.
  Note: Functionality is provided through the VariableResolver.Variable context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Structure.VariableTest`
  """
  use EtheloApi.DataCase
  @moduletag variable: true, graphql: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.VariableHelper

  alias Kronky.ValidationMessage
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Variable
  alias GraphQL.EtheloApi.Resolvers.Variable, as: VariableResolver

  describe "list/2" do

    test "returns records matching a Decision" do
      %{variable: first, decision: decision} = create_detail_variable()
      %{variable: second} = create_detail_variable(decision)

      parent = %{decision: decision}
      args = %{}
      result = VariableResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Variable{}, %Variable{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "filters by Variable.id" do
      %{variable: matching, decision: decision} = create_detail_variable()
      create_detail_variable(decision)

      parent = %{decision: decision}
      args = %{id: matching.id}
      result = VariableResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Variable{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by Variable.slug" do
      %{variable: matching, decision: decision} = create_detail_variable()
      create_detail_variable(decision)

      parent = %{decision: decision}
      args = %{slug: matching.slug}
      result = VariableResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Variable{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by Variable.option_detail_id" do
      %{variable: matching, decision: decision} = create_detail_variable()
      create_detail_variable(decision)

      parent = %{decision: decision}
      args = %{option_detail_id: matching.option_detail_id}
      result = VariableResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Variable{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by Variable.option_filter_id" do
      %{variable: matching, decision: decision} = create_filter_variable()
      create_filter_variable(decision)

      parent = %{decision: decision}
      args = %{option_filter_id: matching.option_filter_id}
      result = VariableResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Variable{}] = result
      assert_result_ids_match([matching], result)
    end

    test "no Variable matches" do
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
      deps = detail_variable_deps()
      %{decision: decision} = deps

      attrs = valid_attrs(deps)
      result = VariableResolver.create(decision, attrs)

      assert {:ok, %Variable{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "returns a changeset with invalid data" do
      deps = detail_variable_deps()
      %{option_detail: option_detail, decision: decision} = deps
      delete_option_detail(option_detail.id)

      attrs = invalid_attrs(deps)

      result = VariableResolver.create(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = changeset |> errors_on() |> Map.keys()
      assert :title in errors
      assert :slug in errors
      assert :method in errors
      assert :option_detail_id in errors
      refute :option_filter_id in errors
      assert [_, _, _, _] = errors
    end
  end

  describe "update/2" do

    test "updates with valid data" do
      deps = create_detail_variable()
      %{decision: decision} = deps

      attrs = valid_attrs(deps)
      result = VariableResolver.update(decision, attrs)

      assert {:ok, %Variable{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "returns errors when Variable does not exist" do
      deps = create_detail_variable()
      %{variable: variable, decision: decision} = deps
      delete_variable(variable.id)

      attrs = valid_attrs(deps)
      result = VariableResolver.update(decision, attrs)

      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "returns errors when Decision does not match" do
      deps = create_detail_variable()
      decision = create_decision()

      attrs = valid_attrs(deps)
      result = VariableResolver.update(decision, attrs)

      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "returns a changeset with invalid data" do
      deps = create_filter_variable()
      %{decision: decision} = deps

      attrs = invalid_attrs(deps)
      result = VariableResolver.update(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = changeset |> errors_on() |> Map.keys()
      assert :title in errors
      assert :slug in errors
      assert :method in errors
      refute :option_filter_id in errors
      refute :option_detail_id in errors
      assert [_, _, _] = errors
    end
  end

  describe "delete/2" do
    test "deletes" do
      deps = create_detail_variable()
      %{variable: variable, decision: decision} = deps

      attrs = %{decision_id: decision.id, id: variable.id}
      result = VariableResolver.delete(decision, attrs)

      assert {:ok, %Variable{}} = result
      assert nil == Structure.get_variable(variable.id, decision)
    end

    test "delete/2 does not return errors when Variable does not exist" do
      %{variable: variable, decision: decision} = create_detail_variable()
      delete_variable(variable.id)

      attrs = %{decision_id: decision.id, id: variable.id}
      result = VariableResolver.delete(decision, attrs)

      assert {:ok, nil} = result
    end
  end
end
