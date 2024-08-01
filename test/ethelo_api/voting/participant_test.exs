defmodule EtheloApi.Voting.ParticipantTest do
  @moduledoc """
  Validations and basic access for Participants
  Includes both the context EtheloApi.Structure, and specific functionality on the Participant schema
  """
  use EtheloApi.DataCase
  @moduletag participant: true, ecto: true

  import EtheloApi.Voting.Factory
  import EtheloApi.Voting.TestHelper.ParticipantHelper

  alias EtheloApi.Voting
  alias EtheloApi.Voting.Participant
  alias EtheloApi.Structure.Decision

  describe "list_participants/1" do
    test "filters by decision_id" do
      %{participant: _excluded} = create_participant()
      %{participant: to_match1, decision: decision} = create_participant()
      %{participant: to_match2} = create_participant(decision)

      result = Voting.list_participants(decision)

      assert [%Participant{}, %Participant{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Voting.list_participants(nil) end
    end
  end

  describe "get_participant/2" do
    test "filters by decision_id as struct" do
      %{participant: to_match, decision: decision} = create_participant()

      result = Voting.get_participant(to_match.id, decision)

      assert %Participant{} = result
      assert result.id == to_match.id
    end

    test "filters by decision_id" do
      %{participant: to_match, decision: decision} = create_participant()

      result = Voting.get_participant(to_match.id, decision.id)

      assert %Participant{} = result
      assert result.id == to_match.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Voting.get_participant(1, nil) end
    end

    test "raises without a Participant id" do
      assert_raise ArgumentError, ~r/Participant/, fn ->
        Voting.get_participant(nil, create_decision())
      end
    end

    test "missing record returns nil" do
      decision = create_decision()

      result = Voting.get_participant(1929, decision.id)

      assert result == nil
    end

    test "invalid Decision returns nil" do
      %{participant: to_match} = create_participant()
      decision2 = create_decision()

      result = Voting.get_participant(to_match.id, decision2)

      assert result == nil
    end
  end

  describe "create_participant/2" do
    test "creates with valid data" do
      %{decision: decision} = deps = participant_deps()
      attrs = valid_attrs(deps)

      result = Voting.create_participant(attrs, decision)

      assert {:ok, %Participant{} = new_record} = result

      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn ->
        Voting.create_participant(invalid_attrs(), nil)
      end
    end

    test "empty data returns defaults" do
      decision = create_decision()

      result = Voting.create_participant(empty_attrs(), decision)

      assert {:ok, %Participant{} = new_record} = result
      assert_decimal_eq(1.0, new_record.weighting)
    end

    test "invalid data returns changeset" do
      decision = create_decision()

      attrs = invalid_attrs()
      result = Voting.create_participant(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "must be less than 99999.99" in errors.weighting
      expected = [:weighting]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "update_participant/2" do
    test "updates with valid data" do
      %{participant: to_update} = deps = create_participant()
      attrs = valid_attrs(deps)

      result = Voting.update_participant(to_update, attrs)

      assert {:ok, %Participant{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    # this is weird, may need to change later - possible decimal/float weirdness happening
    test "empty data returns Participant with default weighting" do
      %{participant: to_update} = create_participant()

      result = Voting.update_participant(to_update, empty_attrs())

      assert {:ok, %Participant{} = updated} = result
      assert_decimal_eq(1.0, updated.weighting)
    end

    test "invalid data returns changeset" do
      %{participant: to_update} = create_participant()

      result = Voting.update_participant(to_update, invalid_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "must be less than 99999.99" in errors.weighting
      expected = [:weighting]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "Decision update ignored" do
      %{participant: to_update} = create_participant()
      decision2 = create_decision()
      attrs = %{weighting: 4.3, decision: decision2}

      result = Voting.update_participant(to_update, attrs)
      assert {:ok, updated} = result
      assert_decimal_eq(attrs.weighting, updated.weighting)
      refute updated.decision.id == decision2.id
      assert updated.decision.id == to_update.decision_id
    end
  end

  describe "delete_participant/2" do
    test "deletes" do
      %{participant: to_delete, decision: decision} = create_participant()

      result = Voting.delete_participant(to_delete, decision.id)
      assert {:ok, %Participant{}} = result
      assert nil == Repo.get(Participant, to_delete.id)
      assert nil !== Repo.get(Decision, decision.id)
    end
  end

  describe "documentation" do
    test "has documentation module" do
      assert %{} = Participant.strings()
      assert %{} = Participant.examples()
      assert is_list(Participant.fields())
    end
  end
end
