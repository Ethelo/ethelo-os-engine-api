defmodule GraphQL.EtheloApi.AdminSchema.OptionTest do
  @moduledoc """
  Test graphql queries for decisions
  """
  use GraphQL.EtheloApi.AdminSchemaCase
  @moduletag option: true, graphql: true

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Option
  alias Kronky.ValidationMessage
  import EtheloApi.Structure.Factory

  def fields() do
    %{
      id: :string, title: :string, info: :string, results_title: :string,
      enabled: :boolean, sort: :integer, determinative: :boolean,
      updated_at: :date, inserted_at: :date,
    }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  describe "decision => options query " do
    test "no filter" do
      %{option: first, decision: decision} = create_option()
      %{option: second} = create_option(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            options{
              id
              title
              resultsTitle
              info
              enabled
              determinative
              sort
              updatedAt
              insertedAt

            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "options"])
      assert [first_result, second_result] = result

      assert_equivalent_graphql(first, first_result, fields())
      assert_equivalent_graphql(second, second_result, fields())
    end

    test "filter by id" do
      %{option: matching, decision: decision} = create_option()
      %{option: _not_matching} = create_option(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            options(
              id: #{matching.id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "options"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "filter by slug" do
      %{option: matching, decision: decision} = create_option()
      %{option: _not_matching} = create_option(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            options(
              slug: "#{matching.slug}"
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "options"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "filter by OptionCategoryId" do
      %{option: matching, decision: decision} = create_option()
      %{option: _not_matching} = create_option(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            options(
              optionCategoryId: #{matching.option_category_id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "options"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "filter by enabled" do
      decision = create_decision()
      %{option: matching, decision: decision} = create_option(decision, %{enabled: true})
      %{option: _not_matching} = create_option(decision, %{enabled: false})

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            options(
              enabled: #{matching.enabled}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "options"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "filter by optionFilterId" do
      deps = create_option()
      %{decision: decision, option: matching, option_category: option_category} = deps
      %{option_filter: option_filter} = create_option_category_filter_matching(decision, option_category, "in_category")

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            options(
              optionFilterId: #{option_filter.id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "options"])
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
            options{
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "options"])
      assert [] = result
    end

    test "inline OptionCategories" do
      %{option_category: first, decision: decision} = create_option()
      %{option_category: second} = create_option(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            options{
              optionCategory{
                id
              }
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "options"])
      assert [first_result, second_result] = result

      expected_ids = [to_string(first.id), to_string(second.id)]

      first_id = get_in(first_result, ["optionCategory", "id"])
      second_id = get_in(second_result, ["optionCategory", "id"])
      assert first_id in expected_ids
      assert second_id in expected_ids
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
            options{
              detailValues{
                value
              }
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "options"])
      assert [first_result, second_result] = result

      expected = [first.value, second.value]

      first_detail = first_result |> get_in(["detailValues"]) |> hd()
      assert first_detail["value"] in expected

      second_detail = second_result |> get_in(["detailValues"]) |> hd()
      assert second_detail["value"] in expected
    end
  end

  describe "createOption mutation" do

    test "succeeds" do
      %{decision: decision, option_category: option_category} = option_deps()
      input = %{
        title: "Moogle",
        results_title: "Meegle",
        option_category_id: option_category.id,
        info: "Display",
        enabled: false,
        decision_id: decision.id,
        sort: 10,
        determinative: true,
      }

      query = """
        mutation{
          createOption(
            input: {
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              resultsTitle: "#{input.results_title}"
              optionCategoryId: #{input.option_category_id}
              info: "#{input.info}"
              enabled: #{input.enabled}
              sort: #{input.sort}
              determinative: #{input.determinative}
            }
          )
          {
            successful
            result {
              id
              title
              resultsTitle
              info
              determinative
              enabled
              sort
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"createOption" => payload} = data
      fields = fields() |> Map.drop([:id])
      assert_mutation_success(input, payload, fields)
      assert %Option{} = Structure.get_option(payload["result"]["id"], decision)
    end

    test "failure" do
      %{decision: decision} = option_deps()
      input = %{
        title: "-", slug: "A",
        decision_id: decision.id,
      }

      query = """
        mutation{
          createOption(
            input: {
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
      assert %{"createOption" => payload} = data
      expected = [
        %ValidationMessage{code: :format, field: :title, message: "must include at least one word"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end

    test "decision not found" do
      %{decision: decision} = option_deps()
      delete_decision(decision)
      input = %{
        title: "-", slug: "A",
        decision_id: decision.id,
      }

      query = """
        mutation{
          createOption(
            input: {
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
      assert %{"createOption" => payload} = data
      expected = [
        %ValidationMessage{code: :not_found, field: :decisionId, message: "does not exist"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end
  end

  describe "updateOption mutation" do

    test "succeeds" do
      %{decision: decision, option: option} = create_option()
      %{option_category: option_category} = create_option_category(decision)
      input = %{
        title: "Moogle",
        results_title: "Meegle",
        option_category_id: option_category.id,
        info: "Display",
        enabled: false,
        id: option.id,
        decision_id: decision.id,
        sort: 10,
        determinative: true,
      }
      query = """
        mutation{
          updateOption(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              resultsTitle: "#{input.results_title}"
              optionCategoryId: #{input.option_category_id}
              info: "#{input.info}"
              enabled: #{input.enabled}
              sort: #{input.sort}
              determinative: #{input.determinative}
            }
          )
          {
            successful
            result {
              id
              title
              resultsTitle
              info
              determinative
              enabled
              sort
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"updateOption" => payload} = data
      assert_mutation_success(input, payload, fields())
      assert %Option{} = Structure.get_option(payload["result"]["id"], decision)
    end

    test "failure" do
      %{decision: decision, option: option} = create_option()
      input = %{
        title: "-", slug: "A",
        decision_id: decision.id,
        id: option.id,
      }

      query = """
        mutation{
          updateOption(
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
      assert %{"updateOption" => payload} = data
      expected = %ValidationMessage{
        code: :format, field: :title, message: "must include at least one word"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end

    test "Option not found" do
      %{option: option} = create_option()
      decision = create_decision()
      delete_option(option)

      input = %{
        title: "-", slug: "A",
        decision_id: decision.id,
        id: option.id
      }

      query = """
        mutation{
          updateOption(
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
      assert %{"updateOption" => payload} = data
      expected = %ValidationMessage{
        code: "not_found", field: :id, message: "does not exist"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end
  end

  describe "deleteOption mutation" do
    test "succeeds" do
      %{decision: decision, option: option} = create_option()
      input = %{id: option.id, decision_id: decision.id}

      query = """
        mutation{
          deleteOption(
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
      assert %{"deleteOption" => %{"successful" => true}} = data
      assert nil == Structure.get_option(option.id, decision)
    end
  end
end
