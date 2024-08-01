defmodule GraphQL.EtheloApi.Resolvers.CriteriaWeightTest do
  @moduledoc """
  Validations and basic access for "CriteriaWeight" resolver, used to load criteria_weight records
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
  alias Ecto.Changeset
  alias GraphQL.EtheloApi.Resolvers.CriteriaWeight, as: CriteriaWeightResolver

  describe "list/2" do

    test "returns records matching a Decision" do
      %{criteria_weight: first, decision: decision} = create_criteria_weight()
      %{criteria_weight: second} = create_criteria_weight(decision)

      parent = %{decision: decision}
      args = %{}
      result = CriteriaWeightResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%CriteriaWeight{}, %CriteriaWeight{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "filters by CriteriaWeight.participant_id" do
      %{criteria_weight: matching, decision: decision} = create_criteria_weight()
      create_criteria_weight(decision)

      parent = %{decision: decision}
      args = %{participant_id: matching.participant_id}
      result = CriteriaWeightResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%CriteriaWeight{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by CriteriaWeight.criteria_id" do
      %{criteria_weight: matching, decision: decision} = create_criteria_weight()
      create_criteria_weight(decision)

      parent = %{decision: decision}
      args = %{criteria_id: matching.criteria_id}
      result = CriteriaWeightResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%CriteriaWeight{}] = result
      assert_result_ids_match([matching], result)
    end

    test "no CriteriaWeight matches" do
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
      deps = criteria_weight_deps()
      %{decision: decision} = deps

      attrs = deps |> valid_attrs()
      result = CriteriaWeightResolver.upsert(decision, attrs)

      assert {:ok, %CriteriaWeight{} = new_record} = result
      assert attrs.weighting == new_record.weighting
      assert attrs.criteria_id == new_record.criteria_id
      assert attrs.participant_id == new_record.participant_id
    end

    test "returns a list of errors with invalid data" do
      deps = criteria_weight_deps()
      %{decision: decision} = deps
      delete_participant(deps.participant)
      delete_criteria(deps.criteria)

      attrs = deps |> invalid_attrs()
      result = CriteriaWeightResolver.upsert(decision, attrs)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> errors_on() |> Map.keys()
      assert :participant_id in errors
      assert :criteria_id in errors
      assert :weighting in errors
      assert [_, _, _,] = errors
    end

    test "updates with valid data" do
      deps = create_criteria_weight()
      %{decision: decision} = deps

      attrs = deps |> valid_attrs()
      result = CriteriaWeightResolver.upsert(decision, attrs)

      assert {:ok, %CriteriaWeight{} = updated} = result
      assert attrs.weighting == updated.weighting
      assert attrs.criteria_id == updated.criteria_id
      assert attrs.participant_id == updated.participant_id
    end

    test "deletes" do
      deps = create_criteria_weight()
      %{criteria_weight: criteria_weight, decision: decision} = deps

      attrs = deps |> valid_attrs() |> Map.put(:delete, true)

      result = CriteriaWeightResolver.upsert(decision, attrs)

      assert {:ok, nil} = result
      assert nil == Voting.get_criteria_weight(criteria_weight.id, decision)
    end

  end
end
