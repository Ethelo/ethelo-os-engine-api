defmodule EtheloApi.Graphql.Schemas.BinVoteTest do
  @moduledoc """
  Test graphql queries for BinVotes
  """
  use EtheloApi.Graphql.SchemaCase
  @moduletag bin_vote: true, graphql: true

  alias EtheloApi.Voting
  alias AbsintheErrorPayload.ValidationMessage
  import EtheloApi.Voting.Factory
  import EtheloApi.Voting.TestHelper.BinVoteHelper

  describe "decision => binVotes query" do
    test "without filter returns all records" do
      %{bin_vote: to_match1, decision: decision} = create_bin_vote()
      %{bin_vote: to_match2} = create_bin_vote(decision)
      %{bin_vote: _excluded} = create_bin_vote()

      assert_list_many_query("binVotes", decision.id, %{}, [to_match1, to_match2], fields())
    end

    test "filters by option_id" do
      %{bin_vote: to_match, decision: decision} = create_bin_vote()
      %{bin_vote: _excluded} = create_bin_vote(decision)

      assert_list_one_query("binVotes", to_match, [:option_id], fields([:option_id]))
    end

    test "filters by criteria_id" do
      %{bin_vote: to_match, decision: decision} = create_bin_vote()
      %{bin_vote: _excluded} = create_bin_vote(decision)

      assert_list_one_query("binVotes", to_match, [:criteria_id], fields([:criteria_id]))
    end

    test "filters by participant_id" do
      %{bin_vote: to_match, decision: decision} = create_bin_vote()
      %{bin_vote: _excluded} = create_bin_vote(decision)

      assert_list_one_query("binVotes", to_match, [:participant_id], fields([:participant_id]))
    end

    test "no matching records" do
      decision = create_decision()
      assert_list_none_query("binVotes", %{decision_id: decision.id}, [:id])
    end
  end

  describe "upsertBinVote mutation" do
    test "creates with valid data" do
      %{decision: decision} = deps = bin_vote_deps()

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("upsertBinVote", decision.id, attrs)

      assert_mutation_success(attrs, payload, fields(field_names))
    end

    test "updates with valid data" do
      %{decision: decision} = deps = create_bin_vote()

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("upsertBinVote", decision.id, attrs)

      assert_mutation_success(attrs, payload, fields(field_names))
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = bin_vote_deps()

      field_names = input_field_names()
      attrs = deps |> invalid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("upsertBinVote", decision.id, attrs)

      expected = [%ValidationMessage{code: :less_than_or_equal_to, field: :bin}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid Decision returns error" do
      %{decision: decision} = deps = bin_vote_deps()

      delete_decision(decision)

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("upsertBinVote", decision.id, attrs)

      expected = [%ValidationMessage{code: :not_found, field: "decisionId"}]
      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "deletes" do
      %{bin_vote: to_delete, decision: decision} = deps = create_bin_vote()

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names) |> Map.put(:delete, true)

      payload = run_mutate_one_query("upsertBinVote", decision.id, attrs, field_names)

      assert %{"successful" => true} = payload
      assert nil == payload["result"]
      assert nil == Voting.get_bin_vote(to_delete.id, decision)
    end
  end
end
