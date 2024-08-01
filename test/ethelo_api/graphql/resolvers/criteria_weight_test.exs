defmodule EtheloApi.Graphql.Resolvers.CriteriaWeightTest do
  @moduledoc """
  Validations and basic access for CriteriaWeight resolver
  through graphql.
  Note: Functionality is provided through the CriteriaWeightResolver.CriteriaWeight context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Voting.CriteriaWeightTest`
  """
  use EtheloApi.DataCase
  @moduletag criteria_weight: true, graphql: true

  import EtheloApi.Voting.Factory
  import EtheloApi.Voting.TestHelper.CriteriaWeightHelper

  alias EtheloApi.Voting
  alias EtheloApi.Voting.CriteriaWeight
  alias EtheloApi.Graphql.Resolvers.CriteriaWeight, as: CriteriaWeightResolver

  def test_list_filtering(field_name) do
    %{criteria_weight: to_match, decision: decision} = create_criteria_weight()
    %{criteria_weight: _excluded} = create_criteria_weight(decision)
    test_list_filtering(field_name, to_match, decision)
  end

  def test_list_filtering(field_name, to_match, decision) do
    parent = %{decision: decision}
    args = %{} |> Map.put(field_name, Map.get(to_match, field_name))
    result = CriteriaWeightResolver.list(parent, args, nil)
    assert {:ok, result} = result
    assert [%CriteriaWeight{}] = result
    assert_result_ids_match([to_match], result)
  end

  describe "list/2" do
    test "filters by decision_id" do
      %{criteria_weight: to_match1, decision: decision} = create_criteria_weight()
      %{criteria_weight: to_match2} = create_criteria_weight(decision)

      parent = %{decision: decision}
      args = %{}
      result = CriteriaWeightResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%CriteriaWeight{}, %CriteriaWeight{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "filters by participant_id" do
      test_list_filtering(:participant_id)
    end

    test "filters by criteria_id" do
      test_list_filtering(:criteria_id)
    end

    test "no matching records" do
      decision = create_decision()

      parent = %{decision: decision}
      args = %{}
      result = CriteriaWeightResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [] = result
    end
  end

  describe "upsert/2" do
    test "creates with valid data" do
      %{decision: decision} = deps = criteria_weight_deps()

      attrs = deps |> valid_attrs()
      params = to_graphql_input_params(attrs, decision)

      result = CriteriaWeightResolver.upsert(params, nil)
      assert {:ok, %CriteriaWeight{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "invalid data returns changeset" do
      %{decision: decision} = deps = criteria_weight_deps()
      delete_participant(deps.participant)
      delete_criteria(deps.criteria)
      attrs = deps |> invalid_attrs()
      params = to_graphql_input_params(attrs, decision)
      result = CriteriaWeightResolver.upsert(params, nil)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> error_map()

      expected = [:weighting, :criteria_id, :participant_id]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "updates with valid data" do
      %{decision: decision} = deps = create_criteria_weight()

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = CriteriaWeightResolver.upsert(params, nil)

      assert {:ok, %CriteriaWeight{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "deletes" do
      %{criteria_weight: to_delete, decision: decision} = deps = create_criteria_weight()

      attrs = deps |> valid_attrs() |> Map.put(:delete, true)
      params = to_graphql_input_params(attrs, decision)

      result = CriteriaWeightResolver.upsert(params, nil)

      assert {:ok, nil} = result
      assert nil == Voting.get_criteria_weight(to_delete.id, decision)
    end
  end
end
