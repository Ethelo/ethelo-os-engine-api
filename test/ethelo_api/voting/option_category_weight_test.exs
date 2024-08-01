defmodule EtheloApi.Voting.OptionCategoryWeightTest do
  @moduledoc """
  Validations and basic access for OptionCategoryWeights
  Includes both the context EtheloApi.Structure, and specific functionality on the OptionCategoryWeight schema
  """
  use EtheloApi.DataCase
  @moduletag option_category_weight: true, ecto: true

  import EtheloApi.Voting.Factory
  import EtheloApi.Voting.TestHelper.OptionCategoryWeightHelper

  alias EtheloApi.Voting
  alias EtheloApi.Voting.OptionCategoryWeight
  alias EtheloApi.Voting.Participant
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.OptionCategory

  describe "list_option_category_weights/1" do
    test "filters by decision_id" do
      %{option_category_weight: _excluded} = create_option_category_weight()
      [to_match1, to_match2] = create_pair()

      result = Voting.list_option_category_weights(to_match1.decision)
      assert [%OptionCategoryWeight{}, %OptionCategoryWeight{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "filters by participant_id" do
      [to_match, _excluded] = create_pair()
      decision = to_match.decision
      modifiers = %{participant_id: to_match.participant_id}

      result = Voting.list_option_category_weights(decision, modifiers)

      assert [%OptionCategoryWeight{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by option_category_id" do
      [to_match, _excluded] = create_pair()
      decision = to_match.decision
      modifiers = %{option_category_id: to_match.option_category_id}

      result = Voting.list_option_category_weights(decision, modifiers)

      assert [%OptionCategoryWeight{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Voting.list_option_category_weights(nil) end
    end
  end

  describe "get_option_category_weight/2" do
    test "filters by decision_id as struct" do
      %{option_category_weight: to_match, decision: decision} = create_option_category_weight()

      result = Voting.get_option_category_weight(to_match.id, decision)

      assert %OptionCategoryWeight{} = result
      assert result.id == to_match.id
    end

    test "filters by decision_id" do
      %{option_category_weight: to_match, decision: decision} = create_option_category_weight()

      result = Voting.get_option_category_weight(to_match.id, decision.id)

      assert %OptionCategoryWeight{} = result
      assert result.id == to_match.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn ->
        Voting.get_option_category_weight(1, nil)
      end
    end

    test "raises without an OptionCategoryWeight id" do
      assert_raise ArgumentError, ~r/OptionCategoryWeight/, fn ->
        Voting.get_option_category_weight(nil, create_decision())
      end
    end

    test "missing record returns nil" do
      decision = create_decision()

      result = Voting.get_option_category_weight(1929, decision.id)

      assert result == nil
    end

    test "invalid Decision returns nil" do
      %{option_category_weight: to_match} = create_option_category_weight()
      decision2 = create_decision()

      result = Voting.get_option_category_weight(to_match.id, decision2)

      assert result == nil
    end
  end

  describe "upsert_option_category_weight/2" do
    test "creates with valid data" do
      %{decision: decision} = deps = option_category_weight_deps()
      attrs = valid_attrs(deps)

      result = Voting.upsert_option_category_weight(attrs, decision)

      assert {:ok, %OptionCategoryWeight{} = new_record} = result
      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "upserts existing record" do
      %{decision: decision} = deps = create_option_category_weight()
      attrs = valid_attrs(deps)

      result = Voting.upsert_option_category_weight(attrs, decision)

      assert {:ok, %OptionCategoryWeight{} = updated_record} = result

      assert_equivalent(attrs, updated_record)
      assert updated_record.decision_id == decision.id
      assert updated_record.id == deps.option_category_weight.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn ->
        Voting.upsert_option_category_weight(invalid_attrs(), nil)
      end
    end

    test "empty data returns changeset" do
      decision = create_decision()

      result = Voting.upsert_option_category_weight(empty_attrs(), decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.weighting
      assert "can't be blank" in errors.participant_id
      assert "can't be blank" in errors.option_category_id
      expected = [:participant_id, :option_category_id, :weighting]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      decision = create_decision()

      result = Voting.upsert_option_category_weight(invalid_attrs(), decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.participant_id
      assert "does not exist" in errors.option_category_id
      assert "must be less than or equal to 100" in errors.weighting
      expected = [:participant_id, :option_category_id, :weighting]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "OptionCategory from different Decision returns changeset" do
      %{option_category: mismatch} = create_option_category()
      %{decision: decision} = deps = option_category_weight_deps()
      attrs = deps |> Map.put(:option_category, mismatch) |> valid_attrs()

      result = Voting.upsert_option_category_weight(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.option_category_id
    end

    test "Participant from different Decision returns changeset" do
      %{participant: mismatch} = create_participant()
      %{decision: decision} = deps = option_category_weight_deps()
      attrs = deps |> Map.put(:participant, mismatch) |> valid_attrs()

      result = Voting.upsert_option_category_weight(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.participant_id
    end
  end

  describe "delete_option_category_weight/2" do
    test "deletes" do
      %{
        option_category_weight: to_delete,
        participant: participant,
        option_category: option_category,
        decision: decision
      } = create_option_category_weight()

      result = Voting.delete_option_category_weight(to_delete, decision.id)
      assert {:ok, %OptionCategoryWeight{}} = result
      assert nil == Repo.get(OptionCategoryWeight, to_delete.id)
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
