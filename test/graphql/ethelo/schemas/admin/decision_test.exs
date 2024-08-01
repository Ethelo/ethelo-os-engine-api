defmodule GraphQL.EtheloApi.AdminSchema.DecisionTest do
  @moduledoc """
  Test graphql queries for decisions
  """
  use GraphQL.EtheloApi.AdminSchemaCase
  @moduletag decision: true, graphql: true

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias Kronky.ValidationMessage
  import EtheloApi.Structure.Factory

  def fields() do
     %{
       id: :string, title: :string, slug: :string, info: :string,
       copyable: :boolean, max_users: :integer, language: :string,
       updated_at: :date, inserted_at: :date
     }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  describe "decisions query" do
    test "no filters" do
      first = create_decision()
      second = create_decision()

      query = """
        {
          decisions {
            id
            title
            slug
            info
            copyable
            language
            maxUsers
            updatedAt
            insertedAt
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decisions"])
      assert [first_result, second_result] = result
      assert_equivalent_graphql(first, first_result, fields())
      assert_equivalent_graphql(second, second_result, fields())
    end
   end

  describe "decision => summary query " do

    test "filter by id" do
      create_decision()
      decision = create_decision()

      query = """
        query($decisionId: ID!){
          decision(
            decisionId: $decisionId
          )
          {
            meta {
              successful
              messages{
                message
              }
            }
            summary{
              id
            }
          }
        }
      """

      response = evaluate_graphql(query, variables: %{"decisionId" => decision.id})

      assert {:ok, %{data: data}} = response
      summary = get_in(data, ["decision", "summary"])
      assert %{"id" => id} = summary
      assert to_string(decision.id) == id

      meta = get_in(data, ["decision", "meta"])
      assert %{"successful" => true, "messages" => []} = meta
    end

    test "decision not found" do
      decision = create_decision()
      delete_decision(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            meta {
              successful
              messages{
                message
                field
              }
            }
            summary{
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      meta = get_in(data, ["decision", "meta"])
      assert %{"successful" => false, "messages" => [message]} = meta
      assert %{"message" => "does not exist", "field" => "filters"} = message
      summary = get_in(data, ["decision", "summary"])
      assert nil == summary
    end


    test "filter by slug" do
      create_decision()
      decision = create_decision()

      query = """
        {
          decision(
            decisionSlug: "#{decision.slug}"
          )
          {
            summary{
              slug
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
        result = get_in(data, ["decision", "summary"])
        assert %{"slug" => slug} = result
        assert to_string(decision.slug) == slug
    end
  end

  describe "createDecision mutation" do

    test "succeeds" do
      input = %{
        title: "Moogle", info: "Moogle Moogle",
        copyable: true, max_users: 50, language: "en",
      }

      query = """
        mutation{
          createDecision(
            input: {
              title: "#{input.title}"
              info: "#{input.info}"
              language: "#{input.language}"
              copyable: #{input.copyable}
              maxUsers: #{input.max_users}
            }
          )
          {
            successful
            result {
              id
              title
              info
              copyable
              language
              maxUsers
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"createDecision" => payload} = data
      assert_mutation_success(input, payload, fields([:title, :info, :copyable,:language, :max_users]))
      assert %Decision{} = Structure.get_decision(payload["result"]["id"])
    end

    test "failure" do
      input = %{
        title: "-", slug: "A",
      }

      query = """
        mutation{
          createDecision(
            input: {
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
      assert %{"createDecision" => payload} = data
      expected = %ValidationMessage{
        code: :format, field: :title, message: "must include at least one word"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end
  end

  describe "updateDecision mutation" do

    test "succeeds" do
      existing = create_decision()
      input = %{
        title: "Moogle", info: "Moogle Moogle",
        copyable: true, max_users: 50, language: "en",
        id: existing.id,
      }
      query =
        """
        mutation{
          updateDecision(
            input: {
              id: #{input.id}
              title: "#{input.title}"
              info: "#{input.info}"
              language: "#{input.language}"
              copyable: #{input.copyable}
              maxUsers: #{input.max_users}
            }
          )
          {
            successful
            result {
              id
              title
              info
              language
              copyable
              maxUsers
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"updateDecision" => payload} = data
      assert_mutation_success(input, payload, fields([:title, :info, :copyable, :max_users]))
      assert %Decision{} = Structure.get_decision(payload["result"]["id"])
    end

    test "failure" do
      existing = create_decision()
      input = %{
        title: "-", slug: "A",
        id: existing.id
      }

      query = """
        mutation{
          updateDecision(
            input: {
              id: #{input.id}
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
      assert %{"updateDecision" => payload} = data

      expected = %ValidationMessage{
        code: :format, field: :title, message: "must include at least one word"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end
  end

  describe "deleteDecision mutation" do
    test "succeeds" do
      existing = create_decision()
      input = %{id: existing.id}

      query = """
        mutation{
          deleteDecision(
            input: {
              id: #{input.id}
            }
          ){
            successful
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"deleteDecision" => %{"successful" => true}} = data
      assert nil == Structure.get_decision(existing.id)
    end
  end

end
