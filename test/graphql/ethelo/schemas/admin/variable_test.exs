defmodule GraphQL.EtheloApi.AdminSchema.VariableTest do
  @moduledoc """
  Test graphql queries for decisions
  """
  use GraphQL.EtheloApi.AdminSchemaCase
  @moduletag variable: true, graphql: true

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Variable
  alias Kronky.ValidationMessage
  import EtheloApi.Structure.Factory

  def fields() do
    %{
      id: :string, title: :string, slug: :string,
      method: :enum,
      updated_at: :date, inserted_at: :date,
  }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  describe "decision => variables query " do
    test "no filter" do
      %{variable: first, decision: decision} = create_detail_variable()
      %{variable: second} = create_filter_variable(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            variables{
              id
              title
              slug
              method
              updatedAt
              insertedAt
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "variables"])
      assert [_, _] = result
      [first_result, second_result] = result |> Enum.sort_by(&(Map.get(&1, "id")))

      assert_equivalent_graphql(first, first_result, fields())
      assert_equivalent_graphql(second, second_result, fields())
    end

    test "filter by id" do
      %{variable: matching, decision: decision} = create_detail_variable()
      %{variable: _not_matching} = create_detail_variable(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            variables(
              id: #{matching.id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "variables"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "filter by slug" do
      %{variable: matching, decision: decision} = create_detail_variable()
      %{variable: _not_matching} = create_detail_variable(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            variables(
              slug: "#{matching.slug}"
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "variables"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "filter by OptionFilterId" do
      %{variable: matching, decision: decision} = create_filter_variable()
      %{variable: _not_matching} = create_filter_variable(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            variables(
              optionFilterId: #{matching.option_filter_id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "variables"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "filter by OptionDetailId" do
      %{variable: matching, decision: decision} = create_detail_variable()
      %{variable: _not_matching} = create_detail_variable(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            variables(
              optionDetailId: #{matching.option_detail_id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "variables"])
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
            variables{
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "variables"])
      assert [] = result
    end

    test "inline OptionFilter" do
      %{option_filter: first, decision: decision} = create_filter_variable()
      %{option_filter: second} = create_filter_variable(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            variables{
              optionFilter{
                id
              }
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "variables"])
      assert [first_result, second_result] = result

      expected_ids = [to_string(first.id), to_string(second.id)]

      first_id = get_in(first_result, ["optionFilter", "id"])
      second_id = get_in(second_result, ["optionFilter", "id"])
      assert first_id in expected_ids
      assert second_id in expected_ids
    end

    test "inline OptionDetail" do
      %{option_detail: first, decision: decision} = create_detail_variable()
      %{option_detail: second} = create_detail_variable(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            variables{
              optionDetail{
                id
              }
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "variables"])
      assert [first_result, second_result] = result

      expected_ids = [to_string(first.id), to_string(second.id)]

      first_id = get_in(first_result, ["optionDetail", "id"])
      second_id = get_in(second_result, ["optionDetail", "id"])
      assert first_id in expected_ids
      assert second_id in expected_ids
    end

    test "inline Calculations" do
      %{decision: decision, calculation: calculation} = create_calculation_with_variables()

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            variables{
              calculations{
                id
              }
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "variables"])
      assert [variable, _] = result
      [returned_calculation] = variable["calculations"]
      assert returned_calculation["id"] == to_string(calculation.id)
    end
  end

  describe "createDetailVariable mutation" do

    test "success" do
      %{option_detail: option_detail, decision: decision} = detail_variable_deps()
      input = %{
        slug: "foo",
        title: "foo bar",
        method: "SUM_ALL",
        option_detail_id: option_detail.id,
        decision_id: decision.id,
      }

      query =
        """
        mutation{
          createDetailVariable(
            input: {
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
              method: #{input.method}
              optionDetailId: #{input.option_detail_id}
            }
          ){
            successful
            result {
              id
              title
              slug
              method
            }
          }
        }
        """

      assert {:ok, %{data: data}} = evaluate_graphql(query)
      assert %{"createDetailVariable" => payload} = data
      assert_mutation_success(input, payload, fields([:title, :slug, :option_detail_id, :method]))
      assert %Variable{} = Structure.get_variable(payload["result"]["id"], decision)
    end

    test "failure" do
      %{decision: decision, option_detail: option_detail} = detail_variable_deps()
      input = %{
        title: "-", slug: "A",
        decision_id: decision.id,
        option_detail_id: option_detail.id,
        method: "SUM_ALL",
      }

      query = """
        mutation{
          createDetailVariable(
            input: {
              decisionId: #{input.decision_id}
              optionDetailId: #{input.option_detail_id}
              method: #{input.method}
              title: "#{input.title}"
              slug: "#{input.slug}"
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
      assert %{"createDetailVariable" => payload} = data
      expected = [
        %ValidationMessage{code: :format, field: :title, message: "must include at least one word"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end

    test "decision not found" do
      %{decision: decision, option_detail: option_detail} = detail_variable_deps()
      input = %{
        title: "-", slug: "A",
        decision_id: decision.id,
        option_detail_id: option_detail.id,
        method: "SUM_ALL",
      }
       delete_decision(decision)

      query = """
        mutation{
          createDetailVariable(
            input: {
              decisionId: #{input.decision_id}
              optionDetailId: #{input.option_detail_id}
              method: #{input.method}
              title: "#{input.title}"
              slug: "#{input.slug}"
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
      assert %{"createDetailVariable" => payload} = data
      expected = [
        %ValidationMessage{code: :not_found, field: :decisionId, message: "does not exist"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end
  end

  describe "updateDetailVariable mutation" do

    test "success" do
      %{variable: variable, option_detail: option_detail, decision: decision} = create_detail_variable()
      input = %{
        id: variable.id,
        slug: "foo",
        title: "foo bar",
        method: "SUM_ALL",
        option_detail_id: option_detail.id,
        decision_id: decision.id,
      }
      query = """
        mutation{
          updateDetailVariable(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
              method: #{input.method}
              optionDetailId: #{input.option_detail_id}
            }
          )
          {
            successful
            result {
              id
              title
              slug
              method
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"updateDetailVariable" => payload} = data
      assert_mutation_success(input, payload, fields())
      assert %Variable{} = Structure.get_variable(payload["result"]["id"], decision)
    end

    test "failure" do
      %{variable: variable, decision: decision} = create_detail_variable()
      input = %{
        title: "-", slug: "A",
        id: variable.id,
        decision_id: decision.id,
      }

      query = """
        mutation{
          updateDetailVariable(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
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
      assert %{"updateDetailVariable" => payload} = data
      expected = %ValidationMessage{
        code: :format, field: :title, message: "must include at least one word"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end

    test "Variable not found" do
      %{variable: variable} = create_detail_variable()
      decision = create_decision()

      input = %{
        title: "-", slug: "A",
        decision_id: decision.id,
        id: variable.id,
      }

      query = """
        mutation{
          updateDetailVariable(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
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
      assert %{"updateDetailVariable" => payload} = data
      expected = %ValidationMessage{
        code: "not_found", field: :id, message: "does not exist"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end
  end

  describe "createFilterVariable mutation" do

    test "success" do
      %{option_filter: option_filter, decision: decision} = filter_variable_deps()
      input = %{
        slug: "foo",
        title: "foo bar",
        method: "COUNT_SELECTED",
        option_filter_id: option_filter.id,
        decision_id: decision.id,
      }

      query =
        """
        mutation{
          createFilterVariable(
            input: {
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
              method: #{input.method}
              optionFilterId: #{input.option_filter_id}
            }
          ){
            successful
            result {
              id
              title
              slug
              method
            }
          }
        }
        """

      assert {:ok, %{data: data}} = evaluate_graphql(query)
      assert %{"createFilterVariable" => payload} = data
      assert_mutation_success(input, payload, fields([:title, :slug, :option_filter_id, :method]))
      assert %Variable{} = Structure.get_variable(payload["result"]["id"], decision)
    end

    test "failure" do
      %{decision: decision, option_filter: option_filter} = filter_variable_deps()
      input = %{
        title: "-", slug: "A",
        decision_id: decision.id,
        option_filter_id: option_filter.id,
        method: "COUNT_SELECTED",
      }

      query = """
        mutation{
          createFilterVariable(
            input: {
              decisionId: #{input.decision_id}
              optionFilterId: #{input.option_filter_id}
              method: #{input.method}
              title: "#{input.title}"
              slug: "#{input.slug}"
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
      assert %{"createFilterVariable" => payload} = data
      expected = [
        %ValidationMessage{code: :format, field: :title, message: "must include at least one word"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end

    test "decision not found" do
      %{decision: decision, option_filter: option_filter} = filter_variable_deps()
      delete_decision(decision)
      input = %{
        title: "-", slug: "A",
        decision_id: decision.id,
        option_filter_id: option_filter.id,
        method: "COUNT_SELECTED",
      }

      query = """
        mutation{
          createFilterVariable(
            input: {
              decisionId: #{input.decision_id}
              optionFilterId: #{input.option_filter_id}
              method: #{input.method}
              title: "#{input.title}"
              slug: "#{input.slug}"
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
      assert %{"createFilterVariable" => payload} = data
      expected = [
        %ValidationMessage{code: :not_found, field: :decisionId, message: "does not exist"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end
  end

  describe "updateFilterVariable mutation" do

    test "success" do
      %{variable: variable, option_filter: option_filter, decision: decision} = create_filter_variable()
      input = %{
        id: variable.id,
        slug: "foo",
        title: "foo bar",
        method: "COUNT_SELECTED",
        option_filter_id: option_filter.id,
        decision_id: decision.id,
      }
      query = """
        mutation{
          updateFilterVariable(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
              method: #{input.method}
              optionFilterId: #{input.option_filter_id}
            }
          )
          {
            successful
            result {
              id
              title
              method
              slug
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"updateFilterVariable" => payload} = data
      assert_mutation_success(input, payload, fields())
      assert %Variable{} = Structure.get_variable(payload["result"]["id"], decision)
    end

    test "failure" do
      %{variable: variable, decision: decision} = create_filter_variable()
      input = %{
        title: "-", slug: "A",
        id: variable.id,
        decision_id: decision.id,
      }

      query = """
        mutation{
          updateFilterVariable(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
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
      assert %{"updateFilterVariable" => payload} = data
      expected = %ValidationMessage{
        code: :format, field: :title, message: "must include at least one word"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end

    test "Variable not found" do
      %{variable: variable} = create_filter_variable()
      decision = create_decision()

      input = %{
        title: "-", slug: "A",
        decision_id: decision.id,
        id: variable.id,
      }

      query = """
        mutation{
          updateFilterVariable(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
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
      assert %{"updateFilterVariable" => payload} = data
      expected = %ValidationMessage{
        code: "not_found", field: :id, message: "does not exist"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end
  end

  describe "deleteVariable mutation" do
    test "success" do
      %{decision: decision, variable: variable} = create_detail_variable()
      input = %{id: variable.id, decision_id: decision.id}

      query = """
        mutation{
          deleteVariable(
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
      assert %{"deleteVariable" => %{"successful" => true}} = data
      assert nil == Structure.get_variable(variable.id, decision)
    end
  end
end
