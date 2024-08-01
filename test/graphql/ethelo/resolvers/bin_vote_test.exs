defmodule GraphQL.EtheloApi.Resolvers.BinVoteTest do
  @moduledoc """
  Validations and basic access for "BinVote" resolver, used to load bin_vote records
  through graphql.
  Note: Functionality is provided through the BinVoteResolver.BinVote context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Voting.BinVoteTest`
  """
  use EtheloApi.DataCase
  @moduletag bin_vote: true, graphql: true

  import EtheloApi.Voting.Factory
  import EtheloApi.Voting.TestHelper.BinVoteHelper

  alias EtheloApi.Voting
  alias EtheloApi.Voting.BinVote
  alias Ecto.Changeset
  alias GraphQL.EtheloApi.Resolvers.BinVote, as: BinVoteResolver

  describe "list/2" do

    test "returns records matching a Decision" do
      %{bin_vote: first, decision: decision} = create_bin_vote()
      %{bin_vote: second} = create_bin_vote(decision)

      parent = %{decision: decision}
      args = %{}
      result = BinVoteResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%BinVote{}, %BinVote{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "filters by BinVote.id" do
      %{bin_vote: matching, decision: decision} = create_bin_vote()
      create_bin_vote(decision)

      parent = %{decision: decision}
      args = %{id: matching.id}
      result = BinVoteResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%BinVote{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by BinVote.participant_id" do
      %{bin_vote: matching, decision: decision} = create_bin_vote()
      create_bin_vote(decision)

      parent = %{decision: decision}
      args = %{participant_id: matching.participant_id}
      result = BinVoteResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%BinVote{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by BinVote.criteria_id" do
      %{bin_vote: matching, decision: decision} = create_bin_vote()
      create_bin_vote(decision)

      parent = %{decision: decision}
      args = %{criteria_id: matching.criteria_id}
      result = BinVoteResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%BinVote{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by BinVote.option_id" do
      %{bin_vote: matching, decision: decision} = create_bin_vote()
      create_bin_vote(decision)

      parent = %{decision: decision}
      args = %{option_id: matching.option_id}
      result = BinVoteResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%BinVote{}] = result
      assert_result_ids_match([matching], result)
    end

    test "no BinVote matches" do
      decision = create_decision()

      parent = %{decision: decision}
      args = %{}
      result = BinVoteResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [] = result
    end
  end

  describe "upsert/2" do
    test "creates with valid data" do
      deps = bin_vote_deps()
      %{decision: decision} = deps

      attrs = deps |> valid_attrs()
      result = BinVoteResolver.upsert(decision, attrs)

      assert {:ok, %BinVote{} = new_record} = result
      assert attrs.bin == new_record.bin
      assert attrs.option_id == new_record.option_id
      assert attrs.criteria_id == new_record.criteria_id
      assert attrs.participant_id == new_record.participant_id
    end

    test "returns a list of errors with invalid data" do
      deps = bin_vote_deps()
      %{decision: decision} = deps
      delete_participant(deps.participant)
      delete_option(deps.option)
      delete_criteria(deps.criteria)

      attrs = deps |> invalid_attrs()
      result = BinVoteResolver.upsert(decision, attrs)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> errors_on() |> Map.keys()
      assert :participant_id in errors
      assert :criteria_id in errors
      assert :option_id in errors
      assert :bin in errors
      assert [_, _, _, _,] = errors
    end

    test "updates with valid data" do
      deps = create_bin_vote()
      %{decision: decision} = deps

      attrs = deps |> valid_attrs()
      result = BinVoteResolver.upsert(decision, attrs)

      assert {:ok, %BinVote{} = updated} = result
      assert attrs.bin == updated.bin
      assert attrs.option_id == updated.option_id
      assert attrs.criteria_id == updated.criteria_id
      assert attrs.participant_id == updated.participant_id
    end

    test "deletes" do
      deps = create_bin_vote()
      %{bin_vote: bin_vote, decision: decision} = deps

      attrs = deps |> valid_attrs() |> Map.put(:delete, true)

      result = BinVoteResolver.upsert(decision, attrs)

      assert {:ok, nil} = result
      assert nil == Voting.get_bin_vote(bin_vote.id, decision)
    end

  end
end
