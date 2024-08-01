defmodule EtheloApi.Graphql.Resolvers.BinVoteTest do
  @moduledoc """
  Validations and basic access for BinVote resolver
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
  alias EtheloApi.Graphql.Resolvers.BinVote, as: BinVoteResolver

  def test_list_filtering(field_name) do
    %{bin_vote: to_match, decision: decision} = create_bin_vote()
    %{bin_vote: _excluded} = create_bin_vote(decision)
    test_list_filtering(field_name, to_match, decision)
  end

  def test_list_filtering(field_name, to_match, decision) do
    parent = %{decision: decision}
    args = %{} |> Map.put(field_name, Map.get(to_match, field_name))
    result = BinVoteResolver.list(parent, args, nil)
    assert {:ok, result} = result
    assert [%BinVote{}] = result
    assert_result_ids_match([to_match], result)
  end

  describe "list/2" do
    test "filters by decision_id" do
      %{bin_vote: to_match1, decision: decision} = create_bin_vote()
      %{bin_vote: to_match2} = create_bin_vote(decision)

      parent = %{decision: decision}
      args = %{}
      result = BinVoteResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%BinVote{}, %BinVote{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "filters by id" do
      test_list_filtering(:id)
    end

    test "filters by participant_id" do
      test_list_filtering(:participant_id)
    end

    test "filters by criteria_id" do
      test_list_filtering(:criteria_id)
    end

    test "filters by option_id" do
      test_list_filtering(:option_id)
    end

    test "no matching records" do
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
      %{decision: decision} = deps = bin_vote_deps()

      attrs = deps |> valid_attrs()
      params = to_graphql_input_params(attrs, decision)
      result = BinVoteResolver.upsert(params, nil)

      assert {:ok, %BinVote{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "updates with valid data" do
      %{decision: decision} = deps = bin_vote_deps()
      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)
      result = BinVoteResolver.upsert(params, nil)

      assert {:ok, %BinVote{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "invalid field returns changeset" do
      %{decision: decision} = deps = bin_vote_deps()
      delete_participant(deps.participant)

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = BinVoteResolver.upsert(params, nil)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> error_map()

      expected = [:participant_id]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "deletes" do
      %{bin_vote: to_delete, decision: decision} = deps = create_bin_vote()
      attrs = deps |> valid_attrs() |> Map.put(:delete, true)
      params = to_graphql_input_params(attrs, decision)

      result = BinVoteResolver.upsert(params, nil)

      assert {:ok, nil} = result
      assert nil == Voting.get_bin_vote(to_delete.id, decision)
    end
  end
end
