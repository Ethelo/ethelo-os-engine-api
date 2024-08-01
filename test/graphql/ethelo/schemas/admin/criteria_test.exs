defmodule GraphQL.EtheloApi.AdminSchema.CriteriaTest do
  @moduledoc """
  Test graphql queries for decisions
  """
  use GraphQL.EtheloApi.AdminSchemaCase
  @moduletag criteria: true, graphql: true

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Criteria
  alias Kronky.ValidationMessage
  import EtheloApi.Structure.Factory

  def fields() do
    %{
    id: :string, title: :string, slug: :string,
    bins: :integer, support_only: :boolean, sort: :integer,
    weighting: :integer, apply_participant_weights: :boolean,
    updated_at: :date, inserted_at: :date,
   }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  describe "decision => criterias query " do
    test "no filter" do
      %{criteria: first, decision: decision} = create_criteria()
      %{criteria: second} = create_criteria(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            criterias{
              id
              title
              slug
              info
              bins
              sort
              weighting
              applyParticipantWeights
              supportOnly
              updatedAt
              insertedAt
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "criterias"])
      assert [first_result, second_result] = result
      assert_equivalent_graphql(first, first_result, fields())
      assert_equivalent_graphql(second, second_result, fields())
    end

    test "filter by id" do
      %{criteria: existing, decision: decision} = create_criteria()

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            criterias(
              id: #{existing.id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "criterias"])
      assert [%{"id" => id}] = result
      assert to_string(existing.id) == id
    end

    test "filter by slug" do
      %{criteria: existing, decision: decision} = create_criteria()

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            criterias(
              slug: "#{existing.slug}"
            ){
              slug
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "criterias"])
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
            criterias{
              slug
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "criterias"])
      assert [] = result
    end
  end

  describe "createCriteria mutation" do

    test "succeeds" do
      %{decision: decision} = criteria_deps()
      input = %{
        title: "Moogle", bins: 5,
        decision_id: decision.id,
        sort: 10,
      }

      query = """
        mutation{
          createCriteria(
            input: {
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              bins: #{input.bins}
              sort: #{input.sort}
            }
          )
          {
            successful
            result {
              id
              title
              bins
              sort
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"createCriteria" => payload} = data
      assert_mutation_success(input, payload, fields([:title, :bins, :sort]))
      assert %Criteria{} = Structure.get_criteria(payload["result"]["id"], decision)
    end

    test "failure" do
      %{decision: decision} = criteria_deps()
      input = %{
        title: "-", slug: "A", bins: 3,
        decision_id: decision.id,
      }

      query = """
        mutation{
          createCriteria(
            input: {
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
              bins: #{input.bins}
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
      assert %{"createCriteria" => payload} = data
      expected = [
        %ValidationMessage{code: :format, field: :title, message: "must include at least one word"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end

    test "decision not found" do
      %{decision: decision} = criteria_deps()
      delete_decision(decision)
      input = %{
        title: "-", slug: "A", bins: 3,
        decision_id: decision.id,
      }

      query = """
        mutation{
          createCriteria(
            input: {
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
              bins: #{input.bins}
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
      assert %{"createCriteria" => payload} = data
      expected = [
        %ValidationMessage{code: :not_found, field: :decisionId, message: "does not exist"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end
  end

  describe "updateCriteria mutation" do

    test "succeeds" do
      %{decision: decision, criteria: existing} = create_criteria()
      input = %{
        title: "Moogle", bins: 5,
        id: existing.id, decision_id: decision.id,
        sort: 10,
      }
      query = """
        mutation{
          updateCriteria(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              bins: #{input.bins}
              sort: #{input.sort}
            }
          )
          {
            successful
            result {
              id
              title
              bins
              sort
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"updateCriteria" => payload} = data
      assert_mutation_success(input, payload, fields([:title, :bins]))
      assert %Criteria{} = Structure.get_criteria(payload["result"]["id"], decision)
    end

    test "failure" do
      %{decision: decision, criteria: existing} = create_criteria()
      input = %{
        title: "-", slug: "A",
        decision_id: decision.id, id: existing.id,
      }

      query = """
        mutation{
          updateCriteria(
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
      assert %{"updateCriteria" => payload} = data
      expected = %ValidationMessage{
        code: :format, field: :title, message: "must include at least one word"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end

    test "criteria not found" do
      %{criteria: existing} = create_criteria()
      decision = create_decision()
      delete_criteria(existing)

      input = %{
        title: "-", slug: "A",
        decision_id: decision.id, id: existing.id,
      }

      query = """
        mutation{
          updateCriteria(
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
      assert %{"updateCriteria" => payload} = data
      expected = %ValidationMessage{
        code: "not_found", field: :id, message: "does not exist"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end
  end

  describe "deleteCriteria mutation" do
    test "succeeds" do
      %{decision: decision, criteria: first} = create_criteria()
      %{criteria: _second} = create_criteria(decision)

      input = %{id: first.id, decision_id: decision.id}

      query = """
        mutation{
          deleteCriteria(
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
      assert %{"deleteCriteria" => %{"successful" => true}} = data
      assert nil == Structure.get_criteria(first.id, decision)
    end

    test "failure" do
      %{decision: decision, criteria: only} = create_criteria()

      input = %{id: only.id, decision_id: decision.id}

      query = """
        mutation{
          deleteCriteria(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
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
      assert %{"deleteCriteria" => payload} = data
      expected = %ValidationMessage{
        code: "protected_record", field: :id, message: "cannot be deleted"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
      refute nil == Structure.get_criteria(only.id, decision)
    end
  end

end
