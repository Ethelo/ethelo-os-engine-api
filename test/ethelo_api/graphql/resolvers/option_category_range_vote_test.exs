defmodule EtheloApi.Graphql.Resolvers.OptionCategoryRangeVoteTest do
  @moduledoc """
  Validations and basic access for OptionCategoryRangeVote resolver
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
  alias EtheloApi.Graphql.Resolvers.OptionCategoryRangeVote, as: OptionCategoryRangeVoteResolver

  def test_list_filtering(field_name) do
    %{option_category_range_vote: to_match, decision: decision} =
      create_option_category_range_vote()

    %{option_category_range_vote: _excluded} = create_option_category_range_vote(decision)
    test_list_filtering(field_name, to_match, decision)
  end

  def test_list_filtering(field_name, to_match, decision) do
    parent = %{decision: decision}
    args = %{} |> Map.put(field_name, Map.get(to_match, field_name))
    result = OptionCategoryRangeVoteResolver.list(parent, args, nil)
    assert {:ok, result} = result
    assert [%OptionCategoryRangeVote{}] = result
    assert_result_ids_match([to_match], result)
  end

  describe "list/2" do
    test "filters by decision_id" do
      %{option_category_range_vote: to_match1, decision: decision} =
        create_option_category_range_vote()

      %{option_category_range_vote: to_match2} = create_option_category_range_vote(decision)

      parent = %{decision: decision}
      args = %{}
      result = OptionCategoryRangeVoteResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionCategoryRangeVote{}, %OptionCategoryRangeVote{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "filters by participant_id" do
      test_list_filtering(:participant_id)
    end

    test "filters by option_category_id" do
      test_list_filtering(:option_category_id)
    end

    test "filters by low_option_id" do
      test_list_filtering(:low_option_id)
    end

    test "filters by high_option_id" do
      test_list_filtering(:high_option_id)
    end

    test "no matching records" do
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
      %{decision: decision} = deps = option_category_range_vote_deps()

      attrs = deps |> valid_attrs()
      params = to_graphql_input_params(attrs, decision)

      result = OptionCategoryRangeVoteResolver.upsert(params, nil)
      assert {:ok, %OptionCategoryRangeVote{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "invalid data returns changeset" do
      %{decision: decision} = deps = option_category_range_vote_deps()
      delete_participant(deps.participant)
      delete_option(deps.high_option)
      delete_option(deps.low_option)
      delete_option_category(deps.option_category)

      attrs = deps |> invalid_attrs()
      params = to_graphql_input_params(attrs, decision)
      result = OptionCategoryRangeVoteResolver.upsert(params, nil)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> error_map()
      expected = [:low_option_id, :high_option_id, :option_category_id, :participant_id]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "updates with valid data" do
      %{decision: decision} = deps = create_option_category_range_vote()

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = OptionCategoryRangeVoteResolver.upsert(params, nil)
      assert {:ok, %OptionCategoryRangeVote{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "deletes" do
      %{option_category_range_vote: to_delete, decision: decision} =
        deps = create_option_category_range_vote()

      %{option_category_range_vote: to_keep} = create_option_category_range_vote(decision)

      attrs = deps |> valid_attrs() |> Map.put(:delete, true)
      params = to_graphql_input_params(attrs, decision)

      result = OptionCategoryRangeVoteResolver.upsert(params, nil)

      assert {:ok, nil} = result
      assert nil == Voting.get_option_category_range_vote(to_delete.id, decision)
      assert nil !== Voting.get_option_category_range_vote(to_keep.id, decision)
    end
  end
end
