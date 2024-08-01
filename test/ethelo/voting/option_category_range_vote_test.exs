defmodule EtheloApi.Voting.OptionCategoryRangeVoteTest do
  @moduledoc """
  Validations and basic access for OptionCategoryRangeVotes
  Includes both the context EtheloApi.Structure, and specific functionality on the OptionCategoryRangeVote schema
  """
  use EtheloApi.DataCase
  import EtheloApi.Voting.Factory
  import EtheloApi.Voting.TestHelper.OptionCategoryRangeVoteHelper

  alias EtheloApi.Voting
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Option
  alias EtheloApi.Structure.OptionCategory
  alias EtheloApi.Voting.Participant
  alias EtheloApi.Voting.OptionCategoryRangeVote


  describe "list_option_category_range_votes/1" do

    test "returns all records matching a Decision" do
      create_option_category_range_vote() # should not be returned
      [first, second] = create_pair()

      result = Voting.list_option_category_range_votes(first.decision)
      assert [%OptionCategoryRangeVote{}, %OptionCategoryRangeVote{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "returns all records matching a Participant" do
      [first, _] = create_pair()
      decision = first.decision
      filters = %{participant_id: first.participant_id}

      result = Voting.list_option_category_range_votes(decision, filters)

      assert [%OptionCategoryRangeVote{}] = result
      assert_result_ids_match([first], result)
    end

    test "returns all records matching an OptionCategory" do
      create_option_category_range_vote() # should not be returned
      [first, _] = create_pair()
      decision = first.decision
      filters = %{option_category_id: first.option_category_id}

      result = Voting.list_option_category_range_votes(decision, filters)
      assert [%OptionCategoryRangeVote{}] = result
      assert_result_ids_match([first], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Voting.list_option_category_range_votes(nil) end
    end
  end

  describe "get_option_category_range_vote/2" do

    test "returns the matching record by Decision object" do
      %{option_category_range_vote: record, decision: decision} = create_option_category_range_vote()

      result = Voting.get_option_category_range_vote(record.id, decision)

      assert %OptionCategoryRangeVote{} = result
      assert result.id == record.id
    end

    test "returns the matching record by Decision.id" do
      %{option_category_range_vote: record, decision: decision} = create_option_category_range_vote()

      result = Voting.get_option_category_range_vote(record.id, decision.id)

      assert %OptionCategoryRangeVote{} = result
      assert result.id == record.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Voting.get_option_category_range_vote(1, nil) end
    end

    test "raises without an OptionCategoryRangeVote id" do
      assert_raise ArgumentError, ~r/OptionCategoryRangeVote/,
        fn -> Voting.get_option_category_range_vote(nil, create_decision()) end
    end

    test "returns nil if id does not exist" do
      decision = create_decision()

      result = Voting.get_option_category_range_vote(1929, decision.id)

      assert result == nil
    end

    test "returns nil with invalid decision id " do
      %{option_category_range_vote: record} = create_option_category_range_vote()
      decision2 = create_decision()

      result = Voting.get_option_category_range_vote(record.id, decision2)

      assert result == nil
    end
  end

  describe "upsert_option_category_range_vote/2 " do

    test "creates with valid data" do
      deps = option_category_range_vote_deps()
      attrs = valid_attrs(deps)

      result = Voting.upsert_option_category_range_vote(deps.decision, attrs)

      assert {:ok, %OptionCategoryRangeVote{} = new_record} = result

      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == deps.decision.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
      	fn -> Voting.upsert_option_category_range_vote(nil, invalid_attrs()) end
    end

    test "Duplicate dependencies upsert" do
      deps = create_option_category_range_vote()
      %{option: option} = EtheloApi.Structure.Factory.create_option(deps.decision, %{option_category: deps.option_category})
      attrs = Map.put(deps, :high_option_id, option.id) |> valid_attrs()

      result = Voting.upsert_option_category_range_vote(deps.decision, attrs)
      all_range_votes = Voting.list_option_category_range_votes(deps.decision)

      assert {:ok, %OptionCategoryRangeVote{} = updated_record} = result
      assert_equivalent(attrs, updated_record)
      assert updated_record.decision_id == deps.decision.id
      assert updated_record.id == deps.option_category_range_vote.id
      assert length(all_range_votes) == 1

    end

    test "an OptionCategory from different decision returns changeset" do
      %{option_category: option_category} = create_option_category()
      deps = option_category_range_vote_deps() |> Map.put(:option_category, option_category)
      attrs = valid_attrs(deps)

      result = Voting.upsert_option_category_range_vote(deps.decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.option_category_id
    end

    test "a low Option from different decision returns changeset" do
      %{option: option} = create_option()
      deps = option_category_range_vote_deps() |> Map.put(:low_option, option)
      attrs = valid_attrs(deps)

      result = Voting.upsert_option_category_range_vote(deps.decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.low_option_id
    end

    test "a high Option from different decision returns changeset" do
      %{option: option} = create_option()
      deps = option_category_range_vote_deps() |> Map.put(:high_option, option)
      attrs = valid_attrs(deps)

      result = Voting.upsert_option_category_range_vote(deps.decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.high_option_id
    end

    test "a low Option from different OptionCategory returns changeset" do
      %{option: option, decision: decision} = create_option()
      deps = option_category_range_vote_deps(decision) |> Map.put(:low_option, option)
      attrs = valid_attrs(deps)

      result = Voting.upsert_option_category_range_vote(deps.decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.low_option_id
    end

    test "a high Option from different OptionCategory returns changeset" do
      %{option: option, decision: decision} = create_option()
      deps = option_category_range_vote_deps(decision) |> Map.put(:high_option, option)
      attrs = valid_attrs(deps)

      result = Voting.upsert_option_category_range_vote(deps.decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.high_option_id
    end

    test "a Participant from different decision returns changeset" do
      %{participant: participant} = create_participant()
      deps = option_category_range_vote_deps() |> Map.put(:participant, participant)
      attrs = valid_attrs(deps)

      result = Voting.upsert_option_category_range_vote(deps.decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.participant_id
    end

    test "with empty data returns errors" do
      decision = create_decision()

      result = Voting.upsert_option_category_range_vote(decision, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "can't be blank" in errors.participant_id
      assert "can't be blank" in errors.low_option_id
      assert "can't be blank" in errors.option_category_id
    end

    test "with invalid data returns errors" do
      decision = create_decision()

      result = Voting.upsert_option_category_range_vote(decision, invalid_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.participant_id
      assert "does not exist" in errors.low_option_id
      assert "does not exist" in errors.high_option_id
      assert "does not exist" in errors.option_category_id
    end

  end

  describe "delete_option_category_range_vote/2" do

    test "deletes" do
      %{option_category_range_vote: existing} = deps = create_option_category_range_vote()
      %{option_category: option_category, decision: decision, participant: participant, low_option: low_option, high_option: high_option} = deps
      to_delete = %OptionCategoryRangeVote{id: existing.id}

      result = Voting.delete_option_category_range_vote(to_delete, decision.id)
      assert {:ok, %OptionCategoryRangeVote{}} = result
      assert nil == Repo.get(OptionCategoryRangeVote, existing.id)
      assert nil !== Repo.get(Decision, decision.id)
      assert nil !== Repo.get(Participant, participant.id)
      assert nil !== Repo.get(Option, low_option.id)
      assert nil !== Repo.get(Option, high_option.id)
      assert nil !== Repo.get(OptionCategory, option_category.id)

    end

  end

  describe "documentation" do
    test "has documentation module" do
      assert %{} = OptionCategoryRangeVote.strings()
      assert %{} = OptionCategoryRangeVote.examples()
      assert is_list(OptionCategoryRangeVote.fields())
    end
  end
end
