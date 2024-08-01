defmodule EtheloApi.Graphql.Resolvers.OptionCategoryBinVoteTest do
  @moduledoc """
  Validations and basic access for OptionCategoryBinVote resolver
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
  alias EtheloApi.Graphql.Resolvers.OptionCategoryBinVote, as: OptionCategoryBinVoteResolver

  def test_list_filtering(field_name) do
    %{option_category_bin_vote: to_match, decision: decision} = create_option_category_bin_vote()
    %{option_category_bin_vote: _excluded} = create_option_category_bin_vote(decision)
    test_list_filtering(field_name, to_match, decision)
  end

  def test_list_filtering(field_name, to_match, decision) do
    parent = %{decision: decision}
    args = %{} |> Map.put(field_name, Map.get(to_match, field_name))
    result = OptionCategoryBinVoteResolver.list(parent, args, nil)
    assert {:ok, result} = result
    assert [%OptionCategoryBinVote{}] = result
    assert_result_ids_match([to_match], result)
  end

  describe "list/2" do
    test "filters by decision_id" do
      %{option_category_bin_vote: to_match1, decision: decision} =
        create_option_category_bin_vote()

      %{option_category_bin_vote: to_match2} = create_option_category_bin_vote(decision)

      parent = %{decision: decision}
      args = %{}
      result = OptionCategoryBinVoteResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionCategoryBinVote{}, %OptionCategoryBinVote{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "filters by participant_id" do
      test_list_filtering(:participant_id)
    end

    test "filters by criteria_id" do
      test_list_filtering(:criteria_id)
    end

    test "filters by option_category_id" do
      test_list_filtering(:option_category_id)
    end

    test "no matching records" do
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
      %{decision: decision} = deps = option_category_bin_vote_deps()

      attrs = deps |> valid_attrs()
      params = to_graphql_input_params(attrs, decision)

      result = OptionCategoryBinVoteResolver.upsert(params, nil)
      assert {:ok, %OptionCategoryBinVote{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "invalid data returns changeset" do
      %{decision: decision} = deps = option_category_bin_vote_deps()
      delete_participant(deps.participant)
      delete_option_category(deps.option_category)
      delete_criteria(deps.criteria)

      attrs = deps |> invalid_attrs()
      params = to_graphql_input_params(attrs, decision)
      result = OptionCategoryBinVoteResolver.upsert(params, nil)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> error_map()
      expected = [:bin, :option_category_id, :criteria_id, :participant_id]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "updates with valid data" do
      %{decision: decision} = deps = create_option_category_bin_vote()

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = OptionCategoryBinVoteResolver.upsert(params, nil)
      assert {:ok, %OptionCategoryBinVote{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "deletes" do
      %{option_category_bin_vote: to_delete, decision: decision} =
        deps = create_option_category_bin_vote()

      attrs = deps |> valid_attrs() |> Map.put(:delete, true)
      params = to_graphql_input_params(attrs, decision)

      result = OptionCategoryBinVoteResolver.upsert(params, nil)

      assert {:ok, nil} = result
      assert nil == Voting.get_option_category_bin_vote(to_delete.id, decision)
    end
  end
end
