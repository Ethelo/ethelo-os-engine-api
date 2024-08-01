defmodule GraphQL.EtheloApi.AdminSchema.OptionCategoryBinVoteTest do
  @moduledoc """
  Test graphql queries for decisions
  """
  use GraphQL.EtheloApi.AdminSchemaCase
  @moduletag option_category_bin_vote: true, graphql: true

  alias EtheloApi.Voting
  alias EtheloApi.Voting.OptionCategoryBinVote
  import EtheloApi.Voting.Factory

  def fields() do
    %{
     bin: :integer,  updated_at: :date, inserted_at: :date, delete: false
    }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  describe "decision => OptionCategoryBinVotess query " do
    test "no filter" do
      %{option_category_bin_vote: first, decision: decision} = create_option_category_bin_vote()
      %{option_category_bin_vote: second} = create_option_category_bin_vote(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionCategoryBinVotes{
              id
              bin
              optionCategoryId
              criteriaId
              participantId
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionCategoryBinVotes"])
      assert [first_result, second_result] = result

      fields = [:bin, :option_category_id, :criteria_id, :participant_id]
      first = first |> Map.take(fields)
      assert_equivalent_graphql(first, first_result, fields())

      second = second |> Map.take(fields)
      assert_equivalent_graphql(second, second_result, fields())
    end

    test "filter by OptionCategoryId" do
      %{option_category_bin_vote: matching, decision: decision} = create_option_category_bin_vote()
      %{option_category_bin_vote: _not_matching} = create_option_category_bin_vote(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionCategoryBinVotes(
              optionCategoryId: #{matching.option_category_id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionCategoryBinVotes"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "filter by participantId" do
      %{option_category_bin_vote: matching, decision: decision} = create_option_category_bin_vote()
      %{option_category_bin_vote: _not_matching} = create_option_category_bin_vote(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionCategoryBinVotes(
              participantId: #{matching.participant_id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionCategoryBinVotes"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "filter by criteriaId" do
      %{option_category_bin_vote: matching, decision: decision} = create_option_category_bin_vote()
      %{option_category_bin_vote: _not_matching} = create_option_category_bin_vote(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionCategoryBinVotes(
              criteriaId: #{matching.criteria_id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionCategoryBinVotes"])
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
            optionCategoryBinVotes{
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionCategoryBinVotes"])
      assert [] = result
    end
  end
  describe "upsertOptionCategoryBinVote mutation" do

    test "create new" do
      %{participant: participant, criteria: criteria, option_category: option_category, decision: decision} = option_category_bin_vote_deps()
      input = %{
        decision_id: decision.id,
        bin: 1,
        option_category_id: option_category.id,
        criteria_id: criteria.id,
        participant_id: participant.id,
      }

      query =
        """
        mutation{
          upsertOptionCategoryBinVote(
            input: {
              decisionId: #{input.decision_id}
              bin: #{input.bin},
              criteriaId: #{input.criteria_id}
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
              bin
              criteriaId
              optionCategoryId
              participantId
            }
          }
        }
        """

      assert {:ok, %{data: data}} = evaluate_graphql(query)
      assert %{"upsertOptionCategoryBinVote" => payload} = data
      assert_mutation_success(input, payload, fields([:title, :slug, :bin]))
      assert %OptionCategoryBinVote{} = Voting.get_option_category_bin_vote(payload["result"]["id"], decision)
    end

    test "invalid values" do
      %{decision: decision, participant: participant, criteria: criteria, option_category: option_category} = option_category_bin_vote_deps()
      input = %{
        decision_id: decision.id,
        bin: 90,
        option_category_id: option_category.id,
        criteria_id: criteria.id,
        participant_id: participant.id,
      }

      query =
        """
        mutation{
          upsertOptionCategoryBinVote(
            input: {
              decisionId: #{input.decision_id}
              bin: #{input.bin},
              criteriaId: #{input.criteria_id}
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
              bin
              criteriaId
              optionCategoryId
              participantId
            }
          }
        }
        """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"upsertOptionCategoryBinVote" => payload} = data
      expected = [
        %ValidationMessage{code: :less_than_or_equal_to, field: :bin, message: "must be less than or equal to 9"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end

    test "decision not found" do
      %{participant: participant, criteria: criteria, option_category: option_category, decision: decision} = option_category_bin_vote_deps()
      input = %{
        decision_id: decision.id,
        bin: 1,
        option_category_id: option_category.id,
        criteria_id: criteria.id,
        participant_id: participant.id,
      }
      delete_decision(decision)

      query =
        """
        mutation{
          upsertOptionCategoryBinVote(
            input: {
              decisionId: #{input.decision_id}
              bin: #{input.bin},
              criteriaId: #{input.criteria_id}
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
              bin
              criteriaId
              optionCategoryId
              participantId
            }
          }
        }
        """

      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"upsertOptionCategoryBinVote" => payload} = data
      expected = [
        %ValidationMessage{code: :not_found, field: :decisionId, message: "does not exist"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end

    test "upserts" do
      %{option_category_bin_vote: bin_vote, decision: decision} = create_option_category_bin_vote()
      input = %{
        decision_id: bin_vote.decision_id,
        bin: 1,
        option_category_id: bin_vote.option_category_id,
        criteria_id: bin_vote.criteria_id,
        participant_id: bin_vote.participant_id,
      }

      query = """
        mutation{
          upsertOptionCategoryBinVote(
            input: {
              decisionId: #{input.decision_id}
              bin: #{input.bin},
              criteriaId: #{input.criteria_id}
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
              bin
              criteriaId
              optionCategoryId
              participantId
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"upsertOptionCategoryBinVote" => payload} = data
      assert_mutation_success(input, payload, fields())
      assert %OptionCategoryBinVote{} = Voting.get_option_category_bin_vote(payload["result"]["id"], decision)
    end

    test "deletes" do
      %{option_category_bin_vote: bin_vote, decision: decision} = create_option_category_bin_vote()
      input = %{
        decision_id: bin_vote.decision_id,
        bin: 10,
        option_category_id: bin_vote.option_category_id,
        criteria_id: bin_vote.criteria_id,
        participant_id: bin_vote.participant_id,
      }

      query = """
        mutation{
          upsertOptionCategoryBinVote(
            input: {
              decisionId: #{input.decision_id}
              bin: #{input.bin},
              criteriaId: #{input.criteria_id}
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
              bin
              criteriaId
              optionCategoryId
              participantId
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"upsertOptionCategoryBinVote" => %{"successful" => true}} = data
      assert nil == Voting.get_bin_vote(bin_vote.id, decision)
    end
  end
end
