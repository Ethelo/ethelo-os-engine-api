defmodule GraphQL.EtheloApi.AdminSchema.CriteriaWeightTest do
  @moduledoc """
  Test graphql queries for decisions
  """
  use GraphQL.EtheloApi.AdminSchemaCase
  @moduletag criteria_weight: true, graphql: true

  alias EtheloApi.Voting
  alias EtheloApi.Voting.CriteriaWeight
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

  describe "decision => CriteriaWeights query " do
    test "no filter" do
      %{criteria_weight: first, decision: decision} = create_criteria_weight()
      %{criteria_weight: second} = create_criteria_weight(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            criteriaWeights{
              id
              weighting
              criteriaId
              participantId
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "criteriaWeights"])
      assert [first_result, second_result] = result

      fields = [:weighting, :option_id, :criteria_id, :participant_id]
      first = first |> Map.take(fields)
      assert_equivalent_graphql(first, first_result, fields())

      second = second |> Map.take(fields)
      assert_equivalent_graphql(second, second_result, fields())
    end

    test "filter by participantId" do
      %{criteria_weight: matching, decision: decision} = create_criteria_weight()
      %{criteria_weight: _not_matching} = create_criteria_weight(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            criteriaWeights(
              participantId: #{matching.participant_id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "criteriaWeights"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "filter by criteriaId" do
      %{criteria_weight: matching, decision: decision} = create_criteria_weight()
      %{criteria_weight: _not_matching} = create_criteria_weight(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            criteriaWeights(
              criteriaId: #{matching.criteria_id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "criteriaWeights"])
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
            criteriaWeights{
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "criteriaWeights"])
      assert [] = result
    end
  end
  describe "upsertCriteriaWeight mutation" do

    test "create new" do
      %{participant: participant, criteria: criteria, decision: decision} = criteria_weight_deps()
      input = %{
        decision_id: decision.id,
        weighting: 1,
        criteria_id: criteria.id,
        participant_id: participant.id,
      }

      query =
        """
        mutation{
          upsertCriteriaWeight(
            input: {
              decisionId: #{input.decision_id}
              weighting: #{input.weighting},
              criteriaId: #{input.criteria_id}
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
              criteriaId
              participantId
            }
          }
        }
        """

      assert {:ok, %{data: data}} = evaluate_graphql(query)
      assert %{"upsertCriteriaWeight" => payload} = data
      assert_mutation_success(input, payload, fields([:title, :slug, :weighting]))
      assert %CriteriaWeight{} = Voting.get_criteria_weight(payload["result"]["id"], decision)
    end

    test "invalid values" do
      %{decision: decision, participant: participant, criteria: criteria} = criteria_weight_deps()
      input = %{
        decision_id: decision.id,
        weighting: 9000000,
        criteria_id: criteria.id,
        participant_id: participant.id,
      }

      query =
        """
        mutation{
          upsertCriteriaWeight(
            input: {
              decisionId: #{input.decision_id}
              weighting: #{input.weighting},
              criteriaId: #{input.criteria_id}
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
              criteriaId
              participantId
            }
          }
        }
        """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"upsertCriteriaWeight" => payload} = data
      expected = [
        %ValidationMessage{code: :less_than_or_equal_to, field: :weighting, message: "must be less than or equal to 100"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end

    test "decision not found" do
      %{participant: participant, criteria: criteria, decision: decision} = criteria_weight_deps()
      input = %{
        decision_id: decision.id,
        weighting: 1,
        criteria_id: criteria.id,
        participant_id: participant.id,
      }
      delete_decision(decision)

      query =
        """
        mutation{
          upsertCriteriaWeight(
            input: {
              decisionId: #{input.decision_id}
              weighting: #{input.weighting},
              criteriaId: #{input.criteria_id}
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
              criteriaId
              participantId
            }
          }
        }
        """

      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"upsertCriteriaWeight" => payload} = data
      expected = [
        %ValidationMessage{code: :not_found, field: :decisionId, message: "does not exist"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end

    test "upserts" do
      %{criteria_weight: criteria_weight, decision: decision} = create_criteria_weight()
      input = %{
        decision_id: criteria_weight.decision_id,
        weighting: 1,
        criteria_id: criteria_weight.criteria_id,
        participant_id: criteria_weight.participant_id,
      }

      query = """
        mutation{
          upsertCriteriaWeight(
            input: {
              decisionId: #{input.decision_id}
              weighting: #{input.weighting},
              criteriaId: #{input.criteria_id}
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
              criteriaId
              participantId
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"upsertCriteriaWeight" => payload} = data
      assert_mutation_success(input, payload, fields())
      assert %CriteriaWeight{} = Voting.get_criteria_weight(payload["result"]["id"], decision)
    end

    test "deletes" do
      %{criteria_weight: criteria_weight, decision: decision} = create_criteria_weight()
      input = %{
        decision_id: criteria_weight.decision_id,
        weighting: 10,
        criteria_id: criteria_weight.criteria_id,
        participant_id: criteria_weight.participant_id,
      }

      query = """
        mutation{
          upsertCriteriaWeight(
            input: {
              decisionId: #{input.decision_id}
              weighting: #{input.weighting},
              criteriaId: #{input.criteria_id}
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
              criteriaId

              participantId
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"upsertCriteriaWeight" => %{"successful" => true}} = data
      assert nil == Voting.get_criteria_weight(criteria_weight.id, decision)
    end
  end
end
