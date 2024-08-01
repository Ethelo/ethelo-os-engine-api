defmodule GraphQL.EtheloApi.AdminSchema.OptionDetailTest do
  @moduledoc """
  Test graphql queries for decisions
  """
  use GraphQL.EtheloApi.AdminSchemaCase
  @moduletag option_detail: true, graphql: true

  alias EtheloApi.Structure
  alias EtheloApi.Structure.OptionDetail
  alias Kronky.ValidationMessage
  import EtheloApi.Structure.Factory

  def fields() do
    %{
    id: :string, title: :string, slug: :string,
    format: :enum,  public: :boolean, sort: :integer,
    input_hint: :string, display_hint: :string,
    updated_at: :date, inserted_at: :date,
   }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  describe "decision => option_details query " do
    test "no filter" do
      %{option_detail: first, decision: decision} = create_option_detail()
      %{option_detail: second} = create_option_detail(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionDetails{
              id
              title
              slug
              format
              displayHint
              inputHint
              public
              sort
              updatedAt
              insertedAt
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionDetails"])
      assert [first_result, second_result] = result

      assert_equivalent_graphql(first, first_result, fields())
      assert_equivalent_graphql(second, second_result, fields())
    end

    test "filter by id" do
      %{option_detail: existing, decision: decision} = create_option_detail()

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionDetails(
              id: #{existing.id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionDetails"])
      assert [%{"id" => id}] = result
      assert to_string(existing.id) == id
    end

    test "filter by slug" do
      %{option_detail: existing, decision: decision} = create_option_detail()

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionDetails(
              slug: "#{existing.slug}"
            ){
              slug
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionDetails"])
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
            optionDetails{
              slug
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionDetails"])
      assert [] = result
    end

    test "inline OptionDetailValues" do
      decision = create_decision()
      %{option_detail_value: first} = create_option_detail_value(decision)
      %{option_detail_value: second} = create_option_detail_value(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionDetails{
              optionValues{
                value
              }
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionDetails"])
      assert [first_result, second_result] = result

      expected = [first.value, second.value]

      first_detail = first_result |> get_in(["optionValues"]) |> hd()
      assert first_detail["value"] in expected

      second_detail = second_result |> get_in(["optionValues"]) |> hd()
      assert second_detail["value"] in expected
    end
  end

  describe "createOptionDetail mutation" do

    test "succeeds" do
      %{decision: decision} = option_detail_deps()
      input = %{
        title: "Moogle",
        format: "STRING",
        slug: "slug",
        display_hint: "Display",
        input_hint: "Input",
        public: false,
        decision_id: decision.id,
        sort: 10,
      }

      query = """
        mutation{
          createOptionDetail(
            input: {
              sort: #{input.sort}
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
              display_hint: "#{input.display_hint}"
              input_hint: "#{input.input_hint}"
              public: #{input.public}
              format: #{input.format}
            }
          )
          {
            successful
            result {
              id
              title
              slug
              format
              displayHint
              inputHint
              public
              sort
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"createOptionDetail" => payload} = data
      fields = fields() |> Map.drop([:id])
      assert_mutation_success(input, payload, fields)
      assert %OptionDetail{} = Structure.get_option_detail(payload["result"]["id"], decision)
    end

    test "failure" do
      %{decision: decision} = option_detail_deps()
      input = %{
        title: "-", slug: "A",
        format: "DATETIME",
        decision_id: decision.id,
        sort: 10,
      }

      query = """
        mutation{
          createOptionDetail(
            input: {
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
              format: #{input.format}
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
      assert %{"createOptionDetail" => payload} = data
      expected = [
        %ValidationMessage{code: :format, field: :title, message: "must include at least one word"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end

    test "decision not found" do
      %{decision: decision} = option_detail_deps()
      delete_decision(decision)
      input = %{
        title: "-", slug: "A",
        format: "STRING",
        decision_id: decision.id,
        sort: 10,
      }

      query = """
        mutation{
          createOptionDetail(
            input: {
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
              format: #{input.format}
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
      assert %{"createOptionDetail" => payload} = data
      expected = [
        %ValidationMessage{code: :not_found, field: :decisionId, message: "does not exist"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end
  end

  describe "updateOptionDetail mutation" do

    test "succeeds" do
      %{decision: decision, option_detail: existing} = create_option_detail()
      input = %{
        title: "Moogle",
        format: "STRING",
        slug: "slug",
        display_hint: "Display",
        input_hint: "Input",
        public: false,
        id: existing.id,
        decision_id: decision.id,
        sort: 10,
    }
      query = """
        mutation{
          updateOptionDetail(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
              display_hint: "#{input.display_hint}"
              input_hint: "#{input.input_hint}"
              public: #{input.public}
              format: #{input.format}
              sort: #{input.sort}
            }
          )
          {
            successful
            result {
              id
              title
              slug
              format
              displayHint
              inputHint
              public
              sort
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"updateOptionDetail" => payload} = data
      assert_mutation_success(input, payload, fields())
      assert %OptionDetail{} = Structure.get_option_detail(payload["result"]["id"], decision)
    end

    test "failure" do
      %{decision: decision, option_detail: existing} = create_option_detail()
      input = %{
        title: "-",
        slug: "A",
        decision_id: decision.id,
        id: existing.id,
        sort: 10,
    }

      query = """
        mutation{
          updateOptionDetail(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
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
      assert %{"updateOptionDetail" => payload} = data
      expected = %ValidationMessage{
        code: :format, field: :title, message: "must include at least one word"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end

    test "option_detail not found" do
      %{option_detail: existing} = create_option_detail()
      decision = create_decision()
      delete_option_detail(existing)

      input = %{
        title: "-", slug: "A",
        decision_id: decision.id, id: existing.id,
        sort: 10,
      }

      query = """
        mutation{
          updateOptionDetail(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
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
      assert %{"updateOptionDetail" => payload} = data
      expected = %ValidationMessage{
        code: "not_found", field: :id, message: "does not exist"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end
  end

  describe "deleteOptionDetail mutation" do
    test "succeeds" do
      %{decision: decision, option_detail: existing} = create_option_detail()
      input = %{id: existing.id, decision_id: decision.id}

      query = """
        mutation{
          deleteOptionDetail(
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
      assert %{"deleteOptionDetail" => %{"successful" => true}} = data
      assert nil == Structure.get_option_detail(existing.id, decision)
    end
  end

end
