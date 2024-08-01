defmodule EtheloApi.Structure.OptionCategoryTest do
  @moduledoc """
  Validations and basic access for OptionCategories
  Includes both the context EtheloApi.Structure, and specific functionality on the OptionCategory schema
  """
  use EtheloApi.DataCase
  @moduletag option_category: true, ethelo: true, ecto: true
  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.OptionCategoryHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.OptionCategory
  alias EtheloApi.Structure.Decision

  describe "list_option_categories/1" do

    test "returns all records matching a Decision" do
      create_option_category() # should not be returned
      %{option_category: first, decision: decision} = create_option_category()
      %{option_category: second} = create_option_category(decision)

      result = Structure.list_option_categories(decision)
      assert [%OptionCategory{} = first_result, %OptionCategory{}] = result
      assert_result_ids_match([first, second], result)
      refute %Ecto.Association.NotLoaded{} == first_result.options
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Structure.list_option_categories(nil) end
    end


    test "returns records matching ids" do
      %{option_category: first, decision: decision} = create_option_category()
      %{option_category: second} = create_option_category(decision)
      %{option_category: third} = create_option_category()

      result = Structure.list_option_categories(decision, %{}, [:id, :title])

      assert [%{id: _, title: _}, %{}] = result
      assert_result_ids_match([first, second], result)
      refute_id_in_result(third.id, result)
    end

    test "returns distinct records" do
      sort_10 = %{sort: 10}
      sort_0 = %{sort: 0}

      decision = create_decision();
      create_option_category(decision, sort_10)
      create_option_category(decision, sort_10)
      create_option_category(decision, sort_0)

      result = Structure.list_option_categories(decision, %{distinct: true}, [:sort])

      assert [_, _] = result
      assert sort_10 in result
      assert sort_0 in result
    end
  end

  describe "get_option_category/2" do

    test "returns the matching record by Decision object" do
      %{option_category: record, decision: decision} = create_option_category()

      result = Structure.get_option_category(record.id, decision)

      assert %OptionCategory{} = result
      assert result.id == record.id
    end

    test "returns the matching record by Decision.id" do
      %{option_category: record, decision: decision} = create_option_category()

      result = Structure.get_option_category(record.id, decision.id)

      assert %OptionCategory{} = result
      assert result.id == record.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Structure.get_option_category(1, nil) end
    end

    test "raises without an OptionCategory id" do
      assert_raise ArgumentError, ~r/OptionCategory/,
        fn -> Structure.get_option_category(nil, create_decision()) end
    end

    test "returns nil if id does not exist" do
      decision = create_decision()

      result = Structure.get_option_category(1929, decision.id)

      assert result == nil
    end

    test "returns nil with invalid decision id " do
      %{option_category: record} = create_option_category()
      decision2 = create_decision()

      result = Structure.get_option_category(record.id, decision2)

      assert result == nil
    end
  end

  describe "create_option_category/2 " do

    test "creates with valid data" do
      deps = option_category_deps()
      attrs = valid_attrs(deps)

      result = Structure.create_option_category(deps.decision, attrs)

      assert {:ok, %OptionCategory{} = new_record} = result

      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == deps.decision.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Structure.create_option_category(nil, invalid_attrs()) end
    end

    test "with empty data returns errors" do
      decision = create_decision()

      result = Structure.create_option_category(decision, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "can't be blank" in errors.title
      assert "can't be blank" in errors.weighting
      refute :info in Map.keys(errors)
    refute :sort in Map.keys(errors)
    end

    test "with invalid data returns errors" do
      decision = create_decision()

      attrs = invalid_attrs()
      result = Structure.create_option_category(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "must include at least one word" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.weighting
      assert "is invalid" in errors.info
      assert "is invalid" in errors.keywords
      assert "is invalid" in errors.xor
      assert "is invalid" in errors.apply_participant_weights
      assert "is invalid" in errors.scoring_mode
      assert "is invalid" in errors.triangle_base
      assert "is invalid" in errors.voting_style
      assert "is invalid" in errors.vote_on_percent
      assert "is invalid" in errors.quadratic
      assert "is invalid" in errors.sort
      assert [:apply_participant_weights, :budget_percent, :flat_fee, :info, :keywords,
      :quadratic, :scoring_mode, :slug, :sort, :title, :triangle_base,
      :vote_on_percent, :voting_style, :weighting, :xor] = Map.keys(errors)
    end

    test "an OptionDetail from different decision returns errors" do
      deps = option_category_with_detail_deps()
      %{decision: decision} = deps
      %{option_detail: option_detail} = create_option_detail()

      attrs =  deps |> Map.put(:primary_detail, option_detail) |> valid_attrs() |> Map.put(:scoring_mode, :triangle)

      result = Structure.create_option_category(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.primary_detail_id
    end

    test "an OptionDetail from same decision succeeds" do
      deps = option_category_with_detail_deps()
      %{decision: decision, primary_detail: option_detail} = deps

      attrs =  deps |> valid_attrs()

      result = Structure.create_option_category(decision, attrs)

      assert {:ok, %OptionCategory{} = new_record} = result
      assert option_detail.id == new_record.primary_detail_id
    end

    test "an low Option from different decision returns errors" do
      deps = option_category_with_detail_deps()
      %{decision: decision} = deps
      %{option: option} = create_option()

      attrs =  deps
        |> Map.put(:default_low_option, option)
        |> valid_attrs()
        |> Map.put(:scoring_mode, :triangle)

      result = Structure.create_option_category(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.default_low_option_id
    end

    test "an low Option from same decision succeeds" do
      %{decision: decision} = deps = option_category_with_detail_deps()
      %{option: option} = create_option(decision)

      attrs =  deps
        |> Map.put(:default_low_option, option)
        |> valid_attrs()
        |> Map.put(:scoring_mode, :triangle)

      result = Structure.create_option_category(decision, attrs)

      assert {:ok, %OptionCategory{} = new_record} = result
      assert option.id == new_record.default_low_option_id
    end

    test "an high Option from different decision returns errors" do
      deps = option_category_with_detail_deps()
      %{decision: decision} = deps
      %{option: option} = create_option()

      attrs =  deps
        |> Map.put(:default_high_option, option)
        |> valid_attrs()
        |> Map.put(:scoring_mode, :triangle)
        |> Map.put(:voting_style, :range)

      result = Structure.create_option_category(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.default_high_option_id
    end

    test "an high Option from same decision succeeds" do
      %{decision: decision} = deps = option_category_with_detail_deps()
      %{option: option} = create_option(decision)

      attrs =  deps
        |> Map.put(:default_high_option, option)
        |> valid_attrs()
        |> Map.put(:scoring_mode, :triangle)
        |> Map.put(:voting_style, :one)

      result = Structure.create_option_category(decision, attrs)

      assert {:ok, %OptionCategory{} = new_record} = result
      assert option.id == new_record.default_high_option_id
    end

    test "a duplicate title with no slug defined generates variant slug" do
      %{option_category: existing, decision: decision} = deps = create_option_category()

      attrs = deps |> valid_attrs() |> Map.put(:title, existing.title) |> Map.drop([:slug])
      result = Structure.create_option_category(decision, attrs)

      assert {:ok, %OptionCategory{} = new_record} = result

      refute existing.slug == new_record.slug
    end

    test "a duplicate slug returns errors" do
      %{option_category: existing, decision: decision} = deps = create_option_category()
      attrs = deps |> valid_attrs() |> Map.put(:slug, existing.slug)

      result = Structure.create_option_category(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "update_option_category/2" do
    test "updates with valid data" do
      %{option_category: existing, decision: decision} = deps = create_option_category()
      Structure.list_option_filters(decision)
      attrs = valid_attrs(deps)

      result = Structure.update_option_category(existing, attrs)

      assert {:ok, %OptionCategory{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "empty data returns errors" do
      %{option_category: existing} = create_option_category()

      result = Structure.update_option_category(existing, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "can't be blank" in errors.weighting
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      refute :info in Map.keys(errors)
      refute :keywords in Map.keys(errors)
      refute :sort in Map.keys(errors)
    end

    test "invalid data returns errors" do
      %{option_category: existing} = create_option_category()

      result = Structure.update_option_category(existing, invalid_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "must include at least one word" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.weighting
      assert "is invalid" in errors.info
      assert "is invalid" in errors.keywords
      assert "is invalid" in errors.xor
      assert "is invalid" in errors.apply_participant_weights
      assert "is invalid" in errors.scoring_mode
      assert "is invalid" in errors.vote_on_percent
      assert "is invalid" in errors.quadratic
      assert "is invalid" in errors.triangle_base
     assert "is invalid" in errors.sort
     assert [:apply_participant_weights, :budget_percent, :flat_fee, :info, :keywords,
     :quadratic, :scoring_mode, :slug, :sort, :title, :triangle_base,
     :vote_on_percent, :voting_style, :weighting, :xor] = Map.keys(errors)

    end

    test "Decision update ignored" do
      %{option_category: existing} = create_option_category()
      decision2 = create_decision()

      attrs = %{weighting: 43, decision: decision2}
      result = Structure.update_option_category(existing, attrs)

      assert {:ok, updated} = result
      assert updated.weighting == attrs.weighting
      refute updated.decision.id == decision2.id
      assert updated.decision.id == existing.decision_id
    end

    test "a duplicate title with no slug defined does not update slug" do
      %{option_category: first, decision: decision} = create_option_category()
      %{option_category: second} = deps = create_option_category(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, first.title) |> Map.drop([:slug])
      result = Structure.update_option_category(second, attrs)

      assert {:ok, %OptionCategory{} = updated} = result

      assert second.slug == updated.slug
    end

    test "a duplicate title with nil slug defined generates variant slug" do
      %{option_category: first, decision: decision} = create_option_category()
      %{option_category: second} = deps = create_option_category(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, first.title) |> Map.put(:slug, nil)
      result = Structure.update_option_category(second, attrs)

      assert {:ok, %OptionCategory{} = updated} = result
      refute second.slug == updated.slug
      refute second.slug == first.slug
    end

    test "a duplicate slug returns errors" do
      %{option_category: first, decision: decision} = create_option_category()
      %{option_category: second} = deps = create_option_category(decision)

      attrs = deps |> valid_attrs() |> Map.put(:slug, first.slug)
      result = Structure.update_option_category(second, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "delete_option_category/2" do

    test "deletes" do
      %{option_category: existing, decision: decision} = create_option_category()
      to_delete = %OptionCategory{id: existing.id}

      result = Structure.delete_option_category(to_delete, decision.id)
      assert {:ok, %OptionCategory{}} = result
      assert nil == Repo.get(OptionCategory, existing.id)
      assert nil !== Repo.get(Decision, decision.id)
    end

    test "deleting default OptionCategory returns error" do
      decision = create_decision()
      default_category = EtheloApi.Structure.Queries.OptionCategory.ensure_default_option_category(decision)

      result = Structure.delete_option_category(%OptionCategory{id: default_category.id}, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "cannot be deleted" in errors.id
      assert %OptionCategory{} = Repo.get(OptionCategory, default_category.id)
      assert nil !== Repo.get(Decision, decision.id)
    end

    test "deleting OptionCategory with options returns error" do
      %{decision: decision, option_category: option_category} = create_option()

      result = Structure.delete_option_category(%OptionCategory{id: option_category.id}, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "cannot be deleted" in errors.id
      assert %OptionCategory{} = Repo.get(OptionCategory, option_category.id)
      assert nil !== Repo.get(Decision, decision.id)
    end

  end

  describe "documentation" do
    test "has documentation module" do
      assert %{} = OptionCategory.strings()
      assert %{} = OptionCategory.examples()
      assert is_list(OptionCategory.fields())
    end
  end
end
