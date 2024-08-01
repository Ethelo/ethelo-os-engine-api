defmodule EtheloApi.Graphql.Schemas.ConstraintTest do
  @moduledoc """
  Test graphql queries for Constraints
  """
  use EtheloApi.Graphql.SchemaCase
  @moduletag constraint: true, graphql: true

  alias EtheloApi.Structure
  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.ConstraintHelper

  describe "decision => constraints query" do
    test "without filter returns all records" do
      %{constraint: to_match1, decision: decision} = create_variable_constraint()
      %{constraint: to_match2} = create_calculation_constraint(decision, %{operator: :between})
      %{constraint: _excluded} = create_variable_constraint()

      assert_list_many_query("constraints", decision.id, %{}, [to_match1, to_match2], fields())
    end

    test "filters by id" do
      %{constraint: to_match, decision: decision} = create_variable_constraint()
      %{constraint: _excluded} = create_variable_constraint(decision)

      assert_list_one_query("constraints", to_match, [:id], fields([:id]))
    end

    test "filters by slug" do
      %{constraint: to_match, decision: decision} = create_variable_constraint()
      %{constraint: _excluded} = create_variable_constraint(decision)
      assert_list_one_query("constraints", to_match, [:slug], fields([:slug]))
    end

    test "filters by option_filter_id" do
      %{constraint: to_match, decision: decision} = create_calculation_constraint()
      %{constraint: _excluded} = create_calculation_constraint(decision)

      assert_list_one_query(
        "constraints",
        to_match,
        [:option_filter_id],
        fields([:option_filter_id])
      )
    end

    test "filters by variable_id" do
      %{constraint: to_match, decision: decision} = create_variable_constraint()
      %{constraint: _excluded} = create_variable_constraint(decision)

      assert_list_one_query(
        "constraints",
        to_match,
        [:variable_id],
        fields([:variable_id])
      )
    end

    test "filters by calculation_id" do
      %{constraint: to_match, decision: decision} = create_calculation_constraint()
      %{constraint: _excluded} = create_calculation_constraint(decision)

      assert_list_one_query(
        "constraints",
        to_match,
        [:calculation_id],
        fields([:calculation_id])
      )
    end

    test "no matching records" do
      decision = create_decision()
      assert_list_none_query("constraints", %{decision_id: decision.id}, [:id])
    end

    test "inline OptionFilter" do
      decision = create_decision()

      %{constraint: constraint1, option_filter: option_filter1} =
        create_calculation_constraint(decision)

      %{constraint: constraint2, option_filter: option_filter2} =
        create_variable_constraint(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            constraints{
              id
              optionFilter{
                id
              }
            }
          }
        }
      """

      result_list = evaluate_query_graphql(query, "constraints")

      assert [_, _] = result_list
      result_list = result_list |> Enum.sort_by(&Map.get(&1, "id"))

      expected = [
        %{
          "id" => "#{constraint1.id}",
          "optionFilter" => %{"id" => "#{option_filter1.id}"}
        },
        %{
          "id" => "#{constraint2.id}",
          "optionFilter" => %{"id" => "#{option_filter2.id}"}
        }
      ]

      assert expected == result_list
    end

    test "inline Variables" do
      decision = create_decision()
      %{constraint: constraint1, variable: variable} = create_variable_constraint(decision)
      %{constraint: constraint2} = create_calculation_constraint(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            constraints{
              id
              variable{
                id
              }
            }
          }
        }
      """

      result_list = evaluate_query_graphql(query, "constraints")
      result_list = result_list |> Enum.sort_by(&Map.get(&1, "id"))

      assert [_, _] = result_list

      expected = [
        %{
          "id" => "#{constraint1.id}",
          "variable" => %{"id" => "#{variable.id}"}
        },
        %{
          "id" => "#{constraint2.id}",
          "variable" => nil
        }
      ]

      assert expected == result_list
    end

    test "inline Calculation" do
      decision = create_decision()

      %{constraint: constraint1, calculation: calculation} =
        create_calculation_constraint(decision)

      %{constraint: constraint2} = create_variable_constraint(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            constraints{
              id
              calculation{
                id
              }
            }
          }
        }
      """

      result_list = evaluate_query_graphql(query, "constraints")
      result_list = result_list |> Enum.sort_by(&Map.get(&1, "id"))

      assert [_, _] = result_list

      expected = [
        %{
          "id" => "#{constraint1.id}",
          "calculation" => %{"id" => "#{calculation.id}"}
        },
        %{
          "id" => "#{constraint2.id}",
          "calculation" => nil
        }
      ]

      assert expected == result_list
    end
  end

  describe "createConstraint mutation" do
    test "creates with valid data" do
      %{decision: decision} = deps = variable_constraint_deps()

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names)
      requested_fields = Map.keys(attrs) ++ [:id]

      payload = run_mutate_one_query("createConstraint", decision.id, attrs, requested_fields)

      assert_mutation_success(attrs, payload, fields(field_names))
      refute nil == get_in(payload, ["result", "id"])
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = variable_constraint_deps()

      invalid = Map.take(invalid_attrs(), [:title])

      field_names = input_field_names()

      attrs = deps |> valid_attrs() |> Map.merge(invalid) |> Map.take(field_names)

      payload = run_mutate_one_query("createConstraint", decision.id, attrs)

      expected = [%ValidationMessage{code: :required, field: :title}]
      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid Decision returns error" do
      %{decision: decision} = deps = variable_constraint_deps()

      delete_decision(decision)

      field_names = input_field_names() |> List.delete(:option_filter_id)
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("createConstraint", decision.id, attrs)
      expected = [%ValidationMessage{code: :not_found, field: "decisionId"}]
      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "updateConstraint mutation" do
    test "updates with valid data" do
      %{decision: decision} = deps = create_calculation_constraint()

      field_names = input_field_names() ++ [:id]

      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("updateConstraint", decision.id, attrs)

      assert_mutation_success(attrs, payload, fields(field_names))
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = create_calculation_constraint()

      invalid = Map.take(invalid_attrs(), [:title])
      field_names = [:id, :title, :operator, :rhs, :lhs]

      attrs = deps |> valid_attrs() |> Map.merge(invalid) |> Map.take(field_names)

      payload = run_mutate_one_query("updateConstraint", decision.id, attrs)

      expected = [%ValidationMessage{code: :required, field: :title}]
      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid Constraint returns error" do
      %{constraint: to_delete, decision: decision} = deps = create_calculation_constraint()

      delete_constraint(to_delete)

      field_names = [:id, :operator, :rhs, :lhs]

      attrs = deps |> valid_between_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("updateConstraint", decision.id, attrs)
      expected = [%ValidationMessage{code: "not_found", field: :id}]
      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "deleteConstraint mutation" do
    test "deletes" do
      %{decision: decision, constraint: to_delete} = create_variable_constraint()

      attrs = to_delete |> Map.take([:id])
      payload = run_mutate_one_query("deleteConstraint", decision.id, attrs)

      assert_mutation_success(%{}, payload, %{})
      assert nil == Structure.get_constraint(to_delete.id, decision)
    end
  end
end
