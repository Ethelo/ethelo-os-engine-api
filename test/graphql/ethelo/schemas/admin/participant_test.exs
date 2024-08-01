defmodule GraphQL.EtheloApi.AdminSchema.ParticipantTest do
  @moduledoc """
  Test graphql queries for decisions
  """
  use GraphQL.EtheloApi.AdminSchemaCase
  @moduletag participant: true, graphql: true

  alias EtheloApi.Voting.Participant
  alias Kronky.ValidationMessage
  alias EtheloApi.Voting
  import EtheloApi.Voting.Factory
  alias EtheloApi.Structure.Factory, as: Structure

  def fields() do
    %{
    id: :string, weighting: :decimal,
  #  updated_at: :date, inserted_at: :date,
   }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  describe "decision => participants query " do
    test "no filter" do
      %{participant: first, decision: decision} = create_participant()
      %{participant: second} = create_participant(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            participants{
              id
              weighting
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "participants"])
      assert [_, _] = result
      [first_result, second_result] = result |> Enum.sort_by(&(Map.get(&1, "id")))

      assert_equivalent_graphql(first, first_result, fields())
      assert_equivalent_graphql(second, second_result, fields())
    end

    test "inline voting for all participants" do
      deps = create_participant();
      %{decision: decision, participant: participant} = deps
      %{option: option, option_category: option_category} = Structure.create_option(decision)
      %{criteria: criteria} = Structure.create_criteria(decision)

      deps = %{ option: option, low_option: option, high_option: option,
       option_category: option_category,
      criteria: criteria , decision: decision, participant: participant }

      create_bin_vote_without_deps(decision, deps)
      create_option_category_range_vote_without_deps(decision, deps)
      create_option_category_weight_without_deps(decision, deps)
      create_criteria_weight_without_deps(decision, deps)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            participants{
              id
              binVotes {
                optionId
              }
              optionCategoryRangeVotes {
                optionCategoryId
              }
              optionCategoryWeights {
                optionCategoryId
              }
              criteriaWeights {
                criteriaId
              }
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "participants"])

      assert [%{"binVotes" => bin_votes}] = result
      assert [%{"optionId" => _}] = bin_votes

      assert [%{"optionCategoryRangeVotes" => ocrvs}] = result
      assert [%{"optionCategoryId" => _}] = ocrvs

      assert [%{"optionCategoryWeights" => ocws}] = result
      assert [%{"optionCategoryId" => _}] = ocws

      assert [%{"criteriaWeights" => cws}] = result
      assert [%{"criteriaId" => _}] = cws

    end

    test "subqueries for one participant" do
      %{decision: decision, participants: participants} = EtheloApi.Blueprints.PizzaProject.build()
      decision = EtheloApi.Structure.get_decision(decision.id)
      participant = participants[:one]

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            participants(
              id: #{participant.id}
            ){
              id
              binVotes {
                id
              }

              optionCategoryRangeVotes {
                id
              }

              optionCategoryWeights {
                id
              }

              criteriaWeights {
                id
              }
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "participants"])

      assert [%{
        "id" => id,
        "binVotes" => bin_votes,
        "optionCategoryRangeVotes" => ocrvs,
        "optionCategoryWeights" => ocws,
        "criteriaWeights" => cws,
        }]  = result

        assert to_string(participant.id) == id
        assert [ _ | _ ] = bin_votes
        assert [ _ | _ ] = ocrvs
        assert [ _ | _ ] = ocws
        assert [ _ | _ ] = cws

    end

    test "no matches" do
      decision = create_decision()

      query = """
        {
          decision(
            decisionId: "#{decision.id}"
          )
          {
            participants{
              weighting
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "participants"])
      assert [] = result
    end
  end

  describe "createParticipant mutation" do

    test "succeeds" do
      %{decision: decision} = participant_deps()
      input = %{
        weighting: 5.2,
        decision_id: decision.id,
      }

      query = """
        mutation{
          createParticipant(
            input: {
              decisionId: #{input.decision_id}
              weighting: #{input.weighting}
            }
          )
          {
            successful
            result {
              id
              weighting
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"createParticipant" => payload} = data
      assert_mutation_success(input, payload, fields([:weighting]))
      assert %Participant{} = Voting.get_participant(payload["result"]["id"], decision)
    end

    @tag :skip
    test "failure" do
      %{decision: decision} = participant_deps()
      input = %{
        weighting: 5000.3,
        decision_id: decision.id,
      }

      query = """
        mutation{
          createParticipant(
            input: {
              decisionId: #{input.decision_id}
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
      assert %{"createParticipant" => payload} = data
      expected = [
        %ValidationMessage{code: :format, field: :weighting, message: "must be a number"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end

    test "decision not found" do
      %{decision: decision} = participant_deps()
      delete_decision(decision)
      input = %{
        weighting: 3.2,
        decision_id: decision.id,
      }

      query = """
        mutation{
          createParticipant(
            input: {
              decisionId: #{input.decision_id}
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
      assert %{"createParticipant" => payload} = data
      expected = [
        %ValidationMessage{code: :not_found, field: :decisionId, message: "does not exist"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end
  end

  describe "updateParticipant mutation" do

    test "succeeds" do
      %{decision: decision, participant: existing} = create_participant()
      input = %{
        weighting: 93033.72,
        id: existing.id, decision_id: decision.id
      }
      query = """
        mutation{
          updateParticipant(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              weighting: #{input.weighting}
            }
          )
          {
            successful
            result {
              id
              weighting
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"updateParticipant" => payload} = data
      assert_mutation_success(input, payload, fields([:weighting]))
      assert %Participant{} = Voting.get_participant(payload["result"]["id"], decision)
    end

    @tag :skip

    test "failure" do
      %{decision: decision, participant: existing} = create_participant()
      input = %{
        weighting: "M#",
        decision_id: decision.id, id: existing.id
      }

      query = """
        mutation{
          updateParticipant(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              weighting: "#{input.weighting}"
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
      assert %{"updateParticipant" => payload} = data
      expected = %ValidationMessage{
        code: :format, field: :weighting, message: "must be a number"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end

    test "participant not found" do
      %{participant: existing} = create_participant()
      decision = create_decision()
      delete_participant(existing)

      input = %{
        weighting: 20,
        decision_id: decision.id, id: existing.id
      }

      query = """
        mutation{
          updateParticipant(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
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
      assert %{"updateParticipant" => payload} = data
      expected = %ValidationMessage{
        code: "not_found", field: :id, message: "does not exist"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end
  end

  describe "deleteParticipant mutation" do
    test "succeeds" do
      %{decision: decision, participant: existing} = create_participant()
      input = %{id: existing.id, decision_id: decision.id}

      query = """
        mutation{
          deleteParticipant(
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
      assert %{"deleteParticipant" => %{"successful" => true}} = data
      assert nil == Voting.get_participant(existing.id, decision)
    end
  end

end
