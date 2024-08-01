defmodule GraphQL.EtheloApi.AdminSchema.ConstraintTest do
  @moduledoc """
  Test graphql queries for decisions
  """
  use GraphQL.EtheloApi.AdminSchemaCase
  @moduletag constraint: true, graphql: true

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Constraint
  alias Kronky.ValidationMessage
  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.ConstraintHelper

  def fields() do
    %{
      title: :string, slug: :string, relaxable: :boolean,
      operator: :enum, value: :float, between_high: :float, between_low: :float,
      updated_at: :date, inserted_at: :date
  }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  describe "decision => constraints query " do
    test "no filter" do
      %{constraint: first, decision: decision} = create_variable_constraint()
      %{constraint: second} = create_calculation_constraint(decision, %{operator: :between})

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            constraints{
              id
              title
              slug
              relaxable
              operator
              value
              betweenHigh
              betweenLow
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "constraints"])
      assert [_, _] = result
      [first_result, second_result] = result |> Enum.sort_by(&(Map.get(&1, "id")))

      fields = [:title, :slug, :operator, :relaxable, :rhs, :lhs]
      first = first |> Map.take(fields) |> to_graphql_attrs()
      assert_equivalent_graphql(first, first_result, fields())

      second = second |> Map.take(fields) |> to_graphql_attrs()
      assert_equivalent_graphql(second, second_result, fields())
    end

    test "filter by id" do
      %{constraint: matching, decision: decision} = create_variable_constraint()
      %{constraint: _not_matching} = create_variable_constraint(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            constraints(
              id: #{matching.id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "constraints"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "filter by slug" do
      %{constraint: matching, decision: decision} = create_variable_constraint()
      %{constraint: _not_matching} = create_variable_constraint(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            constraints(
              slug: "#{matching.slug}"
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "constraints"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "filter by OptionFilterId" do
      %{constraint: matching, decision: decision} = create_calculation_constraint()
      %{constraint: _not_matching} = create_calculation_constraint(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            constraints(
              optionFilterId: #{matching.option_filter_id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "constraints"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "filter by variableId" do
      %{constraint: matching, decision: decision} = create_variable_constraint()
      %{constraint: _not_matching} = create_variable_constraint(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            constraints(
              variableId: #{matching.variable_id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "constraints"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "filter by calculationId" do
      %{constraint: matching, decision: decision} = create_calculation_constraint()
      %{constraint: _not_matching} = create_calculation_constraint(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            constraints(
              calculationId: #{matching.calculation_id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "constraints"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "no records" do
      decision = create_decision()

      query = """
        {
          decision(
            decisionId: "#{decision.id}"
          )
          {
            constraints{
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "constraints"])
      assert [] = result
    end

    test "inline OptionFilter" do
      %{option_filter: first, decision: decision} = create_calculation_constraint()
      %{option_filter: second} = create_calculation_constraint(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            constraints{
              optionFilter{
                id
              }
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "constraints"])
      assert [_, _] = result
      [first_result, second_result] = result |> Enum.sort_by(&(Map.get(&1, "id")))

      expected_ids = [to_string(first.id), to_string(second.id)]

      first_id = get_in(first_result, ["optionFilter", "id"])
      second_id = get_in(second_result, ["optionFilter", "id"])
      assert first_id in expected_ids
      assert second_id in expected_ids
    end

    test "inline Constraint" do
      %{variable: first, decision: decision} = create_variable_constraint()
      %{variable: second} = create_variable_constraint(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            constraints{
              variable{
                id
              }
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "constraints"])
      assert [first_result, second_result] = result

      expected_ids = [to_string(first.id), to_string(second.id)]

      first_id = get_in(first_result, ["variable", "id"])
      second_id = get_in(second_result, ["variable", "id"])
      assert first_id in expected_ids
      assert second_id in expected_ids
    end

    test "inline Calculation" do
      %{calculation: first, decision: decision} = create_calculation_constraint()
      %{calculation: second} = create_calculation_constraint(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            constraints{
              calculation{
                id
              }
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "constraints"])
      assert [first_result, second_result] = result

      expected_ids = [to_string(first.id), to_string(second.id)]

      first_id = get_in(first_result, ["calculation", "id"])
      second_id = get_in(second_result, ["calculation", "id"])
      assert first_id in expected_ids
      assert second_id in expected_ids
    end

  end

  describe "createSingleBoundaryConstraint mutation with Constraint" do

    test "success" do
      %{variable: variable, option_filter: option_filter, decision: decision} = variable_constraint_deps()
      input = %{
        decision_id: decision.id,
        slug: "foo",
        title: "foo bar",
        operator: "GREATER_THAN_OR_EQUAL_TO",
        value: 10.9,
        option_filter_id: option_filter.id,
        variable_id: variable.id,
        relaxable: true,
      }

      query =
        """
        mutation{
          createSingleBoundaryConstraint(
            input: {
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
              operator: #{input.operator}
              value: #{input.value}
              optionFilterId: #{input.option_filter_id}
              variableId: #{input.variable_id}
              relaxable: #{input.relaxable}
            }
          ){
            successful
            result {
              id
              title
              slug
              relaxable
              operator
              value
            }
          }
        }
        """

      assert {:ok, %{data: data}} = evaluate_graphql(query)
      assert %{"createSingleBoundaryConstraint" => payload} = data
      assert_mutation_success(input, payload, fields([:title, :slug, :value, :operator]))
      assert %Constraint{} = Structure.get_constraint(payload["result"]["id"], decision)
    end

    test "failure" do
      %{decision: decision, variable: variable, option_filter: option_filter} = variable_constraint_deps()
      input = %{
        title: "-", slug: "A",
        decision_id: decision.id,
        variable_id: variable.id,
        option_filter_id: option_filter.id,
        value: 49.0,
        operator: "EQUAL_TO",
        relaxable: true,
      }

      query = """
        mutation{
          createSingleBoundaryConstraint(
            input: {
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
              operator: #{input.operator}
              value: #{input.value},
              optionFilterId: #{input.option_filter_id}
              variableId: #{input.variable_id}
              relaxable: #{input.relaxable}
            }
          ){
            successful
            messages {
              field
              message
              code
            }
            result {
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"createSingleBoundaryConstraint" => payload} = data
      expected = [
        %ValidationMessage{code: :format, field: :title, message: "must include at least one word"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end

    test "decision not found" do
      %{decision: decision, option_filter: option_filter, variable: variable} = variable_constraint_deps()
      input = %{
        title: "-", slug: "A",
        decision_id: decision.id,
        variable_id: variable.id,
        option_filter_id: option_filter.id,
        value: 49.0,
        operator: "EQUAL_TO",
        relaxable: false,
      }
      delete_decision(decision)

      query = """
        mutation{
          createSingleBoundaryConstraint(
            input: {
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              operator: #{input.operator}
              value: #{input.value},
              optionFilterId: #{input.option_filter_id}
              variableId: #{input.variable_id}
              relaxable: #{input.relaxable}
            }
          ){
            successful
            messages {
              field
              message
              code
            }
            result {
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"createSingleBoundaryConstraint" => payload} = data
      expected = [
        %ValidationMessage{code: :not_found, field: :decisionId, message: "does not exist"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end
  end

  describe "updateSingleBoundaryConstraint mutation with variable" do

    test "success" do
      deps = create_variable_constraint()
      %{constraint: constraint, decision: decision} = deps
      %{variable: variable, option_filter: option_filter} = variable_constraint_deps(decision)
      input = %{
        id: constraint.id,
        decision_id: decision.id,
        slug: "foo",
        title: "foo bar",
        operator: "GREATER_THAN_OR_EQUAL_TO",
        value: 10.9,
        option_filter_id: option_filter.id,
        variable_id: variable.id,
        relaxable: false
      }

      query = """
        mutation{
          updateSingleBoundaryConstraint(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              slug: "#{input.slug}"
              title: "#{input.title}"
              operator: #{input.operator}
              value: #{input.value},
              optionFilterId: #{input.option_filter_id}
              variableId: #{input.variable_id}
              relaxable: #{input.relaxable}
            }
          )
          {
            successful
            result {
              id
              title
              slug
              relaxable
              operator
              value
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"updateSingleBoundaryConstraint" => payload} = data
      assert_mutation_success(input, payload, fields())
      assert %Constraint{} = Structure.get_constraint(payload["result"]["id"], decision)
    end

    test "failure" do
      deps = create_variable_constraint()
      %{constraint: constraint, decision: decision} = deps
      %{option_filter: option_filter, variable: variable} = deps

      input = %{
        title: "-", slug: "A",
        id: constraint.id,
        decision_id: decision.id,
        variable_id: variable.id,
        option_filter_id: option_filter.id,
        value: 49.0,
        operator: "EQUAL_TO",
        relaxable: true,
      }

      query = """
        mutation{
          updateSingleBoundaryConstraint(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              operator: #{input.operator}
              value: #{input.value},
              optionFilterId: #{input.option_filter_id}
              variableId: #{input.variable_id}
              relaxable: #{input.relaxable}
            }
          ){
            successful
            messages {
              field
              message
              code
            }
            result {
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"updateSingleBoundaryConstraint" => payload} = data
      expected = %ValidationMessage{
        code: :format, field: :title, message: "must include at least one word"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end

    test "Constraint not found" do
      deps = create_variable_constraint()
      %{constraint: constraint} = deps
      %{option_filter: option_filter, variable: variable} = deps
      decision = create_decision()

      input = %{
        title: "-", slug: "A",
        decision_id: decision.id,
        variable_id: variable.id,
        option_filter_id: option_filter.id,
        value: 49.0,
        operator: "EQUAL_TO",
        id: constraint.id,
        relaxable: false,
      }

      query = """
        mutation{
          updateSingleBoundaryConstraint(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              operator: #{input.operator}
              value: #{input.value},
              optionFilterId: #{input.option_filter_id}
              variableId: #{input.variable_id}
              relaxable: #{input.relaxable}
            }
          ){
            successful
            messages {
              field
              message
              code
            }
            result {
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"updateSingleBoundaryConstraint" => payload} = data
      expected = %ValidationMessage{
        code: "not_found", field: :id, message: "does not exist"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end
  end

  describe "deleteConstraint mutation" do
    test "success" do
      %{decision: decision, constraint: constraint} = create_variable_constraint()
      input = %{id: constraint.id, decision_id: decision.id}

      query = """
        mutation{
          deleteConstraint(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
            }
          ){
            successful
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"deleteConstraint" => %{"successful" => true}} = data
      assert nil == Structure.get_constraint(constraint.id, decision)
    end
  end
end
