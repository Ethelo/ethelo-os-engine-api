defmodule GraphQL.EtheloApi.Resolvers.OptionCategoryRangeVoteTest do
  @moduledoc """
  Validations and basic access for "OptionCategoryRangeVote" resolver, used to load option_category_range_vote records
  through graphql.
  Note: Functionality is provided through the OptionCategoryRangeVoteResolver.OptionCategoryRangeVote context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Voting.OptionCategoryRangeVoteTest`
  """
  use EtheloApi.DataCase
  @moduletag option_category_range_vote: true, graphql: true

  import EtheloApi.Voting.Factory
  import EtheloApi.Voting.TestHelper.OptionCategoryRangeVoteHelper

  alias EtheloApi.Voting
  alias EtheloApi.Voting.OptionCategoryRangeVote
  alias Ecto.Changeset
  alias GraphQL.EtheloApi.Resolvers.OptionCategoryRangeVote, as: OptionCategoryRangeVoteResolver

  describe "list/2" do

    test "returns records matching a Decision" do
      %{option_category_range_vote: first, decision: decision} = create_option_category_range_vote()
      %{option_category_range_vote: second} = create_option_category_range_vote(decision)

      parent = %{decision: decision}
      args = %{}
      result = OptionCategoryRangeVoteResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionCategoryRangeVote{}, %OptionCategoryRangeVote{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "filters by OptionCategoryRangeVote.participant_id" do
      %{option_category_range_vote: matching, decision: decision} = create_option_category_range_vote()
      create_option_category_range_vote(decision)

      parent = %{decision: decision}
      args = %{participant_id: matching.participant_id}
      result = OptionCategoryRangeVoteResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionCategoryRangeVote{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by OptionCategoryRangeVote.option_category_id" do
      %{option_category_range_vote: matching, decision: decision} = create_option_category_range_vote()
      create_option_category_range_vote(decision)

      parent = %{decision: decision}
      args = %{option_category_id: matching.option_category_id}
      result = OptionCategoryRangeVoteResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionCategoryRangeVote{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by OptionCategoryRangeVote.low_option_id" do
      %{option_category_range_vote: matching, decision: decision} = create_option_category_range_vote()
      create_option_category_range_vote(decision)

      parent = %{decision: decision}
      args = %{low_option_id: matching.low_option_id}
      result = OptionCategoryRangeVoteResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionCategoryRangeVote{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by OptionCategoryRangeVote.high_option_id" do
      %{option_category_range_vote: matching, decision: decision} = create_option_category_range_vote()
      create_option_category_range_vote(decision)

      parent = %{decision: decision}
      args = %{high_option_id: matching.high_option_id}
      result = OptionCategoryRangeVoteResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionCategoryRangeVote{}] = result
      assert_result_ids_match([matching], result)
    end

    test "no OptionCategoryRangeVote matches" do
      decision = create_decision()

      parent = %{decision: decision}
      args = %{}
      result = OptionCategoryRangeVoteResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [] = result
    end
  end

  describe "upsert/2" do
    test "creates with valid data" do
      deps = option_category_range_vote_deps()
      %{decision: decision} = deps

      attrs = deps |> valid_attrs()
      result = OptionCategoryRangeVoteResolver.upsert(decision, attrs)

      assert {:ok, %OptionCategoryRangeVote{} = new_record} = result
      assert attrs.option_category_id == new_record.option_category_id
      assert attrs.high_option_id == new_record.high_option_id
      assert attrs.low_option_id == new_record.low_option_id
      assert attrs.participant_id == new_record.participant_id
    end

    test "returns a list of errors with invalid data" do
      deps = option_category_range_vote_deps()
      %{decision: decision} = deps
      delete_participant(deps.participant)
      delete_option(deps.high_option)
      delete_option(deps.low_option)
      delete_option_category(deps.option_category)

      attrs = deps |> invalid_attrs()
      result = OptionCategoryRangeVoteResolver.upsert(decision, attrs)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> errors_on() |> Map.keys()
      assert :participant_id in errors
      assert :low_option_id in errors
      assert :high_option_id in errors
      assert :option_category_id in errors
      assert [_, _, _, _] = errors
    end

    test "updates with valid data" do
      deps = create_option_category_range_vote()
      %{decision: decision} = deps

      attrs = deps |> valid_attrs()
      result = OptionCategoryRangeVoteResolver.upsert(decision, attrs)

      assert {:ok, %OptionCategoryRangeVote{} = updated} = result
      assert attrs.option_category_id == updated.option_category_id
      assert attrs.high_option_id == updated.high_option_id
      assert attrs.low_option_id == updated.low_option_id
      assert attrs.participant_id == updated.participant_id
    end

    test "deletes" do
      deps = create_option_category_range_vote()
      %{option_category_range_vote: option_category_range_vote, decision: decision} = deps
      second = create_option_category_range_vote(decision)
      %{option_category_range_vote: second_ocrv} = second

      attrs = deps |> valid_attrs() |> Map.put(:delete, true)

      result = OptionCategoryRangeVoteResolver.upsert(decision, attrs)

      assert {:ok, nil} = result
      assert nil == Voting.get_option_category_range_vote(option_category_range_vote.id, decision)
      assert nil !== Voting.get_option_category_range_vote(second_ocrv.id, decision)
    end

  end
end
