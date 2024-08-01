defmodule EtheloApi.Graphql.Schemas.CalculationTest do
  @moduledoc """
  Test graphql queries for Calculations
  """
  use EtheloApi.Graphql.SchemaCase
  @moduletag calculation: true, graphql: true

  alias EtheloApi.Structure
  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.CalculationHelper

  describe "decision => calculations query" do
    test "without filter returns all records" do
      %{calculation: to_match1, decision: decision} = create_calculation()
      %{calculation: to_match2} = create_calculation(decision)

      assert_list_many_query("calculations", decision.id, %{}, [to_match1, to_match2], fields())
    end

    test "filters by id" do
      %{calculation: to_match, decision: decision} = create_calculation()
      %{calculation: _excluded} = create_calculation(decision)

      assert_list_one_query("calculations", to_match, [:id], fields([:id]))
    end

    test "filters by slug" do
      %{calculation: to_match, decision: decision} = create_calculation()
      %{calculation: _excluded} = create_calculation(decision)
      assert_list_one_query("calculations", to_match, [:slug], fields([:slug]))
    end

    test "no matching records" do
      decision = create_decision()
      assert_list_none_query("calculations", %{decision_id: decision.id}, [:id])
    end

    test "inline Variables" do
      %{
        filter_variable: variable1,
        detail_variable: variable2,
        calculation: calculation,
        decision: decision
      } = create_calculation_with_variables()

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            calculations{
            id
              variables{
                id
              }
            }
          }
        }
      """

      result_list = evaluate_query_graphql(query, "calculations")

      expected = [
        %{
          "id" => "#{calculation.id}",
          "variables" => [
            %{"id" => "#{variable1.id}"},
            %{"id" => "#{variable2.id}"}
          ]
        }
      ]

      assert expected == result_list
    end
  end

  describe "createCalculation mutation" do
    test "creates with valid data" do
      %{decision: decision} = deps = calculation_with_variables_deps()

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names)
      requested_fields = Map.keys(attrs) ++ [:id]

      payload = run_mutate_one_query("createCalculation", decision.id, attrs, requested_fields)

      assert_mutation_success(attrs, payload, fields(field_names))
      refute nil == get_in(payload, ["result", "id"])
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = calculation_deps()
      invalid = Map.take(invalid_attrs(), [:title])

      field_names = [:slug, :title, :expression]

      attrs = deps |> valid_attrs() |> Map.merge(invalid) |> Map.take(field_names)

      payload = run_mutate_one_query("createCalculation", decision.id, attrs)

      expected = [%ValidationMessage{code: :required, field: :title}]
      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid Decision returns error" do
      %{decision: decision} = deps = option_category_deps()
      delete_decision(decision)

      field_names = [:title, :expression]
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("createCalculation", decision.id, attrs)

      expected = [%ValidationMessage{code: :not_found, field: "decisionId"}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "updateCalculation mutation" do
    test "updates with valid data" do
      %{decision: decision} = deps = create_calculation()
      %{variable: variable} = create_detail_variable(decision)

      field_names = input_field_names() ++ [:id]
      attrs = deps |> Map.put(:variable, variable) |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("updateCalculation", decision.id, attrs)

      assert_mutation_success(attrs, payload, fields(field_names))
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = create_calculation()
      invalid = Map.take(invalid_attrs(), [:title])

      field_names = [:title, :expression, :id]

      attrs = deps |> valid_attrs() |> Map.merge(invalid) |> Map.take(field_names)

      payload = run_mutate_one_query("updateCalculation", decision.id, attrs)

      expected = [%ValidationMessage{code: :required, field: :title}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid Calculation returns error" do
      %{calculation: calculation, decision: decision} = deps = create_calculation()
      delete_calculation(calculation)

      field_names = [:id, :title]
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("updateCalculation", decision.id, attrs)

      expected = [%ValidationMessage{code: "not_found", field: :id}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "deleteCalculation mutation" do
    test "deletes" do
      %{decision: decision, calculation: to_delete} = create_calculation()

      attrs = to_delete |> Map.take([:id])
      payload = run_mutate_one_query("deleteCalculation", decision.id, attrs)

      assert_mutation_success(%{}, payload, %{})
      assert nil == Structure.get_calculation(to_delete.id, decision)
    end
  end
end
