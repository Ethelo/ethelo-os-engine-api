defmodule GraphQL.EtheloApi.AdminSchema.CalculationTest do
  @moduledoc """
  Test graphql queries for decisions
  """
  use GraphQL.EtheloApi.AdminSchemaCase
  @moduletag calculation: true, graphql: true

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Calculation
  alias Kronky.ValidationMessage
  import EtheloApi.Structure.Factory

  def fields() do
    %{
    id: :string, title: :string, personal_results_title: :string, slug: :string, sort: :integer,
    expression: :string, public: :boolean, display_hint: :string,
    updated_at: :date, inserted_at: :date,
   }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  describe "decision => calculations query " do
    test "no filter" do
      %{calculation: first, decision: decision} = create_calculation()
      %{calculation: second} = create_calculation(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            calculations{
              id
              title
              personalResultsTitle
              slug
              expression
              public
              displayHint
              sort
              updatedAt
              insertedAt
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "calculations"])
      assert [_, _] = result
      [first_result, second_result] = result |> Enum.sort_by(&(Map.get(&1, "id")))

      assert_equivalent_graphql(first, first_result, fields())
      assert_equivalent_graphql(second, second_result, fields())
    end

    test "inline Variables" do
      deps = create_calculation_with_variables()
      %{filter_variable: filter_variable, detail_variable: detail_variable, decision: decision} = deps

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            calculations{
              variables{
                id
              }
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "calculations"])
      assert [%{"variables" => variables}] = result
      assert [%{"id" => first_id}, %{"id" => second_id}] = variables
      assert to_string(filter_variable.id) in [first_id, second_id]
      assert to_string(detail_variable.id) in [first_id, second_id]
    end

    test "filter by id" do
      %{calculation: existing, decision: decision} = create_calculation()

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            calculations(
              id: #{existing.id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "calculations"])
      assert [%{"id" => id}] = result
      assert to_string(existing.id) == id
    end

    test "filter by slug" do
      %{calculation: existing, decision: decision} = create_calculation()

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            calculations(
              slug: "#{existing.slug}"
            ){
              slug
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "calculations"])
      assert [%{"slug" => slug}] = result
      assert to_string(existing.slug) == slug
    end

    test "no matches" do
      decision = create_decision()

      query = """
        {
          decision(
            decisionId: "#{decision.id}"
          )
          {
            calculations{
              slug
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "calculations"])
      assert [] = result
    end
  end

  describe "createCalculation mutation" do

    test "succeeds" do
      %{decision: decision, filter_variable: variable} = calculation_with_variables_deps()

      input = %{
        title: "Moogle",
        public: true,
        display_hint: "moogle",
        expression: variable.slug,
        personal_results_title: nil,
        decision_id: decision.id,
        sort: 10,
    }

      query = """
        mutation{
          createCalculation(
            input: {
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              expression: "#{input.expression}"
              public: #{input.public}
              displayHint: "#{input.display_hint}"
              sort: #{input.sort}
              personalResultsTitle: "#{input.personal_results_title}"
            }
          )
          {
            successful
            result {
              id
              title
              personalResultsTitle
              expression
              public
              displayHint
              sort
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"createCalculation" => payload} = data
      assert_mutation_success(input, payload, fields([:title, :personal_results_title, :sort, :public, :expression, :display_hint]))
      assert %Calculation{} = Structure.get_calculation(payload["result"]["id"], decision)
    end

    test "failure" do
      %{decision: decision} = calculation_deps()
      input = %{
        title: "-", slug: "A", sort: 1,
        expression: "3 + 1",
        decision_id: decision.id,
      }

      query = """
        mutation{
          createCalculation(
            input: {
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
              expression: "#{input.expression}"
              sort: #{input.sort}
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
      assert %{"createCalculation" => payload} = data
      expected = [
        %ValidationMessage{code: :format, field: :title, message: "must include at least one word"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end

    test "decision not found" do
      %{decision: decision} = calculation_deps()
      delete_decision(decision)
      input = %{
        title: "-", slug: "A",
        expression: "3 + 1",
        decision_id: decision.id,
      }

      query = """
        mutation{
          createCalculation(
            input: {
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              expression: "#{input.expression}"
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
      assert %{"createCalculation" => payload} = data
      expected = [
        %ValidationMessage{code: :not_found, field: :decisionId, message: "does not exist"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end
  end

  describe "updateCalculation mutation" do

    test "succeeds" do
      %{decision: decision, calculation: existing} = create_calculation()
      %{variable: variable} = create_detail_variable(decision)

      input = %{
        title: "Moogle",
        public: true,
        display_hint: "moogle",
        expression: variable.slug,
        personal_results_title: variable.slug,
        decision_id: decision.id,
        id: existing.id,
        sort: 10,
      }

      query = """
        mutation{
          updateCalculation(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              personalResultsTitle: "#{input.personal_results_title}"
              expression: "#{input.expression}"
              public: #{input.public}
              displayHint: "#{input.display_hint}"
              sort: #{input.sort}
            }
          )
          {
            successful
            result {
              id
              title
              personalResultsTitle
              expression
              public
              displayHint
              sort
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"updateCalculation" => payload} = data
      assert_mutation_success(input, payload, fields([:title, :personal_results_title, :public, :sort]))
      assert %Calculation{} = Structure.get_calculation(payload["result"]["id"], decision)
    end

    test "failure" do
      %{decision: decision, calculation: existing} = create_calculation()
      input = %{
        title: "-", slug: "A",
        decision_id: decision.id,
        id: existing.id,
      }

      query = """
        mutation{
          updateCalculation(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              title: "#{input.title}"
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
      assert %{"updateCalculation" => payload} = data
      expected = %ValidationMessage{
        code: :format, field: :title, message: "must include at least one word"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end

    test "calculation not found" do
      %{calculation: existing} = create_calculation()
      decision = create_decision()
      delete_calculation(existing)

      input = %{
        title: "-", slug: "A",
        decision_id: decision.id,
        id: existing.id,
      }

      query = """
        mutation{
          updateCalculation(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              title: "#{input.title}"
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
      assert %{"updateCalculation" => payload} = data
      expected = %ValidationMessage{
        code: "not_found", field: :id, message: "does not exist"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end
  end

  describe "deleteCalculation mutation" do
    test "succeeds" do
      %{decision: decision, calculation: existing} = create_calculation()
      input = %{id: existing.id, decision_id: decision.id}

      query = """
        mutation{
          deleteCalculation(
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
      assert %{"deleteCalculation" => %{"successful" => true}} = data
      assert nil == Structure.get_calculation(existing.id, decision)
    end
  end

end
