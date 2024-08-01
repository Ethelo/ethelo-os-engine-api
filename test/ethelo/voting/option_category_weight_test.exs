defmodule EtheloApi.Voting.OptionCategoryWeightTest do
  @moduledoc """
  Validations and basic access for OptionCategoryWeights
  Includes both the context EtheloApi.Structure, and specific functionality on the OptionCategoryWeight schema
  """
  use EtheloApi.DataCase
  import EtheloApi.Voting.Factory
  import EtheloApi.Voting.TestHelper.OptionCategoryWeightHelper

  alias EtheloApi.Voting
  alias EtheloApi.Voting.OptionCategoryWeight
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.OptionCategory
  alias EtheloApi.Voting.Participant

  describe "list_option_category_weights/1" do

    test "returns all records matching a Decision" do
      create_option_category_weight() # should not be returned
      [first, second] = create_pair()

      result = Voting.list_option_category_weights(first.decision)
      assert [%OptionCategoryWeight{}, %OptionCategoryWeight{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "returns all records matching a Participant" do
      [first, _] = create_pair()
      decision = first.decision
      filters = %{participant_id: first.participant_id}

      result = Voting.list_option_category_weights(decision, filters)

      assert [%OptionCategoryWeight{}] = result
      assert_result_ids_match([first], result)
    end

    test "returns all records matching an OptionCategory" do
      [first, _] = create_pair()
      decision = first.decision
      filters = %{option_category_id: first.option_category_id}

      result = Voting.list_option_category_weights(decision, filters)

      assert [%OptionCategoryWeight{}] = result
      assert_result_ids_match([first], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Voting.list_option_category_weights(nil) end
    end
  end

  describe "get_option_category_weight/2" do

    test "returns the matching record by Decision object" do
      %{option_category_weight: record, decision: decision} = create_option_category_weight()

      result = Voting.get_option_category_weight(record.id, decision)

      assert %OptionCategoryWeight{} = result
      assert result.id == record.id
    end

    test "returns the matching record by Decision.id" do
      %{option_category_weight: record, decision: decision} = create_option_category_weight()

      result = Voting.get_option_category_weight(record.id, decision.id)

      assert %OptionCategoryWeight{} = result
      assert result.id == record.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Voting.get_option_category_weight(1, nil) end
    end

    test "raises without an OptionCategoryWeight id" do
      assert_raise ArgumentError, ~r/OptionCategoryWeight/,
        fn -> Voting.get_option_category_weight(nil, create_decision()) end
    end

    test "returns nil if id does not exist" do
      decision = create_decision()

      result = Voting.get_option_category_weight(1929, decision.id)

      assert result == nil
    end

    test "returns nil with invalid decision id " do
      %{option_category_weight: record} = create_option_category_weight()
      decision2 = create_decision()

      result = Voting.get_option_category_weight(record.id, decision2)

      assert result == nil
    end
  end

  describe "upsert_option_category_weight/2 " do

    test "creates with valid data" do
      deps = option_category_weight_deps()
      attrs = valid_attrs(deps)

      result = Voting.upsert_option_category_weight(deps.decision, attrs)

      assert {:ok, %OptionCategoryWeight{} = new_record} = result
      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == deps.decision.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Voting.upsert_option_category_weight(nil, invalid_attrs()) end
    end

    test "Duplicate dependencies upserts" do
      deps = create_option_category_weight()
      attrs = valid_attrs(deps)

      result = Voting.upsert_option_category_weight(deps.decision, attrs)

      assert {:ok, %OptionCategoryWeight{} = updated_record} = result

      assert_equivalent(attrs, updated_record)
      assert updated_record.decision_id == deps.decision.id
      assert updated_record.id == deps.option_category_weight.id
    end


    test "OptionCategory from different decision returns changeset" do
      %{option_category: option_category} = create_option_category()
      deps = option_category_weight_deps() |> Map.put(:option_category, option_category)
      attrs = valid_attrs(deps)

      result = Voting.upsert_option_category_weight(deps.decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.option_category_id
    end

    test "Participant from different decision returns changeset" do
      %{participant: participant} = create_participant()
      deps = option_category_weight_deps() |> Map.put(:participant, participant)
      attrs = valid_attrs(deps)

      result = Voting.upsert_option_category_weight(deps.decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.participant_id
    end

    test "with empty data returns errors" do
      decision = create_decision()

      result = Voting.upsert_option_category_weight(decision, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "can't be blank" in errors.weighting
      assert "can't be blank" in errors.participant_id
      assert "can't be blank" in errors.option_category_id
    end

    test "with invalid data returns errors" do
      decision = create_decision()

      result = Voting.upsert_option_category_weight(decision, invalid_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.participant_id
      assert "does not exist" in errors.option_category_id
      assert "is invalid" in errors.weighting
    end

  end

  describe "delete_option_category_weight/2" do

    test "deletes" do
      %{option_category_weight: existing, participant: participant, option_category: option_category, decision: decision} = create_option_category_weight()
      to_delete = %OptionCategoryWeight{id: existing.id}

      result = Voting.delete_option_category_weight(to_delete, decision.id)
      assert {:ok, %OptionCategoryWeight{}} = result
      assert nil == Repo.get(OptionCategoryWeight, existing.id)
      assert nil !== Repo.get(Decision, decision.id)
      assert nil !== Repo.get(Participant, participant.id)
      assert nil !== Repo.get(OptionCategory, option_category.id)

    end

  end

  describe "documentation" do
    test "has documentation module" do
      assert %{} = OptionCategoryWeight.strings()
      assert %{} = OptionCategoryWeight.examples()
      assert is_list(OptionCategoryWeight.fields())
    end
  end
end
