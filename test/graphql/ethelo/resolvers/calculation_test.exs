defmodule GraphQL.EtheloApi.Resolvers.CalculationTest do
  @moduledoc """
  Validations and basic access for "Calculation" resolver, used to load calculation records
  through graphql.
  Note: Functionality is provided through the CalculationResolver.Calculation context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Structure.CalculationTest`
  """
  use EtheloApi.DataCase
  @moduletag calculation: true, graphql: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.CalculationHelper

  alias Kronky.ValidationMessage
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Calculation
  alias GraphQL.EtheloApi.Resolvers.Calculation, as: CalculationResolver

  describe "list/2" do

    test "returns records matching a Decision" do
      %{calculation: first, decision: decision} = create_calculation()
      %{calculation: second} = create_calculation(decision)

      parent = %{decision: decision}
      args = %{}
      result = CalculationResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Calculation{}, %Calculation{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "filters by Calculation.id" do
      %{calculation: matching, decision: decision} = create_calculation()
      create_calculation(decision)

      parent = %{decision: decision}
      args = %{id: matching.id}
      result = CalculationResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Calculation{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by Calculation.slug" do
      %{calculation: matching, decision: decision} = create_calculation()
      create_calculation(decision)

      parent = %{decision: decision}
      args = %{slug: matching.slug}
      result = CalculationResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Calculation{}] = result
      assert_result_ids_match([matching], result)
    end

    test "no Calculation matches" do
      decision = create_decision()

      parent = %{decision: decision}
      args = %{}
      result = CalculationResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [] = result
    end
  end

  describe "create/2" do
    test "creates with valid data" do
      deps = calculation_deps()
      %{decision: decision} = deps

      attrs = deps |> valid_attrs() |> to_graphql_attrs()
      result = CalculationResolver.create(decision, attrs)

      assert {:ok, %Calculation{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "returns a changeset with invalid data" do
      deps = calculation_deps()
      %{decision: decision} = deps

      attrs = invalid_attrs(deps)
      result = CalculationResolver.create(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = changeset |> errors_on() |> Map.keys()
      assert :title in errors
      assert :slug in errors
      assert :expression in errors
      assert :public in errors
      refute :display_hint in errors
      assert [_, _, _, _, _] = errors
    end
  end

  describe "update/2" do

    test "updates with valid data" do
      deps = create_calculation()
      %{decision: decision} = deps

      attrs = valid_attrs(deps)
      result = CalculationResolver.update(decision, attrs)

      assert {:ok, %Calculation{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "returns errors when Calculation does not exist" do
      deps = create_calculation()
      %{calculation: calculation, decision: decision} = deps
      delete_calculation(calculation.id)

      attrs = valid_attrs(deps)
      result = CalculationResolver.update(decision, attrs)

      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "returns errors when Decision does not match" do
      deps = create_calculation()
      decision = create_decision()

      attrs = valid_attrs(deps)
      result = CalculationResolver.update(decision, attrs)

      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "returns a changeset with invalid data" do
      deps = create_calculation()
      %{decision: decision} = deps

      attrs = invalid_attrs(deps)
      result = CalculationResolver.update(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = changeset |> errors_on() |> Map.keys()
      assert :title in errors
      assert :slug in errors
      assert :sort in errors
      assert :expression in errors
      assert :public in errors
      refute :display_hint in errors
      assert [_, _, _, _, _] = errors
    end
  end

  describe "delete/2" do
    test "deletes" do
      deps = create_calculation()
      %{calculation: calculation, decision: decision} = deps

      attrs = %{decision_id: decision.id, id: calculation.id}
      result = CalculationResolver.delete(decision, attrs)

      assert {:ok, %Calculation{}} = result
      assert nil == Structure.get_calculation(calculation.id, decision)
    end

    test "delete/2 does not return errors when Calculation does not exist" do
      %{calculation: calculation, decision: decision} = create_calculation()
      delete_calculation(calculation.id)

      attrs = %{decision_id: decision.id, id: calculation.id}
      result = CalculationResolver.delete(decision, attrs)

      assert {:ok, nil} = result
    end
  end
end
