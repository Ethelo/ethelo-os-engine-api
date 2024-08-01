defmodule EtheloApi.Graphql.Resolvers.CalculationTest do
  @moduledoc """
  Validations and basic access for Calculation resolver
  through graphql.
  Note: Functionality is provided through the CalculationResolver.Calculation context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Structure.CalculationTest`
  """
  use EtheloApi.DataCase
  @moduletag calculation: true, graphql: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.CalculationHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Calculation
  alias EtheloApi.Graphql.Resolvers.Calculation, as: CalculationResolver

  def test_list_filtering(field_name) do
    %{calculation: to_match, decision: decision} = create_calculation()
    %{calculation: _excluded} = create_calculation(decision)

    parent = %{decision: decision}
    args = %{} |> Map.put(field_name, Map.get(to_match, field_name))
    result = CalculationResolver.list(parent, args, nil)

    assert {:ok, result} = result
    assert [%Calculation{}] = result
    assert_result_ids_match([to_match], result)
  end

  describe "list/2" do
    test "filters by decision_id" do
      %{calculation: to_match1, decision: decision} = create_calculation()
      %{calculation: to_match2} = create_calculation(decision)
      %{calculation: _excluded} = create_calculation()

      parent = %{decision: decision}
      args = %{}
      result = CalculationResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Calculation{}, %Calculation{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "filters by id" do
      test_list_filtering(:id)
    end

    test "filters by slug" do
      test_list_filtering(:slug)
    end

    test "no matching records" do
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
      %{decision: decision} = deps = calculation_deps()

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = CalculationResolver.create(params, nil)
      assert {:ok, %Calculation{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "invalid data returns changeset" do
      %{decision: decision} = deps = calculation_deps()

      attrs = invalid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)
      result = CalculationResolver.create(params, nil)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> error_map()

      expected = [
        :expression,
        :public,
        :slug,
        :sort,
        :title
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "update/2" do
    test "updates with valid data" do
      %{decision: decision} = deps = create_calculation()

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = CalculationResolver.update(params, nil)
      assert {:ok, %Calculation{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "invalid Calculation returns error" do
      %{decision: decision, calculation: to_delete} = deps = create_calculation()
      delete_calculation(to_delete.id)

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = CalculationResolver.update(params, nil)
      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "Decision mismatch returns changeset" do
      deps = create_calculation()
      decision = create_decision()
      deps = Map.put(deps, :decision, decision)

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = CalculationResolver.update(params, nil)
      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "invalid data returns changeset" do
      %{decision: decision} = deps = create_calculation()

      attrs = invalid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)
      result = CalculationResolver.update(params, nil)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> error_map()

      expected =
        [
          :expression,
          :public,
          :slug,
          :sort,
          :title
        ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "delete/2" do
    test "deletes" do
      %{decision: decision, calculation: to_delete} = create_calculation()

      attrs = %{decision_id: decision.id, id: to_delete.id}
      params = to_graphql_input_params(attrs, decision)
      result = CalculationResolver.delete(params, nil)

      assert {:ok, %Calculation{}} = result
      assert nil == Structure.get_calculation(to_delete.id, decision)
    end

    test "when record does not exist return successful nil" do
      %{decision: decision, calculation: to_delete} = create_calculation()
      delete_calculation(to_delete.id)

      attrs = %{decision_id: decision.id, id: to_delete.id}
      params = to_graphql_input_params(attrs, decision)
      result = CalculationResolver.delete(params, nil)

      assert {:ok, nil} = result
    end
  end
end
