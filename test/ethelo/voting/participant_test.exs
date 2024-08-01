defmodule EtheloApi.Voting.ParticipantTest do
  @moduledoc """
  Validations and basic access for Participants
  Includes both the context EtheloApi.Structure, and specific functionality on the Participant schema
  """
  use EtheloApi.DataCase
  import EtheloApi.Voting.Factory

  alias EtheloApi.Voting
  alias EtheloApi.Voting.Participant
  alias EtheloApi.Structure.Decision

  @empty_attrs %{participant_id: nil, weighting: nil, influent_hash: nil}
  @invalid_attrs %{participant_id: 30, weighting: "max"}

  def valid_attrs(_) do
    %{weighting: 93033.72, influent_hash: "123"}
  end

  def create_pair() do
    %{participant: participant1, decision: decision} = create_participant()
    %{participant: participant2} = create_participant(decision)
    [participant1, participant2]
  end

  def assert_equivalent(expected, result) do
    assert Decimal.cmp(Decimal.from_float(expected.weighting), result.weighting) == :eq
    assert expected.influent_hash == result.influent_hash
  end

  describe "list_participants/1" do

    test "returns all participants for a Decision" do
      create_participant() # should not be returned
      [first, second] = create_pair()

      result = Voting.list_participants(first.decision)

      assert [%Participant{}, %Participant{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Voting.list_participants(nil) end
    end
  end

  describe "get_participant/2" do

    test "returns the matching record by Decision object" do
      %{participant: record, decision: decision} = create_participant()

      result = Voting.get_participant(record.id, decision)

      assert %Participant{} = result
      assert result.id == record.id
    end

    test "returns the matching record by Decision.id" do
      %{participant: record, decision: decision} = create_participant()

      result = Voting.get_participant(record.id, decision.id)

      assert %Participant{} = result
      assert result.id == record.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Voting.get_participant(1, nil) end
    end

    test "raises without a Participant id" do
      assert_raise ArgumentError, ~r/Participant/,
        fn -> Voting.get_participant(nil, create_decision()) end
    end

    test "returns nil if id does not exist" do
      decision = create_decision()

      result = Voting.get_participant(1929, decision.id)

      assert result == nil
    end

    test "returns nil with invalid decision id " do
      %{participant: record} = create_participant()
      decision2 = create_decision()

      result = Voting.get_participant(record.id, decision2)

      assert result == nil
    end
  end

  describe "create_participant/2 " do

    test "creates with valid data" do
      deps = participant_deps()
      attrs = valid_attrs(deps)

      result = Voting.create_participant(deps.decision, attrs)

      assert {:ok, %Participant{} = new_record} = result

      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == deps.decision.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn ->
        Voting.create_participant(nil, @invalid_attrs)
      end
    end

    test "with empty data is uses defaults" do
      decision = create_decision()

      result = Voting.create_participant(decision, @empty_attrs)

      assert {:ok, %Participant{} = new_record} = result

      assert Decimal.cmp(Decimal.from_float(1.0), new_record.weighting) == :eq
  end

    test "with invalid data returns errors" do
      decision = create_decision()

      result = Voting.create_participant(decision, @invalid_attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "is invalid" in errors.weighting
    end

  end

  describe "update_participant/2" do
    test "updates with valid data" do
      %{participant: existing} = deps = create_participant()
      attrs = valid_attrs(deps)

      result = Voting.update_participant(existing, attrs)

      assert {:ok, %Participant{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "empty data does not return errors" do
      %{participant: existing} = create_participant()

      result = Voting.update_participant(existing, @empty_attrs)

      assert {:ok, %Participant{} = updated} = result
      assert Decimal.cmp(Decimal.from_float(1.0), updated.weighting) == :eq
    end

    test "invalid data returns errors" do
      %{participant: existing} = create_participant()

      result = Voting.update_participant(existing, @invalid_attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "is invalid" in errors.weighting
    end

    test "Decision update ignored" do
      %{participant: existing} = create_participant()
      decision2 = create_decision()
      attrs = %{weighting: 4.3, decision: decision2}

      result = Voting.update_participant(existing, attrs)
      assert {:ok, updated} = result
      assert Decimal.cmp(Decimal.from_float(attrs.weighting), updated.weighting) == :eq
      refute updated.decision.id == decision2.id
      assert updated.decision.id == existing.decision_id
    end
  end

  describe "delete_participant/2" do

    test "deletes" do
      %{participant: existing, decision: decision} = create_participant()
      to_delete = %Participant{id: existing.id}

      result = Voting.delete_participant(to_delete, decision.id)
      assert {:ok, %Participant{}} = result
      assert nil == Repo.get(Participant, existing.id)
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
