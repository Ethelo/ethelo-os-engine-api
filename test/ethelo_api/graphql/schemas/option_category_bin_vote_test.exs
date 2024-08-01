defmodule EtheloApi.Graphql.Schemas.OptionCategoryBinVoteTest do
  @moduledoc """
  Test graphql queries for OptionCategoryBinVotes
  """
  use EtheloApi.Graphql.SchemaCase
  @moduletag option_category_bin_vote: true, graphql: true

  alias EtheloApi.Voting
  import EtheloApi.Voting.Factory
  import EtheloApi.Voting.TestHelper.OptionCategoryBinVoteHelper

  describe "decision => OptionCategoryBinVotess query" do
    test "without filter returns all records" do
      %{option_category_bin_vote: to_match1, decision: decision} =
        create_option_category_bin_vote()

      %{option_category_bin_vote: to_match2} = create_option_category_bin_vote(decision)

      %{option_category_bin_vote: _excluded} = create_option_category_bin_vote()

      assert_list_many_query(
        "optionCategoryBinVotes",
        decision.id,
        %{},
        [to_match1, to_match2],
        fields()
      )
    end

    test "filters by option_category_id" do
      %{option_category_bin_vote: to_match, decision: decision} =
        create_option_category_bin_vote()

      %{option_category_bin_vote: _excluded} = create_option_category_bin_vote(decision)

      assert_list_one_query(
        "optionCategoryBinVotes",
        to_match,
        [:option_category_id],
        fields([:option_category_id])
      )
    end

    test "filters by criteria_id" do
      %{option_category_bin_vote: to_match, decision: decision} =
        create_option_category_bin_vote()

      %{option_category_bin_vote: _excluded} = create_option_category_bin_vote(decision)

      assert_list_one_query(
        "optionCategoryBinVotes",
        to_match,
        [:option_category_id],
        fields([:option_category_id])
      )
    end

    test "filters by participant_id" do
      %{option_category_bin_vote: to_match, decision: decision} =
        create_option_category_bin_vote()

      %{option_category_bin_vote: _excluded} = create_option_category_bin_vote(decision)

      assert_list_one_query(
        "optionCategoryBinVotes",
        to_match,
        [:participant_id],
        fields([:participant_id])
      )
    end

    test "no matching records" do
      decision = create_decision()
      assert_list_none_query("optionCategoryBinVotes", %{decision_id: decision.id}, [:id])
    end
  end

  describe "upsertOptionCategoryBinVote mutation" do
    test "creates with valid data" do
      %{decision: decision} = deps = option_category_bin_vote_deps()

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload =
        run_mutate_one_query("upsertOptionCategoryBinVote", decision.id, attrs)

      assert_mutation_success(attrs, payload, fields(field_names))
    end

    test "upserts with valid data" do
      %{decision: decision} = deps = create_option_category_bin_vote()

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload =
        run_mutate_one_query("upsertOptionCategoryBinVote", decision.id, attrs)

      assert_mutation_success(attrs, payload, fields(field_names))
    end

    test "invalid data returns errors" do
      %{decision: decision} = deps = option_category_bin_vote_deps()

      field_names = input_field_names()
      attrs = deps |> invalid_attrs() |> Map.take(field_names)

      payload =
        run_mutate_one_query("upsertOptionCategoryBinVote", decision.id, attrs)

      expected = [%ValidationMessage{code: :less_than_or_equal_to, field: :bin}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid Decision returns error" do
      %{decision: decision} = deps = option_category_bin_vote_deps()

      delete_decision(decision)

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload =
        run_mutate_one_query("upsertOptionCategoryBinVote", decision.id, attrs)

      expected = [%ValidationMessage{code: :not_found, field: "decisionId"}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "deletes" do
      %{option_category_bin_vote: to_delete, decision: decision} =
        deps = create_option_category_bin_vote()

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names) |> Map.put(:delete, true)

      payload =
        run_mutate_one_query("upsertOptionCategoryBinVote", decision.id, attrs, field_names)

      assert %{"successful" => true} = payload
      assert nil == payload["result"]

      assert nil == Voting.get_option_category_bin_vote(to_delete.id, decision)
    end
  end
end
