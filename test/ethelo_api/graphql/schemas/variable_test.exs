defmodule EtheloApi.Graphql.Schemas.VariableTest do
  @moduledoc """
  Test graphql queries for Variables
  """
  use EtheloApi.Graphql.SchemaCase
  @moduletag variable: true, graphql: true

  alias EtheloApi.Structure
  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.VariableHelper

  describe "decision => variables query" do
    test "without filter returns all records" do
      %{variable: to_match1, decision: decision} = create_detail_variable()
      %{variable: to_match2} = create_filter_variable(decision)
      %{variable: _excluded} = create_filter_variable()

      assert_list_many_query("variables", decision.id, %{}, [to_match1, to_match2], fields())
    end

    test "filters by id" do
      %{variable: to_match, decision: decision} = create_detail_variable()
      %{variable: _excluded} = create_filter_variable(decision)

      assert_list_one_query("variables", to_match, [:id], fields([:id]))
    end

    test "filters by slug" do
      %{variable: to_match, decision: decision} = create_detail_variable()
      %{variable: _excluded} = create_detail_variable(decision)
      assert_list_one_query("variables", to_match, [:slug], fields([:slug]))
    end

    test "filters by option_filter_id" do
      %{variable: to_match, decision: decision} = create_filter_variable()
      %{variable: _excluded} = create_filter_variable(decision)

      assert_list_one_query(
        "variables",
        to_match,
        [:option_filter_id],
        fields([:option_filter_id])
      )
    end

    test "filters by option_detail_id" do
      %{variable: to_match, decision: decision} = create_detail_variable()
      %{variable: _excluded} = create_detail_variable(decision)

      assert_list_one_query(
        "variables",
        to_match,
        [:option_detail_id],
        fields([:option_detail_id])
      )
    end

    test "no matching records" do
      decision = create_decision()
      assert_list_none_query("variables", %{decision_id: decision.id}, [:id])
    end

    test "inline OptionFilter" do
      decision = create_decision()
      %{variable: variable1, option_filter: option_filter} = create_filter_variable(decision)
      %{variable: variable2} = create_detail_variable(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            variables{
              id
              optionFilter{
                id
              }
            }
          }
        }
      """

      result_list = evaluate_query_graphql(query, "variables")

      assert [_, _] = result_list

      expected = [
        %{
          "id" => "#{variable1.id}",
          "optionFilter" => %{"id" => "#{option_filter.id}"}
        },
        %{
          "id" => "#{variable2.id}",
          "optionFilter" => nil
        }
      ]

      assert expected == result_list
    end

    test "inline OptionDetail" do
      decision = create_decision()

      %{variable: variable1, option_detail: option_detail} =
        create_detail_variable(decision)

      %{variable: variable2} = create_filter_variable(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            variables{
              id
              optionDetail{
                id
              }
            }
          }
        }
      """

      result_list = evaluate_query_graphql(query, "variables")

      assert [_, _] = result_list

      expected = [
        %{
          "id" => "#{variable1.id}",
          "optionDetail" => %{"id" => "#{option_detail.id}"}
        },
        %{
          "id" => "#{variable2.id}",
          "optionDetail" => nil
        }
      ]

      assert expected == result_list
    end

    test "inline Calculations" do
      decision = create_decision()

      %{
        filter_variable: variable1,
        detail_variable: variable2,
        calculation: calculation1
      } = create_calculation_with_variables(decision)

      %{variable: variable3} = create_filter_variable(decision)

      query = ~s|
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            variables{
              id
              calculationIds
              calculations{
                id
              }
            }
          }
        }
      |

      result_list = evaluate_query_graphql(query, "variables")
      assert [_, _, _] = result_list

      result_list = result_list |> Enum.sort_by(&Map.get(&1, "id"))

      expected = [
        %{
          "id" => "#{variable1.id}",
          "calculationIds" => ["#{calculation1.id}"],
          "calculations" => [%{"id" => "#{calculation1.id}"}]
        },
        %{
          "id" => "#{variable2.id}",
          "calculationIds" => ["#{calculation1.id}"],
          "calculations" => [%{"id" => "#{calculation1.id}"}]
        },
        %{
          "id" => "#{variable3.id}",
          "calculationIds" => nil,
          "calculations" => []
        }
      ]

      assert expected == result_list
    end
  end

  describe "createDetailVariable mutation" do
    test "creates with valid data" do
      %{decision: decision} = deps = detail_variable_deps()

      field_names = input_field_names() |> List.delete(:option_filter_id)
      attrs = deps |> valid_attrs() |> Map.take(field_names)
      requested_fields = Map.keys(attrs) ++ [:id]

      payload = run_mutate_one_query("createDetailVariable", decision.id, attrs, requested_fields)

      assert_mutation_success(attrs, payload, fields(field_names))
      refute nil == get_in(payload, ["result", "id"])
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = detail_variable_deps()

      invalid = Map.take(invalid_attrs(), [:title])
      field_names = input_field_names() |> List.delete(:option_filter_id)
      attrs = deps |> valid_attrs() |> Map.merge(invalid) |> Map.take(field_names)
      payload = run_mutate_one_query("createDetailVariable", decision.id, attrs)

      expected = [%ValidationMessage{code: :required, field: :title}]
      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid Decision returns error" do
      %{decision: decision} = deps = detail_variable_deps()
      delete_decision(decision)

      field_names = input_field_names() |> List.delete(:option_filter_id)
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("createDetailVariable", decision.id, attrs)
      expected = [%ValidationMessage{code: :not_found, field: "decisionId"}]
      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "updateDetailVariable mutation" do
    test "updates with valid data" do
      %{decision: decision} = deps = create_detail_variable()

      field_names =
        input_field_names() |> List.delete(:option_filter_id) |> List.insert_at(0, :id)

      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("updateDetailVariable", decision.id, attrs)

      assert_mutation_success(attrs, payload, fields(field_names))
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = create_detail_variable()

      invalid = Map.take(invalid_attrs(), [:title])
      field_names = [:title, :slug, :id]
      attrs = deps |> valid_attrs() |> Map.merge(invalid) |> Map.take(field_names)

      payload = run_mutate_one_query("updateDetailVariable", decision.id, attrs)

      expected = [%ValidationMessage{code: :required, field: :title}]
      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid Variable returns error" do
      %{variable: to_delete, decision: decision} = deps = create_detail_variable()
      delete_variable(to_delete)

      field_names = [:title, :slug, :id]
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("updateDetailVariable", decision.id, attrs)
      expected = [%ValidationMessage{code: "not_found", field: :id}]
      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "createFilterVariable mutation" do
    test "creates with valid data" do
      %{decision: decision} = deps = filter_variable_deps()
      field_names = input_field_names() |> List.delete(:option_detail_id)

      attrs = deps |> valid_attrs() |> Map.take(field_names)
      requested_fields = Map.keys(attrs) ++ [:id]

      payload =
        run_mutate_one_query("createFilterVariable", decision.id, attrs, requested_fields)

      assert_mutation_success(attrs, payload, fields(field_names))
      refute nil == get_in(payload, ["result", "id"])
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = filter_variable_deps()
      invalid = Map.take(invalid_attrs(), [:title])
      field_names = input_field_names() |> List.delete(:option_detail_id)
      attrs = deps |> valid_attrs() |> Map.merge(invalid) |> Map.take(field_names)

      payload =
        run_mutate_one_query("createFilterVariable", decision.id, attrs)

      expected = [%ValidationMessage{code: :required, field: :title}]
      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid Decision returns error" do
      %{decision: decision} = deps = filter_variable_deps()
      delete_decision(decision)

      field_names = input_field_names() |> List.delete(:option_detail_id)
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload =
        run_mutate_one_query("createFilterVariable", decision.id, attrs)

      expected = [%ValidationMessage{code: :not_found, field: "decisionId"}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "updateFilterVariable mutation" do
    test "updates with valid data" do
      %{decision: decision} = deps = create_filter_variable()

      field_names =
        input_field_names() |> List.delete(:option_detail_id) |> List.insert_at(0, :id)

      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("updateFilterVariable", decision.id, attrs)

      assert_mutation_success(attrs, payload, fields())
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = create_filter_variable()
      invalid = Map.take(invalid_attrs(), [:title])

      field_names = [:title, :slug, :id]
      attrs = deps |> valid_attrs() |> Map.merge(invalid) |> Map.take(field_names)
      payload = run_mutate_one_query("updateFilterVariable", decision.id, attrs)

      expected = [%ValidationMessage{code: :required, field: :title}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid Variable returns error" do
      %{decision: decision, variable: to_update} = deps = create_filter_variable()
      delete_variable(to_update)

      field_names = [:id, :title]
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("updateFilterVariable", decision.id, attrs)

      expected = [%ValidationMessage{code: "not_found", field: :id}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "deleteVariable mutation" do
    test "deletes" do
      %{decision: decision, variable: to_delete} = create_detail_variable()

      attrs = to_delete |> Map.take([:id])
      payload = run_mutate_one_query("deleteVariable", decision.id, attrs)

      assert_mutation_success(%{}, payload, %{})
      assert nil == Structure.get_variable(to_delete.id, decision)
    end
  end
end
