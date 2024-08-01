defmodule GraphQL.EtheloApi.AdminSchema.OptionCategoryWeightTest do
  @moduledoc """
  Test graphql queries for decisions
  """
  use GraphQL.EtheloApi.AdminSchemaCase
  @moduletag option_category_weight: true, graphql: true

  alias EtheloApi.Voting
  alias EtheloApi.Voting.OptionCategoryWeight
  alias Kronky.ValidationMessage
  import EtheloApi.Voting.Factory

  def fields() do
    %{
     weighting: :integer,  updated_at: :date, inserted_at: :date, delete: false
    }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  describe "decision => OptionCategoryWeights query " do
    test "no filter" do
      %{option_category_weight: first, decision: decision} = create_option_category_weight()
      %{option_category_weight: second} = create_option_category_weight(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionCategoryWeights{
              id
              weighting
              optionCategoryId
              participantId
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionCategoryWeights"])
      assert [first_result, second_result] = result

      fields = [:weighting, :option_id, :option_category_id, :participant_id]
      first = first |> Map.take(fields)
      assert_equivalent_graphql(first, first_result, fields())

      second = second |> Map.take(fields)
      assert_equivalent_graphql(second, second_result, fields())
    end

    test "filter by participantId" do
      %{option_category_weight: matching, decision: decision} = create_option_category_weight()
      %{option_category_weight: _not_matching} = create_option_category_weight(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionCategoryWeights(
              participantId: #{matching.participant_id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionCategoryWeights"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "filter by optionCategoryId" do
      %{option_category_weight: matching, decision: decision} = create_option_category_weight()
      %{option_category_weight: _not_matching} = create_option_category_weight(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionCategoryWeights(
              optionCategoryId: #{matching.option_category_id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionCategoryWeights"])
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
            optionCategoryWeights{
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionCategoryWeights"])
      assert [] = result
    end
  end
  describe "upsertOptionCategoryWeight mutation" do

    test "create new" do
      %{participant: participant, option_category: option_category, decision: decision} = option_category_weight_deps()
      input = %{
        decision_id: decision.id,
        weighting: 1,
        option_category_id: option_category.id,
        participant_id: participant.id,
      }

      query =
        """
        mutation{
          upsertOptionCategoryWeight(
            input: {
              decisionId: #{input.decision_id}
              weighting: #{input.weighting},
              optionCategoryId: #{input.option_category_id}
              participantId: #{input.participant_id}
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
              weighting
              optionCategoryId
              participantId
            }
          }
        }
        """

      assert {:ok, %{data: data}} = evaluate_graphql(query)
      assert %{"upsertOptionCategoryWeight" => payload} = data
      assert_mutation_success(input, payload, fields([:title, :slug, :weighting]))
      assert %OptionCategoryWeight{} = Voting.get_option_category_weight(payload["result"]["id"], decision)
    end

    test "invalid values" do
      %{decision: decision, participant: participant, option_category: option_category} = option_category_weight_deps()
      input = %{
        decision_id: decision.id,
        weighting: 9000000,
        option_category_id: option_category.id,
        participant_id: participant.id,
      }

      query =
        """
        mutation{
          upsertOptionCategoryWeight(
            input: {
              decisionId: #{input.decision_id}
              weighting: #{input.weighting},
              optionCategoryId: #{input.option_category_id}
              participantId: #{input.participant_id}
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
              weighting
              optionCategoryId
              participantId
            }
          }
        }
        """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"upsertOptionCategoryWeight" => payload} = data
      expected = [
        %ValidationMessage{code: :less_than_or_equal_to, field: :weighting, message: "must be less than or equal to 100"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end

    test "decision not found" do
      %{participant: participant, option_category: option_category, decision: decision} = option_category_weight_deps()
      input = %{
        decision_id: decision.id,
        weighting: 1,
        option_category_id: option_category.id,
        participant_id: participant.id,
      }
      delete_decision(decision)

      query =
        """
        mutation{
          upsertOptionCategoryWeight(
            input: {
              decisionId: #{input.decision_id}
              weighting: #{input.weighting},
              optionCategoryId: #{input.option_category_id}

              participantId: #{input.participant_id}
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
              weighting
              optionCategoryId
              participantId
            }
          }
        }
        """

      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"upsertOptionCategoryWeight" => payload} = data
      expected = [
        %ValidationMessage{code: :not_found, field: :decisionId, message: "does not exist"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end

    test "upserts" do
      %{option_category_weight: option_category_weight, decision: decision} = create_option_category_weight()
      input = %{
        decision_id: option_category_weight.decision_id,
        weighting: 1,
        option_category_id: option_category_weight.option_category_id,
        participant_id: option_category_weight.participant_id,
      }

      query = """
        mutation{
          upsertOptionCategoryWeight(
            input: {
              decisionId: #{input.decision_id}
              weighting: #{input.weighting},
              optionCategoryId: #{input.option_category_id}
              participantId: #{input.participant_id}
            }
          )
          {
            successful
            messages {
              field
              message
              code
            }
            result {
              id
              weighting
              optionCategoryId
              participantId
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"upsertOptionCategoryWeight" => payload} = data
      assert_mutation_success(input, payload, fields())
      assert %OptionCategoryWeight{} = Voting.get_option_category_weight(payload["result"]["id"], decision)
    end

    test "deletes" do
      %{option_category_weight: option_category_weight, decision: decision} = create_option_category_weight()
      input = %{
        decision_id: option_category_weight.decision_id,
        weighting: 10,
        option_category_id: option_category_weight.option_category_id,
        participant_id: option_category_weight.participant_id,
      }

      query = """
        mutation{
          upsertOptionCategoryWeight(
            input: {
              decisionId: #{input.decision_id}
              weighting: #{input.weighting},
              optionCategoryId: #{input.option_category_id}
              participantId: #{input.participant_id}
              delete: true,
            }
          )
          {
            successful
            messages {
              field
              message
              code
            }
            result {
              id
              weighting
              optionCategoryId
              participantId
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"upsertOptionCategoryWeight" => %{"successful" => true}} = data
      assert nil == Voting.get_option_category_weight(option_category_weight.id, decision)
    end
  end
end
