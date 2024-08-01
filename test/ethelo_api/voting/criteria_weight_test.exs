defmodule EtheloApi.Voting.CriteriaWeightTest do
  @moduledoc """
  Validations and basic access for CriteriaWeights
  Includes both the context EtheloApi.Structure, and specific functionality on the CriteriaWeight schema
  """
  use EtheloApi.DataCase
  @moduletag criteria_weight: true, ecto: true

  import EtheloApi.Voting.Factory
  import EtheloApi.Voting.TestHelper.CriteriaWeightHelper

  alias EtheloApi.Voting
  alias EtheloApi.Voting.CriteriaWeight
  alias EtheloApi.Voting.Participant
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Criteria

  describe "list_criteria_weights/1" do
    test "filters by decision_id" do
      %{criteria_weight: _excluded} = create_criteria_weight()
      [to_match1, to_match2] = create_pair()

      result = Voting.list_criteria_weights(to_match1.decision)
      assert [%CriteriaWeight{}, %CriteriaWeight{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "filters by participant_id" do
      [to_match, _excluded] = create_pair()
      decision = to_match.decision
      modifiers = %{participant_id: to_match.participant_id}

      result = Voting.list_criteria_weights(decision, modifiers)

      assert [%CriteriaWeight{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by criteria_id" do
      [to_match, _excluded] = create_pair()
      decision = to_match.decision
      modifiers = %{criteria_id: to_match.criteria_id}

      result = Voting.list_criteria_weights(decision, modifiers)

      assert [%CriteriaWeight{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Voting.list_criteria_weights(nil) end
    end
  end

  describe "get_criteria_weight/2" do
    test "filters by decision_id as struct" do
      %{criteria_weight: to_match, decision: decision} = create_criteria_weight()

      result = Voting.get_criteria_weight(to_match.id, decision)

      assert %CriteriaWeight{} = result
      assert result.id == to_match.id
    end

    test "filters by decision_id" do
      %{criteria_weight: to_match, decision: decision} = create_criteria_weight()

      result = Voting.get_criteria_weight(to_match.id, decision.id)

      assert %CriteriaWeight{} = result
      assert result.id == to_match.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Voting.get_criteria_weight(1, nil) end
    end

    test "raises without a CriteriaWeight id" do
      assert_raise ArgumentError, ~r/CriteriaWeight/, fn ->
        Voting.get_criteria_weight(nil, create_decision())
      end
    end

    test "missing record returns nil" do
      decision = create_decision()

      result = Voting.get_criteria_weight(1929, decision.id)

      assert result == nil
    end

    test "invalid Decision returns nil" do
      %{criteria_weight: to_match} = create_criteria_weight()
      decision2 = create_decision()

      result = Voting.get_criteria_weight(to_match.id, decision2)

      assert result == nil
    end
  end

  describe "upsert_criteria_weight/2" do
    test "creates with valid data" do
      %{decision: decision} = deps = criteria_weight_deps()
      attrs = valid_attrs(deps)

      result = Voting.upsert_criteria_weight(attrs, decision)

      assert {:ok, %CriteriaWeight{} = new_record} = result
      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "upserts existing record" do
      %{decision: decision} = deps = create_criteria_weight()
      attrs = valid_attrs(deps)

      result = Voting.upsert_criteria_weight(attrs, decision)

      assert {:ok, %CriteriaWeight{} = updated_record} = result

      assert_equivalent(attrs, updated_record)
      assert updated_record.decision_id == decision.id
      assert updated_record.id == deps.criteria_weight.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn ->
        Voting.upsert_criteria_weight(invalid_attrs(), nil)
      end
    end

    test "empty data returns changeset" do
      decision = create_decision()

      result = Voting.upsert_criteria_weight(empty_attrs(), decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.weighting
      assert "can't be blank" in errors.participant_id
      assert "can't be blank" in errors.criteria_id
      expected = [:participant_id, :criteria_id, :weighting]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      decision = create_decision()

      result = Voting.upsert_criteria_weight(invalid_attrs(), decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.participant_id
      assert "does not exist" in errors.criteria_id
      assert "must be less than or equal to 100" in errors.weighting
      expected = [:participant_id, :criteria_id, :weighting]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "Criteria from different Decision returns changeset" do
      %{criteria: mismatch} = create_criteria()
      %{decision: decision} = deps = criteria_weight_deps()
      attrs = deps |> Map.put(:criteria, mismatch) |> valid_attrs()

      result = Voting.upsert_criteria_weight(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.criteria_id
    end

    test "Participant from different Decision returns changeset" do
      %{participant: mismatch} = create_participant()
      %{decision: decision} = deps = criteria_weight_deps()
      attrs = deps |> Map.put(:participant, mismatch) |> valid_attrs()

      result = Voting.upsert_criteria_weight(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.participant_id
    end
  end

  describe "delete_criteria_weight/2" do
    test "deletes" do
      %{
        criteria_weight: to_delete,
        participant: participant,
        criteria: criteria,
        decision: decision
      } = create_criteria_weight()

      result = Voting.delete_criteria_weight(to_delete, decision.id)
      assert {:ok, %CriteriaWeight{}} = result
      assert nil == Repo.get(CriteriaWeight, to_delete.id)
      assert nil !== Repo.get(Decision, decision.id)
      assert nil !== Repo.get(Participant, participant.id)
      assert nil !== Repo.get(Criteria, criteria.id)
    end
  end

  describe "documentation" do
    test "has documentation module" do
      assert %{} = CriteriaWeight.strings()
      assert %{} = CriteriaWeight.examples()
      assert is_list(CriteriaWeight.fields())
    end
  end
end
