defmodule EtheloApi.Voting.OptionCategoryBinVoteTest do
  @moduledoc """
  Validations and basic access for OptionCategoryBinVotes
  Includes both the context EtheloApi.Structure, and specific functionality on the OptionCategoryBinVote schema
  """
  use EtheloApi.DataCase
  import EtheloApi.Voting.Factory
  import EtheloApi.Voting.TestHelper.OptionCategoryBinVoteHelper

  alias EtheloApi.Voting
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.OptionCategory
  alias EtheloApi.Voting.Participant
  alias EtheloApi.Voting.OptionCategoryBinVote

  describe "list_option_category_bin_votes/1" do

    test "returns all records matching a Decision" do
      create_option_category_bin_vote() # should not be returned
      [first, second] = create_pair()

      result = Voting.list_option_category_bin_votes(first.decision)
      assert [%OptionCategoryBinVote{}, %OptionCategoryBinVote{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "returns all records matching a Participant" do
      [first, _] = create_pair()
      decision = first.decision
      filters = %{participant_id: first.participant_id}

      result = Voting.list_option_category_bin_votes(decision, filters)

      assert [%OptionCategoryBinVote{}] = result
      assert_result_ids_match([first], result)
    end

    test "returns all records matching a Criteria" do
      [first, _] = create_pair()
      decision = first.decision
      filters = %{criteria_id: first.criteria_id}

      result = Voting.list_option_category_bin_votes(decision, filters)

      assert [%OptionCategoryBinVote{}] = result
      assert_result_ids_match([first], result)
    end

    test "returns all records matching an OptionCategory" do
      create_option_category_bin_vote() # should not be returned
      [first, _] = create_pair()
      decision = first.decision
      filters = %{option_category_id: first.option_category_id}

      result = Voting.list_option_category_bin_votes(decision, filters)
      assert [%OptionCategoryBinVote{}] = result
      assert_result_ids_match([first], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Voting.list_option_category_bin_votes(nil) end
    end
  end

  describe "get_option_category_bin_vote/2" do

    test "returns the matching record by Decision object" do
      %{option_category_bin_vote: record, decision: decision} = create_option_category_bin_vote()

      result = Voting.get_option_category_bin_vote(record.id, decision)

      assert %OptionCategoryBinVote{} = result
      assert result.id == record.id
    end

    test "returns the matching record by Decision.id" do
      %{option_category_bin_vote: record, decision: decision} = create_option_category_bin_vote()

      result = Voting.get_option_category_bin_vote(record.id, decision.id)

      assert %OptionCategoryBinVote{} = result
      assert result.id == record.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Voting.get_option_category_bin_vote(1, nil) end
    end

    test "raises without an OptionCategoryBinVote id" do
      assert_raise ArgumentError, ~r/OptionCategoryBinVote/,
        fn -> Voting.get_option_category_bin_vote(nil, create_decision()) end
    end

    test "returns nil if id does not exist" do
      decision = create_decision()

      result = Voting.get_option_category_bin_vote(1929, decision.id)

      assert result == nil
    end

    test "returns nil with invalid decision id " do
      %{option_category_bin_vote: record} = create_option_category_bin_vote()
      decision2 = create_decision()

      result = Voting.get_option_category_bin_vote(record.id, decision2)

      assert result == nil
    end
  end

  describe "upsert_option_category_bin_vote/2 " do

    test "creates with valid data" do
      deps = option_category_bin_vote_deps()
      attrs = valid_attrs(deps)

      result = Voting.upsert_option_category_bin_vote(deps.decision, attrs)

      assert {:ok, %OptionCategoryBinVote{} = new_record} = result

      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == deps.decision.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
      	fn -> Voting.upsert_option_category_bin_vote(nil, invalid_attrs()) end
    end

    test "Duplicate dependencies upsert" do
      deps = create_option_category_bin_vote()
      attrs = valid_attrs(deps)

      result = Voting.upsert_option_category_bin_vote(deps.decision, attrs)

      assert {:ok, %OptionCategoryBinVote{} = updated_record} = result

      assert_equivalent(attrs, updated_record)
      assert updated_record.decision_id == deps.decision.id
      assert updated_record.id == deps.option_category_bin_vote.id
    end

    test "an OptionCategory from different decision returns changeset" do
      %{option_category: option_category} = create_option_category()
      deps = option_category_bin_vote_deps() |> Map.put(:option_category, option_category)
      attrs = valid_attrs(deps)

      result = Voting.upsert_option_category_bin_vote(deps.decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.option_category_id
    end

    test "a Criteria from different decision returns changeset" do
      %{criteria: criteria} = create_criteria()
      deps = option_category_bin_vote_deps() |> Map.put(:criteria, criteria)
      attrs = valid_attrs(deps)

      result = Voting.upsert_option_category_bin_vote(deps.decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.criteria_id
    end

    test "a Participant from different decision returns changeset" do
      %{participant: participant} = create_participant()
      deps = option_category_bin_vote_deps() |> Map.put(:participant, participant)
      attrs = valid_attrs(deps)

      result = Voting.upsert_option_category_bin_vote(deps.decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.participant_id
    end

    test "with empty data returns errors" do
      decision = create_decision()

      result = Voting.upsert_option_category_bin_vote(decision, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "can't be blank" in errors.bin
      assert "can't be blank" in errors.participant_id
      assert "can't be blank" in errors.criteria_id
      assert "can't be blank" in errors.option_category_id
    end

    test "with invalid data returns errors" do
      decision = create_decision()

      result = Voting.upsert_option_category_bin_vote(decision, invalid_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.participant_id
      assert "does not exist" in errors.criteria_id
      assert "does not exist" in errors.option_category_id
      assert "is invalid" in errors.bin
    end

  end

  describe "delete_option_category_bin_vote/2" do

    test "deletes" do
      %{option_category_bin_vote: existing, decision: decision, participant: participant, option_category: option_category} = create_option_category_bin_vote()
      to_delete = %OptionCategoryBinVote{id: existing.id}

      result = Voting.delete_option_category_bin_vote(to_delete, decision.id)
      assert {:ok, %OptionCategoryBinVote{}} = result
      assert nil == Repo.get(OptionCategoryBinVote, existing.id)
      assert nil !== Repo.get(Decision, decision.id)
      assert nil !== Repo.get(Participant, participant.id)
      assert nil !== Repo.get(OptionCategory, option_category.id)

    end

  end

  describe "documentation" do
    test "has documentation module" do
      assert %{} = OptionCategoryBinVote.strings()
      assert %{} = OptionCategoryBinVote.examples()
      assert is_list(OptionCategoryBinVote.fields())
    end
  end
end
