defmodule GraphQL.EtheloApi.AdminSchema.OptionCategoryRangeVoteTest do
  @moduledoc """
  Test graphql queries for decisions
  """
  use GraphQL.EtheloApi.AdminSchemaCase
  @moduletag option_category_range_vote: true, graphql: true

  alias EtheloApi.Voting
  alias EtheloApi.Voting.OptionCategoryRangeVote
  import EtheloApi.Voting.Factory

  def fields() do
    %{
    updated_at: :date, inserted_at: :date, delete: false
    }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  describe "decision => OptionCategoryRangeVotes query " do
    test "no filter" do
      %{option_category_range_vote: first, decision: decision} = create_option_category_range_vote()
      %{option_category_range_vote: second} = create_option_category_range_vote(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionCategoryRangeVotes{
              id
              optionCategoryId
              highOptionId
              lowOptionId
              participantId
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionCategoryRangeVotes"])
      assert [first_result, second_result] = result

      fields = [:option_category_id, :high_option_id, :low_option_id, :participant_id]
      first = first |> Map.take(fields)
      assert_equivalent_graphql(first, first_result, fields())

      second = second |> Map.take(fields)
      assert_equivalent_graphql(second, second_result, fields())
    end

    test "filter by highOptionId" do
      %{option_category_range_vote: matching, decision: decision} = create_option_category_range_vote()
      %{option_category_range_vote: _not_matching} = create_option_category_range_vote(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionCategoryRangeVotes(
              highOptionId: #{matching.high_option_id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionCategoryRangeVotes"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "filter by lowOptionId" do
      %{option_category_range_vote: matching, decision: decision} = create_option_category_range_vote()
      %{option_category_range_vote: _not_matching} = create_option_category_range_vote(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionCategoryRangeVotes(
              lowOptionId: #{matching.low_option_id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionCategoryRangeVotes"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "filter by participantId" do
      %{option_category_range_vote: matching, decision: decision} = create_option_category_range_vote()
      %{option_category_range_vote: _not_matching} = create_option_category_range_vote(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionCategoryRangeVotes(
              participantId: #{matching.participant_id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionCategoryRangeVotes"])
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
            optionCategoryRangeVotes{
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "optionCategoryRangeVotes"])
      assert [] = result
    end
  end
  describe "upsertOptionCategoryRangeVote mutation" do

    test "create new" do
      deps = option_category_range_vote_deps()
      %{participant: participant, option_category: option_category, decision: decision} = deps
      %{low_option: low_option, high_option: high_option} = deps
      input = %{
        decision_id: decision.id,
        option_category_id: option_category.id,
        high_option_id: high_option.id,
        low_option_id: low_option.id,
        participant_id: participant.id,
      }

      query =
        """
        mutation{
          upsertOptionCategoryRangeVote(
            input: {
              decisionId: #{input.decision_id}
              option_category_id: #{input.option_category_id},
              lowOptionId: #{input.low_option_id}
              highOptionId: #{input.high_option_id}
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
              optionCategoryId
              lowOptionId
              highOptionId
              participantId
            }
          }
        }
        """

      assert {:ok, %{data: data}} = evaluate_graphql(query)
      assert %{"upsertOptionCategoryRangeVote" => payload} = data
      assert_mutation_success(input, payload, fields([:title, :slug, :option_category_id]))
      assert %OptionCategoryRangeVote{} = Voting.get_option_category_range_vote(payload["result"]["id"], decision)
    end

    test "invalid values" do
      deps = option_category_range_vote_deps()
      %{participant: participant} = create_participant()
      %{low_option: low_option, high_option: high_option, decision: decision, option_category: option_category} = deps
      input = %{
        decision_id: decision.id,
        option_category_id: option_category.id,
        high_option_id: high_option.id,
        low_option_id: low_option.id,
        participant_id: participant.id,
      }

      query =
        """
        mutation{
          upsertOptionCategoryRangeVote(
            input: {
              decisionId: #{input.decision_id}
              optionCategoryId: #{input.option_category_id},
              lowOptionId: #{input.low_option_id}
              highOptionId: #{input.high_option_id}
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
              optionCategoryId
              lowOptionId
              highOptionId
              participantId
            }
          }
        }
        """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"upsertOptionCategoryRangeVote" => payload} = data
      expected = [
        %ValidationMessage{code: :foreign, field: :participantId, message: "does not exist"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end

    test "decision not found" do
      deps = option_category_range_vote_deps()
      %{participant: participant, option_category: option_category, decision: decision} = deps
      %{low_option: low_option, high_option: high_option} = deps
      input = %{
        decision_id: decision.id,
        option_category_id: option_category.id,
        high_option_id: high_option.id,
        low_option_id: low_option.id,
        participant_id: participant.id,
      }
      delete_decision(decision)

      query =
        """
        mutation{
          upsertOptionCategoryRangeVote(
            input: {
              decisionId: #{input.decision_id}
              option_category_id: #{input.option_category_id},
              lowOptionId: #{input.low_option_id}
              highOptionId: #{input.high_option_id}
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
              optionCategoryId
              lowOptionId
              highOptionId
              participantId
            }
          }
        }
        """

      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"upsertOptionCategoryRangeVote" => payload} = data
      expected = [
        %ValidationMessage{code: :not_found, field: :decisionId, message: "does not exist"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end

    test "upserts" do
      deps = create_option_category_range_vote()
      %{option_category_range_vote: option_category_range_vote} = deps
      %{option_category: option_category, decision: decision} = deps
      %{option: new_option} = EtheloApi.Structure.Factory.create_option(decision, %{option_category: option_category})

      input = %{
        decision_id: option_category_range_vote.decision_id,
        option_category_id: option_category_range_vote.option_category_id,
        high_option_id: option_category_range_vote.high_option_id,
        low_option_id: new_option.id,
        participant_id: option_category_range_vote.participant_id,
      }

      query = """
        mutation{
          upsertOptionCategoryRangeVote(
            input: {
              decisionId: #{input.decision_id}
              option_category_id: #{input.option_category_id},
              lowOptionId: #{input.low_option_id}
              highOptionId: #{input.high_option_id}
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
              optionCategoryId
              lowOptionId
              highOptionId
              participantId
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"upsertOptionCategoryRangeVote" => payload} = data
      assert_mutation_success(input, payload, fields())
      assert %OptionCategoryRangeVote{} = Voting.get_option_category_range_vote(payload["result"]["id"], decision)
    end

    test "deletes" do

      %{option_category_range_vote: option_category_range_vote, decision: decision} = create_option_category_range_vote()
      input = %{
        decision_id: option_category_range_vote.decision_id,
        option_category_id: option_category_range_vote.option_category_id,
        high_option_id: option_category_range_vote.high_option_id,
        low_option_id: option_category_range_vote.low_option_id,
        participant_id: option_category_range_vote.participant_id,
      }

      query = """
        mutation{
          upsertOptionCategoryRangeVote(
            input: {
              decisionId: #{input.decision_id}
              option_category_id: #{input.option_category_id},
              lowOptionId: #{input.low_option_id}
              highOptionId: #{input.high_option_id}
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
              optionCategoryId
              lowOptionId
              highOptionId
              participantId
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"upsertOptionCategoryRangeVote" => %{"successful" => true}} = data
      assert nil == Voting.get_option_category_range_vote(option_category_range_vote.id, decision)
    end
  end
end
