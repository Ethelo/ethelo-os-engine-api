defmodule EtheloApi.Voting.OptionCategoryRangeVoteTest do
  @moduledoc """
  Validations and basic access for OptionCategoryRangeVotes
  Includes both the context EtheloApi.Structure, and specific functionality on the OptionCategoryRangeVote schema
  """
  use EtheloApi.DataCase
  @moduletag option_category_range_vote: true, ecto: true

  import EtheloApi.Voting.Factory
  alias EtheloApi.Structure.Factory, as: StructureFactory
  import EtheloApi.Voting.TestHelper.OptionCategoryRangeVoteHelper

  alias EtheloApi.Voting
  alias EtheloApi.Voting.Participant
  alias EtheloApi.Voting.OptionCategoryRangeVote
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Option
  alias EtheloApi.Structure.OptionCategory

  describe "list_option_category_range_votes/1" do
    test "filters by decision_id" do
      %{option_category_range_vote: _excluded} = create_option_category_range_vote()
      [to_match1, to_match2] = create_pair()

      result = Voting.list_option_category_range_votes(to_match1.decision)
      assert [%OptionCategoryRangeVote{}, %OptionCategoryRangeVote{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "filters by participant_id" do
      [to_match, _excluded] = create_pair()
      decision = to_match.decision
      modifiers = %{participant_id: to_match.participant_id}

      result = Voting.list_option_category_range_votes(decision, modifiers)

      assert [%OptionCategoryRangeVote{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by option_category_id" do
      [to_match, _excluded] = create_pair()
      decision = to_match.decision
      modifiers = %{option_category_id: to_match.option_category_id}

      result = Voting.list_option_category_range_votes(decision, modifiers)
      assert [%OptionCategoryRangeVote{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn ->
        Voting.list_option_category_range_votes(nil)
      end
    end
  end

  describe "get_option_category_range_vote/2" do
    test "filters by decision_id as struct" do
      %{option_category_range_vote: to_match, decision: decision} =
        create_option_category_range_vote()

      result = Voting.get_option_category_range_vote(to_match.id, decision)

      assert %OptionCategoryRangeVote{} = result
      assert result.id == to_match.id
    end

    test "filters by decision_id" do
      %{option_category_range_vote: to_match, decision: decision} =
        create_option_category_range_vote()

      result = Voting.get_option_category_range_vote(to_match.id, decision.id)

      assert %OptionCategoryRangeVote{} = result
      assert result.id == to_match.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn ->
        Voting.get_option_category_range_vote(1, nil)
      end
    end

    test "raises without an OptionCategoryRangeVote id" do
      assert_raise ArgumentError, ~r/OptionCategoryRangeVote/, fn ->
        Voting.get_option_category_range_vote(nil, create_decision())
      end
    end

    test "missing record returns nil" do
      decision = create_decision()

      result = Voting.get_option_category_range_vote(1929, decision.id)

      assert result == nil
    end

    test "invalid Decision returns nil" do
      %{option_category_range_vote: to_match} = create_option_category_range_vote()
      decision2 = create_decision()

      result = Voting.get_option_category_range_vote(to_match.id, decision2)

      assert result == nil
    end
  end

  describe "upsert_option_category_range_vote/2" do
    test "creates with valid data" do
      %{decision: decision} = deps = option_category_range_vote_deps()

      attrs = valid_attrs(deps)

      result = Voting.upsert_option_category_range_vote(attrs, decision)

      assert {:ok, %OptionCategoryRangeVote{} = new_record} = result

      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "upserts existing record" do
      %{
        decision: decision,
        option_category: option_category,
        option_category_range_vote: option_category_range_vote
      } =
        deps = create_option_category_range_vote()

      %{option: option} =
        EtheloApi.Structure.Factory.create_option(decision, %{
          option_category: option_category
        })

      attrs = Map.put(deps, :high_option_id, option.id) |> valid_attrs()

      result = Voting.upsert_option_category_range_vote(attrs, decision)
      all_range_votes = Voting.list_option_category_range_votes(decision)

      assert {:ok, %OptionCategoryRangeVote{} = updated_record} = result
      assert_equivalent(attrs, updated_record)
      assert updated_record.decision_id == decision.id
      assert updated_record.id == option_category_range_vote.id
      assert length(all_range_votes) == 1
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn ->
        Voting.upsert_option_category_range_vote(invalid_attrs(), nil)
      end
    end

    test "empty data returns changeset" do
      decision = create_decision()

      result = Voting.upsert_option_category_range_vote(empty_attrs(), decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.participant_id
      assert "can't be blank" in errors.low_option_id
      assert "can't be blank" in errors.option_category_id
      expected = [:participant_id, :low_option_id, :option_category_id]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      decision = create_decision()

      result = Voting.upsert_option_category_range_vote(invalid_attrs(), decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.participant_id
      assert "does not exist" in errors.low_option_id
      assert "does not exist" in errors.high_option_id
      assert "does not exist" in errors.option_category_id
      expected = [:participant_id, :low_option_id, :high_option_id, :option_category_id]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "OptionCategory from different Decision returns changeset" do
      %{option_category: mismatch} = create_option_category()
      %{decision: decision} = deps = option_category_range_vote_deps()
      attrs = deps |> Map.put(:option_category, mismatch) |> valid_attrs()

      result = Voting.upsert_option_category_range_vote(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.option_category_id
    end

    test "LowOption from different Decision returns changeset" do
      %{option: mismatch} = create_option()
      %{decision: decision} = deps = option_category_range_vote_deps()
      attrs = deps |> Map.put(:low_option, mismatch) |> valid_attrs()

      result = Voting.upsert_option_category_range_vote(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.low_option_id
    end

    test "HighOption from different Decision returns changeset" do
      %{option: mismatch} = create_option()
      %{decision: decision} = deps = option_category_range_vote_deps()
      attrs = deps |> Map.put(:high_option, mismatch) |> valid_attrs()

      result = Voting.upsert_option_category_range_vote(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.high_option_id
    end

    test "LowOption from different OptionCategory returns changeset" do
      %{decision: decision} = deps = option_category_range_vote_deps()
      %{option: mismatch} = StructureFactory.create_option(decision)

      attrs = deps |> Map.put(:low_option, mismatch) |> valid_attrs()

      result = Voting.upsert_option_category_range_vote(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.low_option_id
    end

    test "HighOption from different OptionCategory returns changeset" do
      %{decision: decision} = deps = option_category_range_vote_deps()
      %{option: mismatch} = StructureFactory.create_option(decision)
      attrs = deps |> Map.put(:high_option, mismatch) |> valid_attrs()

      result = Voting.upsert_option_category_range_vote(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.high_option_id
    end

    test "Participant from different Decision returns changeset" do
      %{participant: mismatch} = create_participant()
      %{decision: decision} = deps = option_category_range_vote_deps()

      attrs = deps |> Map.put(:participant, mismatch) |> valid_attrs()

      result = Voting.upsert_option_category_range_vote(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.participant_id
    end
  end

  describe "delete_option_category_range_vote/2" do
    test "deletes" do
      deps = create_option_category_range_vote()

      %{
        option_category_range_vote: to_delete,
        option_category: option_category,
        decision: decision,
        participant: participant,
        low_option: low_option,
        high_option: high_option
      } = deps

      result = Voting.delete_option_category_range_vote(to_delete, decision.id)
      assert {:ok, %OptionCategoryRangeVote{}} = result
      assert nil == Repo.get(OptionCategoryRangeVote, to_delete.id)
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
