defmodule GraphQL.EtheloApi.Resolvers.OptionCategoryBinVoteTest do
  @moduledoc """
  Validations and basic access for "OptionCategoryBinVote" resolver, used to load option_category_bin_vote records
  through graphql.
  Note: Functionality is provided through the OptionCategoryBinVoteResolver.OptionCategoryBinVote context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Voting.OptionCategoryBinVoteTest`
  """
  use EtheloApi.DataCase
  @moduletag option_category_bin_vote: true, graphql: true

  import EtheloApi.Voting.Factory
  import EtheloApi.Voting.TestHelper.OptionCategoryBinVoteHelper

  alias EtheloApi.Voting
  alias EtheloApi.Voting.OptionCategoryBinVote
  alias Ecto.Changeset
  alias GraphQL.EtheloApi.Resolvers.OptionCategoryBinVote, as: OptionCategoryBinVoteResolver

  describe "list/2" do

    test "returns records matching a Decision" do
      %{option_category_bin_vote: first, decision: decision} = create_option_category_bin_vote()
      %{option_category_bin_vote: second} = create_option_category_bin_vote(decision)

      parent = %{decision: decision}
      args = %{}
      result = OptionCategoryBinVoteResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionCategoryBinVote{}, %OptionCategoryBinVote{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "filters by OptionCategoryBinVote.participant_id" do
      %{option_category_bin_vote: matching, decision: decision} = create_option_category_bin_vote()
      create_option_category_bin_vote(decision)

      parent = %{decision: decision}
      args = %{participant_id: matching.participant_id}
      result = OptionCategoryBinVoteResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionCategoryBinVote{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by OptionCategoryBinVote.criteria_id" do
      %{option_category_bin_vote: matching, decision: decision} = create_option_category_bin_vote()
      create_option_category_bin_vote(decision)

      parent = %{decision: decision}
      args = %{criteria_id: matching.criteria_id}
      result = OptionCategoryBinVoteResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionCategoryBinVote{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by OptionCategoryBinVote.option_category_id" do
      %{option_category_bin_vote: matching, decision: decision} = create_option_category_bin_vote()
      create_option_category_bin_vote(decision)

      parent = %{decision: decision}
      args = %{option_category_id: matching.option_category_id}
      result = OptionCategoryBinVoteResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionCategoryBinVote{}] = result
      assert_result_ids_match([matching], result)
    end

    test "no OptionCategoryBinVote matches" do
      decision = create_decision()

      parent = %{decision: decision}
      args = %{}
      result = OptionCategoryBinVoteResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [] = result
    end
  end

  describe "upsert/2" do
    test "creates with valid data" do
      deps = option_category_bin_vote_deps()
      %{decision: decision} = deps

      attrs = deps |> valid_attrs()
      result = OptionCategoryBinVoteResolver.upsert(decision, attrs)

      assert {:ok, %OptionCategoryBinVote{} = new_record} = result
      assert attrs.bin == new_record.bin
      assert attrs.option_category_id == new_record.option_category_id
      assert attrs.criteria_id == new_record.criteria_id
      assert attrs.participant_id == new_record.participant_id
    end

    test "returns a list of errors with invalid data" do
      deps = option_category_bin_vote_deps()
      %{decision: decision} = deps
      delete_participant(deps.participant)
      delete_option_category(deps.option_category)
      delete_criteria(deps.criteria)

      attrs = deps |> invalid_attrs()
      result = OptionCategoryBinVoteResolver.upsert(decision, attrs)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> errors_on() |> Map.keys()
      assert :participant_id in errors
      assert :criteria_id in errors
      assert :option_category_id in errors
      assert :bin in errors
      assert [_, _, _, _,] = errors
    end

    test "updates with valid data" do
      deps = create_option_category_bin_vote()
      %{decision: decision} = deps

      attrs = deps |> valid_attrs()
      result = OptionCategoryBinVoteResolver.upsert(decision, attrs)

      assert {:ok, %OptionCategoryBinVote{} = updated} = result
      assert attrs.bin == updated.bin
      assert attrs.option_category_id == updated.option_category_id
      assert attrs.criteria_id == updated.criteria_id
      assert attrs.participant_id == updated.participant_id
    end

    test "deletes" do
      deps = create_option_category_bin_vote()
      %{option_category_bin_vote: option_category_bin_vote, decision: decision} = deps

      attrs = deps |> valid_attrs() |> Map.put(:delete, true)

      result = OptionCategoryBinVoteResolver.upsert(decision, attrs)

      assert {:ok, nil} = result
      assert nil == Voting.get_option_category_bin_vote(option_category_bin_vote.id, decision)
    end

  end
end
