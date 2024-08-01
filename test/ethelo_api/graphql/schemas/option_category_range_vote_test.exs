defmodule EtheloApi.Graphql.Schemas.OptionCategoryRangeVoteTest do
  @moduledoc """
  Test graphql queries for OptionCategoryRangeVotes
  """
  use EtheloApi.Graphql.SchemaCase
  @moduletag option_category_range_vote: true, graphql: true

  alias EtheloApi.Voting
  import EtheloApi.Voting.Factory
  import EtheloApi.Voting.TestHelper.OptionCategoryRangeVoteHelper

  describe "decision => optionCategoryRangeVotes query" do
    test "without filter returns all records" do
      %{option_category_range_vote: to_match1, decision: decision} =
        create_option_category_range_vote()

      %{option_category_range_vote: to_match2} = create_option_category_range_vote(decision)
      %{option_category_range_vote: _excluded} = create_option_category_range_vote()

      assert_list_many_query(
        "optionCategoryRangeVotes",
        decision.id,
        %{},
        [to_match1, to_match2],
        fields()
      )
    end

    test "filters by high_option_id" do
      %{option_category_range_vote: to_match, decision: decision} =
        create_option_category_range_vote()

      %{option_category_range_vote: _excluded} = create_option_category_range_vote(decision)

      assert_list_one_query(
        "optionCategoryRangeVotes",
        to_match,
        [:high_option_id],
        fields([:high_option_id])
      )
    end

    test "filters by low_option_id" do
      %{option_category_range_vote: to_match, decision: decision} =
        create_option_category_range_vote()

      %{option_category_range_vote: _excluded} = create_option_category_range_vote(decision)

      assert_list_one_query(
        "optionCategoryRangeVotes",
        to_match,
        [:low_option_id],
        fields([:low_option_id])
      )
    end

    test "filters by option_category_id" do
      %{option_category_range_vote: to_match, decision: decision} =
        create_option_category_range_vote()

      %{option_category_range_vote: _excluded} = create_option_category_range_vote(decision)

      assert_list_one_query(
        "optionCategoryRangeVotes",
        to_match,
        [:option_category_id],
        fields([:option_category_id])
      )
    end

    test "filters by participant_id" do
      %{option_category_range_vote: to_match, decision: decision} =
        create_option_category_range_vote()

      %{option_category_range_vote: _excluded} = create_option_category_range_vote(decision)

      assert_list_one_query(
        "optionCategoryRangeVotes",
        to_match,
        [:participant_id],
        fields([:participant_id])
      )
    end

    test "no matching records" do
      decision = create_decision()
      assert_list_none_query("optionCategoryRangeVotes", %{decision_id: decision.id}, [:id])
    end
  end

  describe "upsertOptionCategoryRangeVote mutation" do
    test "creates with valid data" do
      %{decision: decision} = deps = option_category_range_vote_deps()

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload =
        run_mutate_one_query("upsertOptionCategoryRangeVote", decision.id, attrs)

      assert_mutation_success(attrs, payload, fields(field_names))
    end

    test "upserts with valid data" do
      %{decision: decision, option_category: option_category} =
        deps = create_option_category_range_vote()

      %{option: new_option} =
        EtheloApi.Structure.Factory.create_option(decision, %{option_category: option_category})

      field_names = input_field_names()

      attrs =
        deps |> valid_attrs() |> Map.put(:low_option_id, new_option.id) |> Map.take(field_names)

      payload =
        run_mutate_one_query("upsertOptionCategoryRangeVote", decision.id, attrs)

      assert_mutation_success(attrs, payload, fields(field_names))
    end

    test "invalid Participant returns errors" do
      %{decision: decision} = deps = option_category_range_vote_deps()
      %{participant: participant} = create_participant()

      field_names = input_field_names()

      attrs =
        deps
        |> valid_attrs()
        |> Map.put(:participant_id, participant.id)
        |> Map.take(field_names)

      payload =
        run_mutate_one_query("upsertOptionCategoryRangeVote", decision.id, attrs)

      expected = [%ValidationMessage{code: :foreign, field: :participantId}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid Decision returns error" do
      %{decision: decision} = deps = option_category_range_vote_deps()

      delete_decision(decision)

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload =
        run_mutate_one_query("upsertOptionCategoryRangeVote", decision.id, attrs)

      expected = [%ValidationMessage{code: :not_found, field: "decisionId"}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "deletes" do
      %{option_category_range_vote: to_delete, decision: decision} =
        deps = create_option_category_range_vote()

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names) |> Map.put(:delete, true)

      payload =
        run_mutate_one_query("upsertOptionCategoryRangeVote", decision.id, attrs, field_names)

      assert %{"successful" => true} = payload
      assert nil == payload["result"]

      assert nil == Voting.get_option_category_range_vote(to_delete.id, decision)
    end
  end
end
