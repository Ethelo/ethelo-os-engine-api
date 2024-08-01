defmodule GraphQL.EtheloApi.AdminSchema.OptionCategoryTest do
  @moduledoc """
  Test graphql queries for decisions
  """
  use GraphQL.EtheloApi.AdminSchemaCase
  @moduletag option_category: true, graphql: true

  alias EtheloApi.Structure
  alias EtheloApi.Structure.OptionCategory
  alias Kronky.ValidationMessage
  import EtheloApi.Structure.TestHelper.OptionCategoryHelper
  import EtheloApi.Structure.Factory

  def fields() do
    %{
    id: :string, title: :string, info: :string, keywords: :string,
    slug: :string, sort: :integer, weighting: :integer,
    apply_participant_weights: :boolean, xor: :boolean, scoring_mode: :enum,
    triangle_base: :integer, voting_style: :enum, budget_percent: :float,
    flat_fee: :float, vote_on_percent: :boolean, quadratic: :boolean,
    results_title: :string, updated_at: :date, inserted_at: :date,
   }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  describe "decision => option_categories query " do
    test "no filter" do
      %{option_category: first, decision: decision} = create_option_category()
      %{option_category: second} = create_option_category(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionCategories{
              id
              title
              resultsTitle
              slug
              info
              keywords
              sort
              weighting
              applyParticipantWeights
              xor
              scoringMode
              triangleBase
              budgetPercent
              voteOnPercent
              quadratic
              flatFee
              primaryDetailId
              votingStyle
              defaultLowOptionId
              defaultHighOptionId
              updatedAt
              insertedAt
            }
          }
        }
      """
      response = evaluate_graphql(query)
      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionCategories"])
      assert [_, _] = result
      [first_result, second_result] = result |> Enum.sort_by(&(Map.get(&1, "id")))

      assert_equivalent_graphql(first, first_result, fields())
      assert_equivalent_graphql(second, second_result, fields())
    end

    test "inline Options" do
      %{option: option, decision: decision} = create_option()

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionCategories{
              options{
                id
              }
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionCategories"])
      assert [%{"options" => [loaded]}] = result
      assert to_string(option.id) == loaded["id"]
    end

    test "filter by id" do
      %{option_category: existing, decision: decision} = create_option_category()

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionCategories(
              id: #{existing.id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionCategories"])
      assert [%{"id" => id}] = result
      assert to_string(existing.id) == id
    end

    test "filter by slug" do
      %{option_category: existing, decision: decision} = create_option_category()

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionCategories(
              slug: "#{existing.slug}"
            ){
              slug
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionCategories"])
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
            optionCategories{
              slug
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionCategories"])
      assert [] = result
    end
  end

  describe "createOptionCategory mutation" do

    test "succeeds" do
      %{decision: decision} = deps = option_category_with_detail_deps()
      input = valid_attrs(deps) |> to_graphql_attrs()

      query = """
        mutation{
          createOptionCategory(
            input: {
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              resultsTitle: "#{input.results_title}"
              slug: "#{input.slug}"
              weighting: #{input.weighting}
              xor: #{input.xor}
              voteOnPercent: #{input.vote_on_percent}
              quadratic: #{input.quadratic}
              applyParticipantWeights: #{input.apply_participant_weights}
              scoringMode: #{input.scoring_mode}
              triangleBase: #{input.triangle_base}
              votingStyle: #{input.voting_style}
              budgetPercent: #{input.budget_percent}
              flatFee: #{input.flat_fee}
              sort: #{input.sort}
            }
          )
          {
            successful
            result {
              id
              title
              resultsTitle
              slug
              sort
              weighting
              applyParticipantWeights
              budgetPercent
              flatFee
              xor
              voteOnPercent
              quadratic
              scoringMode
              votingStyle
              triangleBase
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"createOptionCategory" => payload} = data
      field_list = [:title, :results_title, :slug, :weighting, :xor,
      :scoring_mode, :triangle_base, :apply_participant_weights,
      :vote_on_percent, :quadratic, :voting_style]
      assert_mutation_success(input, payload, fields(field_list))
      assert %OptionCategory{} = Structure.get_option_category(payload["result"]["id"], decision)
    end

    test "failure" do
      %{decision: decision} = option_category_deps()
      input = %{
        title: "-", slug: "A",
        weighting: 3,
        decision_id: decision.id,
        sort: 10
      }

      query = """
        mutation{
          createOptionCategory(
            input: {
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
              weighting: #{input.weighting}
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
      assert %{"createOptionCategory" => payload} = data
      expected = [
        %ValidationMessage{code: :format, field: :title, message: "must include at least one word"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end

    test "decision not found" do
      %{decision: decision} = option_category_deps()
      delete_decision(decision)
      input = %{
        title: "-", slug: "A",
        weighting: 3,
        decision_id: decision.id,
        sort: 10,
      }

      query = """
        mutation{
          createOptionCategory(
            input: {
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
              weighting: #{input.weighting}
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
      assert %{"createOptionCategory" => payload} = data
      expected = [
        %ValidationMessage{code: :not_found, field: :decisionId, message: "does not exist"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end
  end

  describe "updateOptionCategory mutation" do

    test "succeeds" do
      %{decision: decision, option_category: existing} = deps = create_option_category_with_detail()
      input = valid_attrs(deps)
        |> Map.merge(%{id: existing.id, decision_id: decision.id, scoring_mode: :triangle})
        |> to_graphql_attrs()

      query = """
        mutation{
          updateOptionCategory(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              resultsTitle: "#{input.results_title}"
              slug: "#{input.slug}"
              weighting: #{input.weighting}
              xor: #{input.xor}
              voteOnPercent: #{input.vote_on_percent}
              quadratic: #{input.quadratic}
              applyParticipantWeights: #{input.apply_participant_weights}
              scoringMode: #{input.scoring_mode}
              budgetPercent: #{input.budget_percent}
              flatFee: #{input.flat_fee}
              triangleBase: #{input.triangle_base}
              primaryDetailId: #{input.primary_detail_id}
              votingStyle: #{input.voting_style}
              sort: #{input.sort}
            }
          )
          {
            successful
            result {
              id
              title
              resultsTitle
              sort
              weighting
              xor
              voteOnPercent
              quadratic
              applyParticipantWeights
              budgetPercent
              flatFee
              scoringMode
              triangleBase
              primaryDetailId
              votingStyle
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"updateOptionCategory" => payload} = data
      assert_mutation_success(input, payload, fields([:title, :weighting]))
      assert %OptionCategory{} = Structure.get_option_category(payload["result"]["id"], decision)
    end

    test "failure" do
      %{decision: decision, option_category: existing} = create_option_category()
      input = %{
        title: "-", slug: "A",
        decision_id: decision.id, id: existing.id, sort: 10,
      }

      query = """
        mutation{
          updateOptionCategory(
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
      assert %{"updateOptionCategory" => payload} = data
      expected = %ValidationMessage{
        code: :format, field: :title, message: "must include at least one word"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end

    test "option_category not found" do
      %{option_category: existing} = create_option_category()
      decision = create_decision()
      delete_option_category(existing)

      input = %{
        title: "-", slug: "A", sort: 10,
        decision_id: decision.id, id: existing.id,
      }

      query = """
        mutation{
          updateOptionCategory(
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
      assert %{"updateOptionCategory" => payload} = data
      expected = %ValidationMessage{
        code: "not_found", field: :id, message: "does not exist"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end
  end

  describe "deleteOptionCategory mutation" do
    test "succeeds" do
      %{decision: decision, option_category: existing} = create_option_category()
      input = %{id: existing.id, decision_id: decision.id}

      query = """
        mutation{
          deleteOptionCategory(
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
      assert %{"deleteOptionCategory" => %{"successful" => true}} = data
      assert nil == Structure.get_option_category(existing.id, decision)
    end
  end

end
