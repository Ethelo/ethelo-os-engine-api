defmodule EtheloApi.Graphql.Schemas.OptionCategoryWeightTest do
  @moduledoc """
  Test graphql queries for OptionCategoryWeights
  """
  use EtheloApi.Graphql.SchemaCase
  @moduletag option_category_weight: true, graphql: true

  alias EtheloApi.Voting
  alias AbsintheErrorPayload.ValidationMessage
  import EtheloApi.Voting.Factory
  import EtheloApi.Voting.TestHelper.OptionCategoryWeightHelper

  describe "decision => binVotes query" do
    test "without filter returns all records" do
      %{option_category_weight: to_match1, decision: decision} = create_option_category_weight()
      %{option_category_weight: to_match2} = create_option_category_weight(decision)
      %{option_category_weight: _excluded} = create_option_category_weight()

      assert_list_many_query(
        "optionCategoryWeights",
        decision.id,
        %{},
        [to_match1, to_match2],
        fields()
      )
    end

    test "filters by option_category_id" do
      %{option_category_weight: to_match, decision: decision} = create_option_category_weight()
      %{option_category_weight: _excluded} = create_option_category_weight(decision)

      assert_list_one_query(
        "optionCategoryWeights",
        to_match,
        [:option_category_id],
        fields([:option_category_id])
      )
    end

    test "filters by participant_id" do
      %{option_category_weight: to_match, decision: decision} = create_option_category_weight()
      %{option_category_weight: _excluded} = create_option_category_weight(decision)

      assert_list_one_query(
        "optionCategoryWeights",
        to_match,
        [:option_category_id],
        fields([:option_category_id])
      )
    end

    test "no matching records" do
      decision = create_decision()
      assert_list_none_query("optionCategoryWeights", %{decision_id: decision.id}, [:id])
    end
  end

  describe "upsertOptionCategoryWeight mutation" do
    test "creates with valid data" do
      %{decision: decision} = deps = option_category_weight_deps()

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload =
        run_mutate_one_query("upsertOptionCategoryWeight", decision.id, attrs)

      assert_mutation_success(attrs, payload, fields(field_names))
    end

    test "upserts with valid data" do
      %{decision: decision} = deps = create_option_category_weight()

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload =
        run_mutate_one_query("upsertOptionCategoryWeight", decision.id, attrs)

      assert_mutation_success(attrs, payload, fields(field_names))
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = option_category_weight_deps()

      field_names = input_field_names()
      attrs = deps |> invalid_attrs() |> Map.take(field_names)

      payload =
        run_mutate_one_query("upsertOptionCategoryWeight", decision.id, attrs)

      expected = [%ValidationMessage{code: :less_than_or_equal_to, field: :weighting}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid Decision returns error" do
      %{decision: decision} = deps = option_category_weight_deps()
      delete_decision(decision)

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload =
        run_mutate_one_query("upsertOptionCategoryWeight", decision.id, attrs)

      expected = [%ValidationMessage{code: :not_found, field: "decisionId"}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "deletes" do
      %{option_category_weight: to_delete, decision: decision} =
        deps = create_option_category_weight()

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names) |> Map.put(:delete, true)

      payload =
        run_mutate_one_query("upsertOptionCategoryWeight", decision.id, attrs, field_names)

      assert %{"successful" => true} = payload
      assert nil == payload["result"]
      assert nil == Voting.get_option_category_weight(to_delete.id, decision)
    end
  end
end
