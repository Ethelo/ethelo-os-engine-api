defmodule EtheloApi.Graphql.Schemas.ParticipantTest do
  @moduledoc """
  Test graphql queries for Participants
  """
  use EtheloApi.Graphql.SchemaCase
  @moduletag participant: true, graphql: true

  alias EtheloApi.Voting
  alias EtheloApi.Structure.Factory, as: Structure

  import EtheloApi.Voting.Factory
  import EtheloApi.Voting.TestHelper.ParticipantHelper

  def decision_with_votes() do
    decision = create_decision()

    %{option: option, option_category: option_category} = Structure.create_option(decision)

    %{criteria: criteria} = Structure.create_criteria(decision)

    deps = %{
      option: option,
      low_option: option,
      high_option: option,
      option_category: option_category,
      criteria: criteria,
      decision: decision
    }

    participant1 = create_participant_without_deps(decision, deps)

    participant1_deps = deps |> Map.put(:participant, participant1)

    create_bin_vote_without_deps(decision, participant1_deps)
    create_option_category_range_vote_without_deps(decision, participant1_deps)
    create_option_category_weight_without_deps(decision, participant1_deps)
    create_criteria_weight_without_deps(decision, participant1_deps)

    participant2 = create_participant_without_deps(decision, deps)

    participant2_deps = deps |> Map.put(:participant, participant2)

    create_bin_vote_without_deps(decision, participant2_deps)
    create_option_category_range_vote_without_deps(decision, participant2_deps)
    create_option_category_weight_without_deps(decision, participant2_deps)
    create_criteria_weight_without_deps(decision, participant2_deps)

    deps |> Map.merge(%{participant1: participant1, participant2: participant2})
  end

  describe "decision => participants query" do
    test "without filter returns all records" do
      %{participant: to_match1, decision: decision} = create_participant()
      %{participant: to_match2} = create_participant(decision)

      to_match1 = to_match1 |> decimals_to_floats()
      to_match2 = to_match2 |> decimals_to_floats()

      assert_list_many_query(
        "participants",
        decision.id,
        %{},
        [to_match1, to_match2],
        fields()
      )
    end

    test "no matching records" do
      decision = create_decision()
      assert_list_none_query("participants", %{decision_id: decision.id}, [:id])
    end

    test "inline records for one Participant" do
      %{decision: decision, participant1: participant} = decision_with_votes()
      query = ~s|
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
                  participantId
                }

                optionCategoryRangeVotes {
                  participantId
                }

                optionCategoryWeights {
                  participantId
                }

                criteriaWeights {
                  participantId
                }
              }
            }
          }

        |

      result_list = evaluate_query_graphql(query, "participants")

      expected = [
        %{
          "id" => "#{participant.id}",
          "binVotes" => [%{"participantId" => "#{participant.id}"}],
          "optionCategoryRangeVotes" => [%{"participantId" => "#{participant.id}"}],
          "optionCategoryWeights" => [%{"participantId" => "#{participant.id}"}],
          "criteriaWeights" => [%{"participantId" => "#{participant.id}"}]
        }
      ]

      assert expected == result_list
    end

    test "inline records for all Participants" do
      %{
        decision: decision,
        participant1: participant1,
        participant2: participant2
      } = decision_with_votes()

      query = ~s|
          {
            decision(
              decisionId: #{decision.id}
            )
            {
              participants{
                id
                binVotes {
                  participantId
                }

                optionCategoryRangeVotes {
                  participantId
                }

                optionCategoryWeights {
                  participantId
                }

                criteriaWeights {
                  participantId
                }
              }
            }
          }

        |

      result_list = evaluate_query_graphql(query, "participants")
      result_list = result_list |> Enum.sort_by(&Map.get(&1, "id"))

      expected =
        [
          %{
            "id" => "#{participant1.id}",
            "binVotes" => [%{"participantId" => "#{participant1.id}"}],
            "optionCategoryRangeVotes" => [%{"participantId" => "#{participant1.id}"}],
            "optionCategoryWeights" => [%{"participantId" => "#{participant1.id}"}],
            "criteriaWeights" => [%{"participantId" => "#{participant1.id}"}]
          },
          %{
            "id" => "#{participant2.id}",
            "binVotes" => [%{"participantId" => "#{participant2.id}"}],
            "optionCategoryRangeVotes" => [%{"participantId" => "#{participant2.id}"}],
            "optionCategoryWeights" => [%{"participantId" => "#{participant2.id}"}],
            "criteriaWeights" => [%{"participantId" => "#{participant2.id}"}]
          }
        ]

      assert expected == result_list
    end
  end

  describe "createParticipant mutation" do
    test "creates with valid data" do
      %{decision: decision} = deps = participant_deps()

      field_names = input_field_names()

      attrs =
        deps |> valid_attrs() |> decimals_to_floats() |> Map.take(field_names)

      requested_fields = Map.keys(attrs) ++ [:id]

      payload = run_mutate_one_query("createParticipant", decision.id, attrs, requested_fields)

      assert_mutation_success(attrs, payload, fields(field_names))
      refute nil == get_in(payload, ["result", "id"])
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = participant_deps()

      invalid = Map.take(invalid_attrs(), [:weighting])
      field_names = input_field_names()

      attrs =
        deps
        |> valid_attrs()
        |> Map.merge(invalid)
        |> decimals_to_floats()
        |> Map.take(field_names)

      requested_fields = Map.keys(attrs) ++ [:id]

      payload = run_mutate_one_query("createParticipant", decision.id, attrs, requested_fields)

      expected = [%ValidationMessage{code: :less_than, field: :weighting}]
      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid Decision returns error" do
      %{decision: decision} = deps = participant_deps()
      delete_decision(decision)

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("createParticipant", decision.id, attrs)

      expected = [%ValidationMessage{code: :not_found, field: "decisionId"}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "updateParticipant mutation" do
    test "updates with valid data" do
      %{decision: decision} = deps = create_participant()

      field_names = input_field_names() ++ [:id]

      attrs =
        deps
        |> valid_attrs()
        |> decimals_to_floats()
        |> Map.take(field_names)

      payload = run_mutate_one_query("updateParticipant", decision.id, attrs)

      assert_mutation_success(attrs, payload, fields(field_names))
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = create_participant()
      invalid = Map.take(invalid_attrs(), [:weighting])

      field_names = [:weighting, :id]
      attrs = deps |> valid_attrs() |> Map.merge(invalid) |> Map.take(field_names)

      payload = run_mutate_one_query("updateParticipant", decision.id, attrs)

      expected = [%ValidationMessage{code: :less_than, field: :weighting}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid Participant returns error" do
      %{participant: to_delete, decision: decision} = deps = create_participant()
      delete_participant(to_delete)

      field_names = [:id, :weighting]
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("updateParticipant", decision.id, attrs)

      expected = [%ValidationMessage{code: "not_found", field: :id}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "deleteParticipant mutation" do
    test "deletes" do
      %{participant: to_delete, decision: decision} = create_participant()
      attrs = to_delete |> Map.take([:id])
      payload = run_mutate_one_query("deleteParticipant", decision.id, attrs)
      assert_mutation_success(%{}, payload, %{})

      assert nil == Voting.get_participant(to_delete.id, decision)
    end
  end
end
