defmodule GraphQL.EtheloApi.AdminSchema.OptionFilterTest do
  @moduledoc """
  Test graphql queries for decisions
  """
  use GraphQL.EtheloApi.AdminSchemaCase
  @moduletag option_filter: true, graphql: true

  alias EtheloApi.Structure
  alias EtheloApi.Structure.OptionFilter
  alias Kronky.ValidationMessage
  import EtheloApi.Structure.Factory

  def fields() do
    %{
      id: :string, title: :string, slug: :string,
      match_value: :string, match_mode: :enum,
      updated_at: :date, inserted_at: :date,
  }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  describe "decision => optionFilters query " do
    test "no filter" do
      %{option_filter: first, decision: decision} = create_option_detail_filter()
      %{option_filter: second} = create_option_category_filter(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionFilters{
              id
              title
              slug
              matchValue
              matchMode
              updatedAt
              insertedAt
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionFilters"])
      assert [first_result, second_result] = result

      assert_equivalent_graphql(first, first_result, fields())
      assert_equivalent_graphql(second, second_result, fields())
    end

    test "filter by id" do
      %{option_filter: matching, decision: decision} = create_option_detail_filter()
      %{option_filter: _not_matching} = create_option_detail_filter(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionFilters(
              id: #{matching.id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionFilters"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "filter by slug" do
      %{option_filter: matching, decision: decision} = create_option_detail_filter()
      %{option_filter: _not_matching} = create_option_detail_filter(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionFilters(
              slug: "#{matching.slug}"
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionFilters"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "filter by OptionCategoryId" do
      %{option_filter: matching, decision: decision} = create_option_category_filter()
      %{option_filter: _not_matching} = create_option_category_filter(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionFilters(
              optionCategoryId: #{matching.option_category_id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionFilters"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "filter by OptionDetailId" do
      %{option_filter: matching, decision: decision} = create_option_detail_filter()
      %{option_filter: _not_matching} = create_option_detail_filter(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionFilters(
              optionDetailId: #{matching.option_detail_id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionFilters"])
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
            optionFilters{
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionFilters"])
      assert [] = result
    end

    test "inline OptionCategory" do
      %{option_category: first, decision: decision} = create_option_category_filter()
      %{option_category: second} = create_option_category_filter(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionFilters{
              optionCategory{
                id
              }
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionFilters"])
      assert [first_result, second_result] = result

      expected_ids = [to_string(first.id), to_string(second.id)]

      first_id = get_in(first_result, ["optionCategory", "id"])
      second_id = get_in(second_result, ["optionCategory", "id"])
      assert first_id in expected_ids
      assert second_id in expected_ids
    end

    test "inline OptionDetail" do
      %{option_detail: first, decision: decision} = create_option_detail_filter()
      %{option_detail: second} = create_option_detail_filter(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionFilters{
              optionDetail{
                id
              }
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionFilters"])
      assert [first_result, second_result] = result

      expected_ids = [to_string(first.id), to_string(second.id)]

      first_id = get_in(first_result, ["optionDetail", "id"])
      second_id = get_in(second_result, ["optionDetail", "id"])
      assert first_id in expected_ids
      assert second_id in expected_ids
    end

    test "inline Options" do
      %{decision: decision} = create_all_options_filter()
      %{option: option} = create_option(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionFilters{
              options{
                id
              }
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionFilters"])
      assert [option_filter] = result
      [returned_option] = option_filter["options"]
      assert returned_option["id"] == to_string(option.id)
    end
  end

  describe "createOptionDetailFilter mutation" do

    test "success" do
      %{option_detail: option_detail, decision: decision} = option_detail_filter_deps()
      input = %{
        decision_id: decision.id,
        slug: "foo",
        title: "foo bar",
        match_mode: "EQUALS",
        match_value: "foo bar baz",
        option_detail_id: option_detail.id,
      }

      query =
        """
        mutation{
          createOptionDetailFilter(
            input: {
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
              matchMode: #{input.match_mode}
              matchValue: "#{input.match_value}"
              optionDetailId: #{input.option_detail_id}
            }
          ){
            successful
            result {
              id
              title
              slug
              matchValue
              matchMode
            }
          }
        }
        """

      assert {:ok, %{data: data}} = evaluate_graphql(query)
      assert %{"createOptionDetailFilter" => payload} = data
      assert_mutation_success(input, payload, fields([:title, :slug, :option_detail_id, :match_value]))
      assert %OptionFilter{} = Structure.get_option_filter(payload["result"]["id"], decision)
    end

    test "failure" do
      %{decision: decision, option_detail: option_detail} = option_detail_filter_deps()
      input = %{
        title: "-", slug: "A",
        decision_id: decision.id,
        option_detail_id: option_detail.id,
        match_mode: "EQUALS",
      }

      query = """
        mutation{
          createOptionDetailFilter(
            input: {
              decisionId: #{input.decision_id}
              optionDetailId: #{input.option_detail_id}
              match_mode: #{input.match_mode}
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
      assert %{"createOptionDetailFilter" => payload} = data
      expected = [
        %ValidationMessage{code: :format, field: :title, message: "must include at least one word"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end

    test "decision not found" do
      %{decision: decision, option_detail: option_detail} = option_detail_filter_deps()
      input = %{
        title: "-", slug: "A",
        decision_id: decision.id,
        option_detail_id: option_detail.id,
        match_mode: "EQUALS",
      }
       delete_decision(decision)

      query = """
        mutation{
          createOptionDetailFilter(
            input: {
              decisionId: #{input.decision_id}
              optionDetailId: #{input.option_detail_id}
              match_mode: #{input.match_mode}
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
      assert %{"createOptionDetailFilter" => payload} = data
      expected = [
        %ValidationMessage{code: :not_found, field: :decisionId, message: "does not exist"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end
  end

  describe "updateOptionDetailFilter mutation" do

    test "success" do
      %{option_filter: option_filter, option_detail: option_detail, decision: decision} = create_option_detail_filter()
      input = %{
        id: option_filter.id,
        slug: "foo",
        title: "foo bar",
        match_mode: "EQUALS",
        match_value: "foo bar baz",
        option_detail_id: option_detail.id,
        decision_id: decision.id,
      }
      query = """
        mutation{
          updateOptionDetailFilter(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
              matchMode: #{input.match_mode}
              matchValue: "#{input.match_value}"
              optionDetailId: #{input.option_detail_id}
            }
          )
          {
            successful
            result {
              id
              title
              slug
              matchMode
              matchValue
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"updateOptionDetailFilter" => payload} = data
      assert_mutation_success(input, payload, fields())
      assert %OptionFilter{} = Structure.get_option_filter(payload["result"]["id"], decision)
    end

    test "failure" do
      %{option_filter: option_filter, decision: decision} = create_option_detail_filter()
      input = %{
        title: "-", slug: "A",
        id: option_filter.id,
        decision_id: decision.id,
      }

      query = """
        mutation{
          updateOptionDetailFilter(
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
      assert %{"updateOptionDetailFilter" => payload} = data
      expected = %ValidationMessage{
        code: :format, field: :title, message: "must include at least one word"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end

    test "OptionFilter not found" do
      %{option_filter: option_filter} = create_option_detail_filter()
      decision = create_decision()

      input = %{
        title: "-", slug: "A",
        decision_id: decision.id,
        id: option_filter.id,
      }

      query = """
        mutation{
          updateOptionDetailFilter(
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
      assert %{"updateOptionDetailFilter" => payload} = data
      expected = %ValidationMessage{
        code: "not_found", field: :id, message: "does not exist"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end
  end

  describe "createOptionCategoryFilter mutation" do

    test "success" do
      %{option_category: option_category, decision: decision} = option_category_filter_deps()
      input = %{
        slug: "foo",
        title: "foo bar",
        match_mode: "IN_CATEGORY",
        option_category_id: option_category.id,
        decision_id: decision.id,
      }

      query =
        """
        mutation{
          createOptionCategoryFilter(
            input: {
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
              matchMode: #{input.match_mode}
              optionCategoryId: #{input.option_category_id}
            }
          ){
            successful
            result {
              id
              title
              slug
              matchMode
            }
          }
        }
        """

      assert {:ok, %{data: data}} = evaluate_graphql(query)
      assert %{"createOptionCategoryFilter" => payload} = data
      assert_mutation_success(input, payload, fields([:title, :slug, :option_category_id, :match_value]))
      assert %OptionFilter{} = Structure.get_option_filter(payload["result"]["id"], decision)
    end

    test "failure" do
      %{decision: decision, option_category: option_category} = option_category_filter_deps()
      input = %{
        title: "-", slug: "A",
        decision_id: decision.id,
        option_category_id: option_category.id,
        match_mode: "IN_CATEGORY",
      }

      query = """
        mutation{
          createOptionCategoryFilter(
            input: {
              decisionId: #{input.decision_id}
              optionCategoryId: #{input.option_category_id}
              match_mode: #{input.match_mode}
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
      assert %{"createOptionCategoryFilter" => payload} = data
      expected = [
        %ValidationMessage{code: :format, field: :title, message: "must include at least one word"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end

    test "decision not found" do
      %{decision: decision, option_category: option_category} = option_category_filter_deps()
      delete_decision(decision)
      input = %{
        title: "-", slug: "A",
        decision_id: decision.id,
        option_category_id: option_category.id,
        match_mode: "IN_CATEGORY",
      }

      query = """
        mutation{
          createOptionCategoryFilter(
            input: {
              decisionId: #{input.decision_id}
              optionCategoryId: #{input.option_category_id}
              matchMode: #{input.match_mode}
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
      assert %{"createOptionCategoryFilter" => payload} = data
      expected = [
        %ValidationMessage{code: :not_found, field: :decisionId, message: "does not exist"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end
  end

  describe "updateOptionCategoryFilter mutation" do

    test "success" do
      %{option_filter: option_filter, option_category: option_category, decision: decision} = create_option_category_filter()
      input = %{
        id: option_filter.id,
        slug: "foo",
        title: "foo bar",
        match_mode: "IN_CATEGORY",
        option_category_id: option_category.id,
        decision_id: decision.id,
      }
      query = """
        mutation{
          updateOptionCategoryFilter(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
              matchMode: #{input.match_mode}
              optionCategoryId: #{input.option_category_id}
            }
          )
          {
            successful
            result {
              id
              title
              matchMode
              slug
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"updateOptionCategoryFilter" => payload} = data
      assert_mutation_success(input, payload, fields())
      assert %OptionFilter{} = Structure.get_option_filter(payload["result"]["id"], decision)
    end

    test "failure" do
      %{option_filter: option_filter, decision: decision} = create_option_category_filter()
      input = %{
        title: "-", slug: "A",
        id: option_filter.id,
        decision_id: decision.id,
      }

      query = """
        mutation{
          updateOptionCategoryFilter(
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
      assert %{"updateOptionCategoryFilter" => payload} = data
      expected = %ValidationMessage{
        code: :format, field: :title, message: "must include at least one word"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end

    test "OptionFilter not found" do
      %{option_filter: option_filter} = create_option_category_filter()
      decision = create_decision()

      input = %{
        title: "-", slug: "A",
        decision_id: decision.id,
        id: option_filter.id,
      }

      query = """
        mutation{
          updateOptionCategoryFilter(
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
      assert %{"updateOptionCategoryFilter" => payload} = data
      expected = %ValidationMessage{
        code: "not_found", field: :id, message: "does not exist"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end
  end

  describe "deleteOptionFilter mutation" do
    test "success" do
      %{decision: decision, option_filter: option_filter} = create_option_detail_filter()
      input = %{id: option_filter.id, decision_id: decision.id}

      query = """
        mutation{
          deleteOptionFilter(
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
      assert %{"deleteOptionFilter" => %{"successful" => true}} = data
      assert nil == Structure.get_option_filter(option_filter.id, decision)
    end
  end
end
