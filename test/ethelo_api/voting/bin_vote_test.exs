defmodule EtheloApi.Voting.BinVoteTest do
  @moduledoc """
  Validations and basic access for BinVotes
  Includes both the context EtheloApi.Structure, and specific functionality on the BinVote schema
  """
  use EtheloApi.DataCase

  @moduletag bin_vote: true, ecto: true
  import EtheloApi.Voting.Factory
  import EtheloApi.Voting.TestHelper.BinVoteHelper

  alias EtheloApi.Voting
  alias EtheloApi.Voting.BinVote
  alias EtheloApi.Voting.Participant
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Option

  describe "list_bin_votes/1" do
    test "filters by decision_id" do
      %{bin_vote: _excluded} = create_bin_vote()
      [to_match1, to_match2] = create_pair()

      result = Voting.list_bin_votes(to_match1.decision)
      assert [%BinVote{}, %BinVote{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "filters by participant_id" do
      [to_match, _excluded] = create_pair()
      decision = to_match.decision
      modifiers = %{participant_id: to_match.participant_id}

      result = Voting.list_bin_votes(decision, modifiers)

      assert [%BinVote{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by criteria_id" do
      [to_match, _excluded] = create_pair()
      decision = to_match.decision
      modifiers = %{criteria_id: to_match.criteria_id}

      result = Voting.list_bin_votes(decision, modifiers)

      assert [%BinVote{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by option_id" do
      [to_match, _excluded] = create_pair()
      decision = to_match.decision
      modifiers = %{option_id: to_match.option_id}

      result = Voting.list_bin_votes(decision, modifiers)
      assert [%BinVote{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Voting.list_bin_votes(nil) end
    end
  end

  describe "get_bin_vote/2" do
    test "filters by decision_id as struct" do
      %{bin_vote: to_match, decision: decision} = create_bin_vote()

      result = Voting.get_bin_vote(to_match.id, decision)

      assert %BinVote{} = result
      assert result.id == to_match.id
    end

    test "filters by decision_id" do
      %{bin_vote: to_match, decision: decision} = create_bin_vote()

      result = Voting.get_bin_vote(to_match.id, decision.id)

      assert %BinVote{} = result
      assert result.id == to_match.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Voting.get_bin_vote(1, nil) end
    end

    test "raises without a BinVote id" do
      assert_raise ArgumentError, ~r/BinVote/, fn ->
        Voting.get_bin_vote(nil, create_decision())
      end
    end

    test "missing record returns nil" do
      decision = create_decision()

      result = Voting.get_bin_vote(1929, decision.id)

      assert result == nil
    end

    test "invalid Decision returns nil" do
      %{bin_vote: to_match} = create_bin_vote()
      decision2 = create_decision()

      result = Voting.get_bin_vote(to_match.id, decision2)

      assert result == nil
    end
  end

  describe "upsert_bin_vote/2" do
    test "creates with valid data" do
      %{decision: decision} = deps = bin_vote_deps()
      attrs = valid_attrs(deps)

      result = Voting.upsert_bin_vote(attrs, decision)

      assert {:ok, %BinVote{} = new_record} = result

      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "upserts existing record" do
      %{decision: decision} = deps = create_bin_vote()
      attrs = valid_attrs(deps)

      result = Voting.upsert_bin_vote(attrs, decision)

      assert {:ok, %BinVote{} = updated_record} = result

      assert_equivalent(attrs, updated_record)
      assert updated_record.decision_id == decision.id
      assert updated_record.id == deps.bin_vote.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn ->
        Voting.upsert_bin_vote(invalid_attrs(), nil)
      end
    end

    test "empty data returns changeset" do
      decision = create_decision()

      result = Voting.upsert_bin_vote(empty_attrs(), decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.bin
      assert "can't be blank" in errors.participant_id
      assert "can't be blank" in errors.criteria_id
      assert "can't be blank" in errors.option_id
      expected = [:participant_id, :criteria_id, :option_id, :bin]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      decision = create_decision()

      result = Voting.upsert_bin_vote(invalid_attrs(), decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.participant_id
      assert "does not exist" in errors.criteria_id
      assert "does not exist" in errors.option_id
      assert "must be less than or equal to 9" in errors.bin
      expected = [:participant_id, :criteria_id, :option_id, :bin]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "Option from different Decision returns changeset" do
      %{option: mismatch} = create_option()
      %{decision: decision} = deps = bin_vote_deps()

      attrs = deps |> Map.put(:option, mismatch) |> valid_attrs()

      result = Voting.upsert_bin_vote(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.option_id
    end

    test "Criteria from different Decision returns changeset" do
      %{criteria: mismatch} = create_criteria()
      %{decision: decision} = deps = bin_vote_deps()

      attrs = deps |> Map.put(:criteria, mismatch) |> valid_attrs()

      result = Voting.upsert_bin_vote(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.criteria_id
    end

    test "Participant from different Decision returns changeset" do
      %{participant: mismatch} = create_participant()
      %{decision: decision} = deps = bin_vote_deps()
      attrs = deps |> Map.put(:participant, mismatch) |> valid_attrs()

      result = Voting.upsert_bin_vote(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.participant_id
    end
  end

  describe "delete_bin_vote/2" do
    test "deletes" do
      %{bin_vote: to_delete, decision: decision, participant: participant, option: option} =
        create_bin_vote()

      result = Voting.delete_bin_vote(to_delete, decision.id)
      assert {:ok, %BinVote{}} = result
      assert nil == Repo.get(BinVote, to_delete.id)
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
