defmodule EtheloApi.Graphql.Schemas.CriteriaWeightTest do
  @moduledoc """
  Test graphql queries for CriteriaWeights
  """
  use EtheloApi.Graphql.SchemaCase
  @moduletag criteria_weight: true, graphql: true

  alias EtheloApi.Voting
  import EtheloApi.Voting.Factory
  import EtheloApi.Voting.TestHelper.CriteriaWeightHelper

  describe "decision => criteriaWeights query" do
    test "without filter returns all records" do
      %{criteria_weight: to_match1, decision: decision} = create_criteria_weight()
      %{criteria_weight: to_match2} = create_criteria_weight(decision)
      %{criteria_weight: _excluded} = create_criteria_weight()

      assert_list_many_query(
        "criteriaWeights",
        decision.id,
        %{},
        [to_match1, to_match2],
        fields()
      )
    end

    test "filters by criteria_id" do
      %{criteria_weight: to_match, decision: decision} = create_criteria_weight()
      %{criteria_weight: _excluded} = create_criteria_weight(decision)

      assert_list_one_query("criteriaWeights", to_match, [:criteria_id], fields([:criteria_id]))
    end

    test "filters by participant_id" do
      %{criteria_weight: to_match, decision: decision} = create_criteria_weight()
      %{criteria_weight: _excluded} = create_criteria_weight(decision)

      assert_list_one_query(
        "criteriaWeights",
        to_match,
        [:participant_id],
        fields([:participant_id])
      )
    end

    test "no matching records" do
      decision = create_decision()
      assert_list_none_query("criteriaWeights", %{decision_id: decision.id}, [:id])
    end
  end

  describe "upsertCriteriaWeight mutation" do
    test "creates with valid data" do
      %{decision: decision} = deps = criteria_weight_deps()

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("upsertCriteriaWeight", decision.id, attrs)

      assert_mutation_success(attrs, payload, fields(field_names))
    end

    test "upserts with valid data" do
      %{decision: decision} = deps = create_criteria_weight()

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("upsertCriteriaWeight", decision.id, attrs)

      assert_mutation_success(attrs, payload, fields(field_names))
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = criteria_weight_deps()

      field_names = input_field_names()
      attrs = deps |> invalid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("upsertCriteriaWeight", decision.id, attrs)

      expected = [%ValidationMessage{code: :less_than_or_equal_to, field: :weighting}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid Decision returns error" do
      %{decision: decision} = deps = criteria_weight_deps()
      delete_decision(decision)

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("upsertCriteriaWeight", decision.id, attrs)

      expected = [%ValidationMessage{code: :not_found, field: "decisionId"}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "deletes" do
      %{criteria_weight: to_delete, decision: decision} = deps = create_criteria_weight()

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names) |> Map.put(:delete, true)

      payload = run_mutate_one_query("upsertCriteriaWeight", decision.id, attrs, field_names)

      assert %{"successful" => true} = payload
      assert nil == payload["result"]

      assert nil == Voting.get_criteria_weight(to_delete.id, decision)
    end
  end
end
