defmodule EtheloApi.Voting.BinVoteTest do
  @moduledoc """
  Validations and basic access for BinVotes
  Includes both the context EtheloApi.Structure, and specific functionality on the BinVote schema
  """
  use EtheloApi.DataCase
  import EtheloApi.Voting.Factory
  import EtheloApi.Voting.TestHelper.BinVoteHelper

  alias EtheloApi.Voting
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Option
  alias EtheloApi.Voting.Participant
  alias EtheloApi.Voting.BinVote
  @moduletag bin_vote: true, ecto: true

  describe "list_bin_votes/1" do

    test "returns all records matching a Decision" do
      create_bin_vote() # should not be returned
      [first, second] = create_pair()

      result = Voting.list_bin_votes(first.decision)
      assert [%BinVote{}, %BinVote{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "returns all records matching a Participant" do
      [first, _] = create_pair()
      decision = first.decision
      filters = %{participant_id: first.participant_id}

      result = Voting.list_bin_votes(decision, filters)

      assert [%BinVote{}] = result
      assert_result_ids_match([first], result)
    end

    test "returns all records matching a Criteria" do
      [first, _] = create_pair()
      decision = first.decision
      filters = %{criteria_id: first.criteria_id}

      result = Voting.list_bin_votes(decision, filters)

      assert [%BinVote{}] = result
      assert_result_ids_match([first], result)
    end

    test "returns all records matching an Option" do
      create_bin_vote() # should not be returned
      [first, _] = create_pair()
      decision = first.decision
      filters = %{option_id: first.option_id}

      result = Voting.list_bin_votes(decision, filters)
      assert [%BinVote{}] = result
      assert_result_ids_match([first], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Voting.list_bin_votes(nil) end
    end
  end

  describe "get_bin_vote/2" do

    test "returns the matching record by Decision object" do
      %{bin_vote: record, decision: decision} = create_bin_vote()

      result = Voting.get_bin_vote(record.id, decision)

      assert %BinVote{} = result
      assert result.id == record.id
    end

    test "returns the matching record by Decision.id" do
      %{bin_vote: record, decision: decision} = create_bin_vote()

      result = Voting.get_bin_vote(record.id, decision.id)

      assert %BinVote{} = result
      assert result.id == record.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Voting.get_bin_vote(1, nil) end
    end

    test "raises without an BinVote id" do
      assert_raise ArgumentError, ~r/BinVote/,
        fn -> Voting.get_bin_vote(nil, create_decision()) end
    end

    test "returns nil if id does not exist" do
      decision = create_decision()

      result = Voting.get_bin_vote(1929, decision.id)

      assert result == nil
    end

    test "returns nil with invalid decision id " do
      %{bin_vote: record} = create_bin_vote()
      decision2 = create_decision()

      result = Voting.get_bin_vote(record.id, decision2)

      assert result == nil
    end
  end

  describe "upsert_bin_vote/2 " do

    test "creates with valid data" do
      deps = bin_vote_deps()
      attrs = valid_attrs(deps)

      result = Voting.upsert_bin_vote(deps.decision, attrs)

      assert {:ok, %BinVote{} = new_record} = result

      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == deps.decision.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
      	fn -> Voting.upsert_bin_vote(nil, invalid_attrs()) end
    end

    test "Duplicate dependencies upserts" do
      deps = create_bin_vote()
      attrs = valid_attrs(deps)

      result = Voting.upsert_bin_vote(deps.decision, attrs)

      assert {:ok, %BinVote{} = updated_record} = result

      assert_equivalent(attrs, updated_record)
      assert updated_record.decision_id == deps.decision.id
      assert updated_record.id == deps.bin_vote.id
    end

    test "an Option from different decision returns changeset" do
      %{option: option} = create_option()
      deps = bin_vote_deps() |> Map.put(:option, option)
      attrs = valid_attrs(deps)

      result = Voting.upsert_bin_vote(deps.decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.option_id
    end

    test "a Criteria from different decision returns changeset" do
      %{criteria: criteria} = create_criteria()
      deps = bin_vote_deps() |> Map.put(:criteria, criteria)
      attrs = valid_attrs(deps)

      result = Voting.upsert_bin_vote(deps.decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.criteria_id
    end

    test "a Participant from different decision returns changeset" do
      %{participant: participant} = create_participant()
      deps = bin_vote_deps() |> Map.put(:participant, participant)
      attrs = valid_attrs(deps)

      result = Voting.upsert_bin_vote(deps.decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.participant_id
    end

    test "with empty data returns errors" do
      decision = create_decision()

      result = Voting.upsert_bin_vote(decision, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "can't be blank" in errors.bin
      assert "can't be blank" in errors.participant_id
      assert "can't be blank" in errors.criteria_id
      assert "can't be blank" in errors.option_id
    end

    test "with invalid data returns errors" do
      decision = create_decision()

      result = Voting.upsert_bin_vote(decision, invalid_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.participant_id
      assert "does not exist" in errors.criteria_id
      assert "does not exist" in errors.option_id
      assert "is invalid" in errors.bin
    end

  end

  describe "delete_bin_vote/2" do

    test "deletes" do
      %{bin_vote: existing, decision: decision, participant: participant, option: option} = create_bin_vote()
      to_delete = %BinVote{id: existing.id}

      result = Voting.delete_bin_vote(to_delete, decision.id)
      assert {:ok, %BinVote{}} = result
      assert nil == Repo.get(BinVote, existing.id)
      assert nil !== Repo.get(Decision, decision.id)
      assert nil !== Repo.get(Participant, participant.id)
      assert nil !== Repo.get(Option, option.id)
    end
  end

  describe "documentation" do
    test "has documentation module" do
      assert %{} = BinVote.strings()
      assert %{} = BinVote.examples()
      assert is_list(BinVote.fields())
    end
  end
end
