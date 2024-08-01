defmodule GraphQL.EtheloApi.AdminSchema.BinVoteTest do
  @moduledoc """
  Test graphql queries for decisions
  """
  use GraphQL.EtheloApi.AdminSchemaCase
  @moduletag bin_vote: true, graphql: true

  alias EtheloApi.Voting
  alias EtheloApi.Voting.BinVote
  import EtheloApi.Voting.Factory

  def fields() do
    %{
     bin: :float,  updated_at: :date, inserted_at: :date, delete: false
    }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  describe "decision => BinVotes query " do
    test "no filter" do
      %{bin_vote: first, decision: decision} = create_bin_vote()
      %{bin_vote: second} = create_bin_vote(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            binVotes{
              id
              bin
              optionId
              criteriaId
              participantId
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "binVotes"])
      assert [_, _] = result
      [first_result, second_result] = result |> Enum.sort_by(&(Map.get(&1, "id")))

      fields = [:bin, :option_id, :criteria_id, :participant_id]
      first = first |> Map.take(fields)
      assert_equivalent_graphql(first, first_result, fields())

      second = second |> Map.take(fields)
      assert_equivalent_graphql(second, second_result, fields())
    end

    test "filter by id" do
      %{bin_vote: matching, decision: decision} = create_bin_vote()
      %{bin_vote: _not_matching} = create_bin_vote(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            binVotes(
              id: #{matching.id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "binVotes"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "filter by OptionId" do
      %{bin_vote: matching, decision: decision} = create_bin_vote()
      %{bin_vote: _not_matching} = create_bin_vote(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            binVotes(
              optionId: #{matching.option_id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "binVotes"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "filter by participantId" do
      %{bin_vote: matching, decision: decision} = create_bin_vote()
      %{bin_vote: _not_matching} = create_bin_vote(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            binVotes(
              participantId: #{matching.participant_id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "binVotes"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "filter by criteriaId" do
      %{bin_vote: matching, decision: decision} = create_bin_vote()
      %{bin_vote: _not_matching} = create_bin_vote(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            binVotes(
              criteriaId: #{matching.criteria_id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "binVotes"])
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
            binVotes{
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "binVotes"])
      assert [] = result
    end
  end
  describe "upsertBinVote mutation" do

    test "create new" do
      %{participant: participant, criteria: criteria, option: option, decision: decision} = bin_vote_deps()
      input = %{
        decision_id: decision.id,
        bin: 1,
        option_id: option.id,
        criteria_id: criteria.id,
        participant_id: participant.id,
      }

      query =
        """
        mutation{
          upsertBinVote(
            input: {
              decisionId: #{input.decision_id}
              bin: #{input.bin},
              criteriaId: #{input.criteria_id}
              optionId: #{input.option_id}
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
              optionId
              participantId
            }
          }
        }
        """

      assert {:ok, %{data: data}} = evaluate_graphql(query)
      assert %{"upsertBinVote" => payload} = data
      assert_mutation_success(input, payload, fields([:title, :slug, :bin]))
      assert %BinVote{} = Voting.get_bin_vote(payload["result"]["id"], decision)
    end

    test "invalid values" do
      %{decision: decision, participant: participant, criteria: criteria, option: option} = bin_vote_deps()
      input = %{
        decision_id: decision.id,
        bin: 90,
        option_id: option.id,
        criteria_id: criteria.id,
        participant_id: participant.id,
      }

      query =
        """
        mutation{
          upsertBinVote(
            input: {
              decisionId: #{input.decision_id}
              bin: #{input.bin},
              criteriaId: #{input.criteria_id}
              optionId: #{input.option_id}
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
              optionId
              participantId
            }
          }
        }
        """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"upsertBinVote" => payload} = data
      expected = [
        %ValidationMessage{code: :less_than_or_equal_to, field: :bin, message: "must be less than or equal to 9"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end

    test "decision not found" do
      %{participant: participant, criteria: criteria, option: option, decision: decision} = bin_vote_deps()
      input = %{
        decision_id: decision.id,
        bin: 1,
        option_id: option.id,
        criteria_id: criteria.id,
        participant_id: participant.id,
      }
      delete_decision(decision)

      query =
        """
        mutation{
          upsertBinVote(
            input: {
              decisionId: #{input.decision_id}
              bin: #{input.bin},
              criteriaId: #{input.criteria_id}
              optionId: #{input.option_id}
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
              optionId
              participantId
            }
          }
        }
        """

      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"upsertBinVote" => payload} = data
      expected = [
        %ValidationMessage{code: :not_found, field: :decisionId, message: "does not exist"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end

    test "upserts" do
      %{bin_vote: bin_vote, decision: decision} = create_bin_vote()
      input = %{
        decision_id: bin_vote.decision_id,
        bin: 1,
        option_id: bin_vote.option_id,
        criteria_id: bin_vote.criteria_id,
        participant_id: bin_vote.participant_id,
      }

      query = """
        mutation{
          upsertBinVote(
            input: {
              decisionId: #{input.decision_id}
              bin: #{input.bin},
              criteriaId: #{input.criteria_id}
              optionId: #{input.option_id}
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
              optionId
              participantId
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"upsertBinVote" => payload} = data
      assert_mutation_success(input, payload, fields())
      assert %BinVote{} = Voting.get_bin_vote(payload["result"]["id"], decision)
    end

    test "deletes" do
      %{bin_vote: bin_vote, decision: decision} = create_bin_vote()
      input = %{
        decision_id: bin_vote.decision_id,
        bin: 10,
        option_id: bin_vote.option_id,
        criteria_id: bin_vote.criteria_id,
        participant_id: bin_vote.participant_id,
      }

      query = """
        mutation{
          upsertBinVote(
            input: {
              decisionId: #{input.decision_id}
              bin: #{input.bin},
              criteriaId: #{input.criteria_id}
              optionId: #{input.option_id}
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
              optionId
              participantId
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"upsertBinVote" => %{"successful" => true}} = data
      assert nil == Voting.get_bin_vote(bin_vote.id, decision)
    end
  end
end
