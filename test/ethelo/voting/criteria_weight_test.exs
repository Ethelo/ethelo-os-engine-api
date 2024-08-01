defmodule EtheloApi.Voting.CriteriaWeightTest do
  @moduledoc """
  Validations and basic access for CriteriaWeights
  Includes both the context EtheloApi.Structure, and specific functionality on the CriteriaWeight schema
  """
  use EtheloApi.DataCase
  import EtheloApi.Voting.Factory
  import EtheloApi.Voting.TestHelper.CriteriaWeightHelper

  alias EtheloApi.Voting
  alias EtheloApi.Voting.CriteriaWeight
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Criteria
  alias EtheloApi.Voting.Participant

  describe "list_criteria_weights/1" do

    test "returns all records matching a Decision" do
      create_criteria_weight() # should not be returned
      [first, second] = create_pair()

      result = Voting.list_criteria_weights(first.decision)
      assert [%CriteriaWeight{}, %CriteriaWeight{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "returns all records matching a Participant" do
      [first, _] = create_pair()
      decision = first.decision
      filters = %{participant_id: first.participant_id}

      result = Voting.list_criteria_weights(decision, filters)

      assert [%CriteriaWeight{}] = result
      assert_result_ids_match([first], result)
    end

    test "returns all records matching an Criteria" do
      [first, _] = create_pair()
      decision = first.decision
      filters = %{criteria_id: first.criteria_id}

      result = Voting.list_criteria_weights(decision, filters)

      assert [%CriteriaWeight{}] = result
      assert_result_ids_match([first], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Voting.list_criteria_weights(nil) end
    end
  end

  describe "get_criteria_weight/2" do

    test "returns the matching record by Decision object" do
      %{criteria_weight: record, decision: decision} = create_criteria_weight()

      result = Voting.get_criteria_weight(record.id, decision)

      assert %CriteriaWeight{} = result
      assert result.id == record.id
    end

    test "returns the matching record by Decision.id" do
      %{criteria_weight: record, decision: decision} = create_criteria_weight()

      result = Voting.get_criteria_weight(record.id, decision.id)

      assert %CriteriaWeight{} = result
      assert result.id == record.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Voting.get_criteria_weight(1, nil) end
    end

    test "raises without an CriteriaWeight id" do
      assert_raise ArgumentError, ~r/CriteriaWeight/,
        fn -> Voting.get_criteria_weight(nil, create_decision()) end
    end

    test "returns nil if id does not exist" do
      decision = create_decision()

      result = Voting.get_criteria_weight(1929, decision.id)

      assert result == nil
    end

    test "returns nil with invalid decision id " do
      %{criteria_weight: record} = create_criteria_weight()
      decision2 = create_decision()

      result = Voting.get_criteria_weight(record.id, decision2)

      assert result == nil
    end
  end

  describe "upsert_criteria_weight/2 " do

    test "creates with valid data" do
      deps = criteria_weight_deps()
      attrs = valid_attrs(deps)

      result = Voting.upsert_criteria_weight(deps.decision, attrs)

      assert {:ok, %CriteriaWeight{} = new_record} = result
      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == deps.decision.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Voting.upsert_criteria_weight(nil, invalid_attrs()) end
    end

    test "Duplicate dependencies upserts" do
      deps = create_criteria_weight()
      attrs = valid_attrs(deps)

      result = Voting.upsert_criteria_weight(deps.decision, attrs)

      assert {:ok, %CriteriaWeight{} = updated_record} = result

      assert_equivalent(attrs, updated_record)
      assert updated_record.decision_id == deps.decision.id
      assert updated_record.id == deps.criteria_weight.id
    end


    test "Criteria from different decision returns changeset" do
      %{criteria: criteria} = create_criteria()
      deps = criteria_weight_deps() |> Map.put(:criteria, criteria)
      attrs = valid_attrs(deps)

      result = Voting.upsert_criteria_weight(deps.decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.criteria_id
    end

    test "Participant from different decision returns changeset" do
      %{participant: participant} = create_participant()
      deps = criteria_weight_deps() |> Map.put(:participant, participant)
      attrs = valid_attrs(deps)

      result = Voting.upsert_criteria_weight(deps.decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.participant_id
    end

    test "with empty data returns errors" do
      decision = create_decision()

      result = Voting.upsert_criteria_weight(decision, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "can't be blank" in errors.weighting
      assert "can't be blank" in errors.participant_id
      assert "can't be blank" in errors.criteria_id
    end

    test "with invalid data returns errors" do
      decision = create_decision()

      result = Voting.upsert_criteria_weight(decision, invalid_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.participant_id
      assert "does not exist" in errors.criteria_id
      assert "is invalid" in errors.weighting
    end

  end

  describe "delete_criteria_weight/2" do

    test "deletes" do
      %{criteria_weight: existing, participant: participant, criteria: criteria, decision: decision} = create_criteria_weight()
      to_delete = %CriteriaWeight{id: existing.id}

      result = Voting.delete_criteria_weight(to_delete, decision.id)
      assert {:ok, %CriteriaWeight{}} = result
      assert nil == Repo.get(CriteriaWeight, existing.id)
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
