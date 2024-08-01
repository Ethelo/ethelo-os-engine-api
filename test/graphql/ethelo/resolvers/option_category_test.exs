defmodule GraphQL.EtheloApi.Resolvers.OptionCategoryTest do
  @moduledoc """
  Validations and basic access for "OptionCategory" resolver, used to load option_category records
  through graphql.
  Note: Functionality is provided through the OptionCategoryResolver.OptionCategory context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Structure.OptionCategoryTest`

  """
  use EtheloApi.DataCase
  @moduletag option_category: true, graphql: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.OptionCategoryHelper
  alias Kronky.ValidationMessage
  alias EtheloApi.Structure
  alias EtheloApi.Structure.OptionCategory
  alias Ecto.Changeset
  alias GraphQL.EtheloApi.Resolvers.OptionCategory, as: OptionCategoryResolver

  describe "list/2" do
    test "returns all OptionCategories for a Decision" do
      %{option_category: first, decision: decision} = create_option_category()
      %{option_category: second} = create_option_category(decision)

      parent = %{decision: decision}
      args = %{}
      result = OptionCategoryResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionCategory{} = first_result, %OptionCategory{}] = result
      assert_result_ids_match([first, second], result)
      refute %Ecto.Association.NotLoaded{} == first_result.options
    end

    test "filters by OptionCategory.id" do
      %{option_category: matching, decision: decision} = create_option_category()
      create_option_category(decision)

      parent = %{decision: decision}
      args = %{id: matching.id}
      result = OptionCategoryResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionCategory{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by OptionCategory.slug" do
      %{option_category: matching, decision: decision} = create_option_category()
      create_option_category(decision)

      parent = %{decision: decision}
      args = %{slug: matching.slug}
      result = OptionCategoryResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionCategory{}] = result
      assert_result_ids_match([matching], result)
    end

    test "no OptionCategory matches" do
      decision = create_decision()

      parent = %{decision: decision}
      args = %{}
      result = OptionCategoryResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [] = result
    end
  end

  describe "create/2" do
    test "creates with valid data" do
      deps = option_category_deps()
      %{decision: decision} = deps

      attrs = deps |> valid_attrs()
      result = OptionCategoryResolver.create(decision, attrs)

      assert {:ok, %OptionCategory{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "returns a changeset with invalid data" do
      deps = option_category_deps()
      %{decision: decision} = deps

      attrs = deps |> invalid_attrs() |> to_graphql_attrs()
      result = OptionCategoryResolver.create(decision, attrs)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> errors_on() |> Map.keys()
      assert [:apply_participant_weights, :budget_percent, :flat_fee, :info, :keywords,
             :quadratic, :scoring_mode, :slug, :sort, :title, :triangle_base,
             :vote_on_percent, :voting_style, :weighting, :xor] = errors
    end
  end

  describe "update/2" do

    test "updates with valid data" do
      deps = create_option_category()
      %{decision: decision} = deps

      attrs = deps |> valid_attrs()
      result = OptionCategoryResolver.update(decision, attrs)

      assert {:ok, %OptionCategory{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "returns errors when OptionCategory does not exist" do
      deps = create_option_category()
      %{option_category: option_category, decision: decision} = deps
      delete_option_category(option_category.id)

      attrs = deps |> valid_attrs()
      result = OptionCategoryResolver.update(decision, attrs)

      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "returns errors when Decision does not match" do
      deps = create_option_category()
      decision = create_decision()

      attrs = deps |> valid_attrs() |> to_graphql_attrs()
      result = OptionCategoryResolver.update(decision, attrs)

      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "returns a changeset with invalid data" do
      deps = create_option_category()
      %{decision: decision} = deps

      attrs = deps |> invalid_attrs()

      result = OptionCategoryResolver.update(decision, attrs)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> errors_on() |> Map.keys()
      assert [:apply_participant_weights, :budget_percent, :flat_fee, :info, :keywords,
             :quadratic, :scoring_mode, :slug, :sort, :title, :triangle_base,
             :vote_on_percent, :voting_style, :weighting, :xor] = errors
    end

  end

  describe "delete/2" do
    test "deletes" do
      %{decision: decision, option_category: existing} = create_option_category()

      attrs = %{decision_id: decision.id, id: existing.id}
      result = OptionCategoryResolver.delete(decision, attrs)

      assert {:ok, %OptionCategory{}} = result
      assert nil == Structure.get_option_category(existing.id, decision)
    end

    test "delete/2 does not return errors when OptionCategory does not exist" do
      %{decision: decision, option_category: existing} = create_option_category()
      delete_option_category(existing.id)

      attrs = %{decision_id: decision.id, id: existing.id}
      result = OptionCategoryResolver.delete(decision, attrs)

      assert {:ok, nil} = result
    end
  end

end
