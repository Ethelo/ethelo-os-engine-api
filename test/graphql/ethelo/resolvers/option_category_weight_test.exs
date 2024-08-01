defmodule GraphQL.EtheloApi.Resolvers.OptionCategoryWeightTest do
  @moduledoc """
  Validations and basic access for "OptionCategoryWeight" resolver, used to load option_category_weight records
  through graphql.
  Note: Functionality is provided through the OptionCategoryWeightResolver.OptionCategoryWeight context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Voting.OptionCategoryWeightTest`
  """
  use EtheloApi.DataCase
  @moduletag option_category_weight: true, graphql: true

  import EtheloApi.Voting.Factory
  import EtheloApi.Voting.TestHelper.OptionCategoryWeightHelper

  alias EtheloApi.Voting
  alias EtheloApi.Voting.OptionCategoryWeight
  alias Ecto.Changeset
  alias GraphQL.EtheloApi.Resolvers.OptionCategoryWeight, as: OptionCategoryWeightResolver

  describe "list/2" do

    test "returns records matching a Decision" do
      %{option_category_weight: first, decision: decision} = create_option_category_weight()
      %{option_category_weight: second} = create_option_category_weight(decision)

      parent = %{decision: decision}
      args = %{}
      result = OptionCategoryWeightResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionCategoryWeight{}, %OptionCategoryWeight{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "filters by OptionCategoryWeight.participant_id" do
      %{option_category_weight: matching, decision: decision} = create_option_category_weight()
      create_option_category_weight(decision)

      parent = %{decision: decision}
      args = %{participant_id: matching.participant_id}
      result = OptionCategoryWeightResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionCategoryWeight{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by OptionCategoryWeight.option_category_id" do
      %{option_category_weight: matching, decision: decision} = create_option_category_weight()
      create_option_category_weight(decision)

      parent = %{decision: decision}
      args = %{option_category_id: matching.option_category_id}
      result = OptionCategoryWeightResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionCategoryWeight{}] = result
      assert_result_ids_match([matching], result)
    end

    test "no OptionCategoryWeight matches" do
      decision = create_decision()

      parent = %{decision: decision}
      args = %{}
      result = OptionCategoryWeightResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [] = result
    end
  end

  describe "upsert/2" do
    test "creates with valid data" do
      deps = option_category_weight_deps()
      %{decision: decision} = deps

      attrs = deps |> valid_attrs()
      result = OptionCategoryWeightResolver.upsert(decision, attrs)

      assert {:ok, %OptionCategoryWeight{} = new_record} = result
      assert attrs.weighting == new_record.weighting
      assert attrs.option_category_id == new_record.option_category_id
      assert attrs.participant_id == new_record.participant_id
    end

    test "returns a list of errors with invalid data" do
      deps = option_category_weight_deps()
      %{decision: decision} = deps
      delete_participant(deps.participant)
      delete_option_category(deps.option_category)

      attrs = deps |> invalid_attrs()
      result = OptionCategoryWeightResolver.upsert(decision, attrs)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> errors_on() |> Map.keys()
      assert :participant_id in errors
      assert :option_category_id in errors
      assert :weighting in errors
      assert [_, _, _,] = errors
    end

    test "updates with valid data" do
      deps = create_option_category_weight()
      %{decision: decision} = deps

      attrs = deps |> valid_attrs()
      result = OptionCategoryWeightResolver.upsert(decision, attrs)

      assert {:ok, %OptionCategoryWeight{} = updated} = result
      assert attrs.weighting == updated.weighting
      assert attrs.option_category_id == updated.option_category_id
      assert attrs.participant_id == updated.participant_id
    end

    test "deletes" do
      deps = create_option_category_weight()
      %{option_category_weight: option_category_weight, decision: decision} = deps

      attrs = deps |> valid_attrs() |> Map.put(:delete, true)

      result = OptionCategoryWeightResolver.upsert(decision, attrs)

      assert {:ok, nil} = result
      assert nil == Voting.get_option_category_weight(option_category_weight.id, decision)
    end

  end
end
