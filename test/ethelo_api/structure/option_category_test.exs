defmodule EtheloApi.Structure.OptionCategoryTest do
  @moduledoc """
  Validations and basic access for OptionCategories
  Includes both the context EtheloApi.Structure, and specific functionality on the OptionCategory schema
  """
  use EtheloApi.DataCase
  @moduletag option_category: true, ecto: true
  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.OptionCategoryHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.OptionCategory
  alias EtheloApi.Structure.Decision

  describe "list_option_categories/1" do
    test "filters by decision_id" do
      %{option_category: _excluded} = create_option_category()
      %{option_category: to_match1, decision: decision} = create_option_category()
      %{option_category: to_match2} = create_option_category(decision)

      result = Structure.list_option_categories(decision)
      assert [%OptionCategory{} = first_result, %OptionCategory{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
      refute %Ecto.Association.NotLoaded{} == first_result.options
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Structure.list_option_categories(nil) end
    end

    test "returns selected fields" do
      %{option_category: to_match1, decision: decision} = create_option_category()
      %{option_category: to_match2} = create_option_category(decision)

      result = Structure.list_option_categories(decision, %{}, [:id, :title])

      assert [%{id: _, title: _}, %{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "filters distinct records" do
      sort_10 = %{sort: 10}
      sort_0 = %{sort: 0}

      decision = create_decision()
      create_option_category(decision, sort_10)
      create_option_category(decision, sort_10)
      create_option_category(decision, sort_0)

      result = Structure.list_option_categories(decision, %{distinct: true}, [:sort])

      assert [_, _] = result
      assert sort_10 in result
      assert sort_0 in result
    end

    test "filters by id" do
      %{option_category: to_match, decision: decision} = create_option_category()
      %{option_category: _excluded} = create_option_category(decision)

      modifiers = %{id: to_match.id}
      result = Structure.list_option_categories(decision, modifiers)

      assert [%OptionCategory{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by slug" do
      %{option_category: to_match, decision: decision} = create_option_category()
      %{option_category: _excluded} = create_option_category(decision)

      modifiers = %{slug: to_match.slug}
      result = Structure.list_option_categories(decision, modifiers)

      assert [%OptionCategory{}] = result
      assert_result_ids_match([to_match], result)
    end
  end

  describe "get_option_category/2" do
    test "filters by decision_id as struct" do
      %{option_category: to_match, decision: decision} = create_option_category()

      result = Structure.get_option_category(to_match.id, decision)

      assert %OptionCategory{} = result
      assert result.id == to_match.id
    end

    test "filters by decision_id" do
      %{option_category: to_match, decision: decision} = create_option_category()

      result = Structure.get_option_category(to_match.id, decision.id)

      assert %OptionCategory{} = result
      assert result.id == to_match.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Structure.get_option_category(1, nil) end
    end

    test "raises without an OptionCategory id" do
      assert_raise ArgumentError, ~r/OptionCategory/, fn ->
        Structure.get_option_category(nil, create_decision())
      end
    end

    test "missing record returns nil" do
      decision = create_decision()

      result = Structure.get_option_category(1929, decision.id)

      assert result == nil
    end

    test "invalid Decision returns nil" do
      %{option_category: to_match} = create_option_category()
      decision2 = create_decision()

      result = Structure.get_option_category(to_match.id, decision2)
      assert result == nil
    end
  end

  describe "create_option_category/2" do
    test "creates with valid data" do
      %{decision: decision} = deps = option_category_deps()
      attrs = valid_attrs(deps)

      result = Structure.create_option_category(attrs, decision)

      assert {:ok, %OptionCategory{} = new_record} = result

      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn ->
        Structure.create_option_category(invalid_attrs(), nil)
      end
    end

    test "empty data returns changeset" do
      decision = create_decision()

      result = Structure.create_option_category(empty_attrs(), decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "can't be blank" in errors.weighting

      expected = [:title, :slug, :weighting]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      decision = create_decision()

      attrs = invalid_attrs()
      result = Structure.create_option_category(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "is invalid" in errors.apply_participant_weights
      assert "is invalid" in errors.info
      assert "is invalid" in errors.keywords
      assert "is invalid" in errors.quadratic
      assert "must include at least one word" in errors.results_title
      assert "is invalid" in errors.scoring_mode
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.sort
      assert "can't be blank" in errors.title
      assert "is invalid" in errors.triangle_base
      assert "is invalid" in errors.vote_on_percent
      assert "is invalid" in errors.voting_style
      assert "is invalid" in errors.weighting
      assert "is invalid" in errors.xor

      expected = [
        :apply_participant_weights,
        :budget_percent,
        :flat_fee,
        :info,
        :keywords,
        :quadratic,
        :results_title,
        :scoring_mode,
        :slug,
        :sort,
        :title,
        :triangle_base,
        :vote_on_percent,
        :voting_style,
        :weighting,
        :xor
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "OptionDetail from different Decision returns changeset" do
      %{decision: decision} =
        deps = option_category_with_detail_deps()

      %{option_detail: mismatch} = create_option_detail()

      attrs =
        deps
        |> Map.put(:primary_detail, mismatch)
        |> valid_attrs()
        |> Map.put(:scoring_mode, :triangle)

      result = Structure.create_option_category(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.primary_detail_id
    end

    test "OptionDetail from same Decision succeeds" do
      deps = option_category_with_detail_deps()
      %{decision: decision, primary_detail: option_detail} = deps

      attrs = deps |> valid_attrs()

      result = Structure.create_option_category(attrs, decision)

      assert {:ok, %OptionCategory{} = new_record} = result
      assert option_detail.id == new_record.primary_detail_id
    end

    test "LowOption from different Decision returns changeset" do
      deps = option_category_with_detail_deps()
      %{decision: decision} = deps
      %{option: mismatch} = create_option()

      attrs =
        deps
        |> Map.put(:default_low_option, mismatch)
        |> valid_attrs()
        |> Map.put(:scoring_mode, :triangle)

      result = Structure.create_option_category(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.default_low_option_id
    end

    test "LowOption from same Decision succeeds" do
      %{decision: decision} = deps = option_category_with_detail_deps()
      %{option: option} = create_option(decision)

      attrs =
        deps
        |> Map.put(:default_low_option, option)
        |> valid_attrs()
        |> Map.put(:scoring_mode, :triangle)

      result = Structure.create_option_category(attrs, decision)

      assert {:ok, %OptionCategory{} = new_record} = result
      assert option.id == new_record.default_low_option_id
    end

    test "HighOption from different Decision returns changeset" do
      deps = option_category_with_detail_deps()
      %{decision: decision} = deps
      %{option: mismatch} = create_option()

      attrs =
        deps
        |> Map.put(:default_high_option, mismatch)
        |> valid_attrs()
        |> Map.put(:scoring_mode, :triangle)
        |> Map.put(:voting_style, :range)

      result = Structure.create_option_category(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.default_high_option_id
    end

    test "HighOption from same Decision succeeds" do
      %{decision: decision} = deps = option_category_with_detail_deps()
      %{option: option} = create_option(decision)

      attrs =
        deps
        |> Map.put(:default_high_option, option)
        |> valid_attrs()
        |> Map.put(:scoring_mode, :triangle)
        |> Map.put(:voting_style, :one)

      result = Structure.create_option_category(attrs, decision)

      assert {:ok, %OptionCategory{} = new_record} = result
      assert option.id == new_record.default_high_option_id
    end

    test "duplicate title with no slug defined generates variant slug" do
      %{option_category: existing, decision: decision} = deps = create_option_category()

      attrs = deps |> valid_attrs() |> Map.put(:title, existing.title) |> Map.drop([:slug])
      result = Structure.create_option_category(attrs, decision)

      assert {:ok, %OptionCategory{} = new_record} = result

      refute existing.slug == new_record.slug
    end

    test "duplicate slug returns changeset" do
      %{option_category: existing, decision: decision} = deps = create_option_category()
      attrs = deps |> valid_attrs() |> Map.put(:slug, existing.slug)

      result = Structure.create_option_category(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "update_option_category/2" do
    test "updates with valid data" do
      %{option_category: to_update} = deps = create_option_category()
      attrs = valid_attrs(deps)

      result = Structure.update_option_category(to_update, attrs)

      assert {:ok, %OptionCategory{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "empty data returns changeset" do
      %{option_category: to_update} = create_option_category()

      result = Structure.update_option_category(to_update, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.weighting
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug

      expected = [:title, :slug, :weighting]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      %{option_category: to_update} = create_option_category()

      result = Structure.update_option_category(to_update, invalid_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "is invalid" in errors.apply_participant_weights
      assert "is invalid" in errors.info
      assert "is invalid" in errors.keywords
      assert "is invalid" in errors.quadratic
      assert "must include at least one word" in errors.results_title
      assert "is invalid" in errors.scoring_mode
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.sort
      assert "can't be blank" in errors.title
      assert "is invalid" in errors.triangle_base
      assert "is invalid" in errors.vote_on_percent
      assert "is invalid" in errors.weighting
      assert "is invalid" in errors.xor

      expected = [
        :apply_participant_weights,
        :budget_percent,
        :flat_fee,
        :info,
        :keywords,
        :quadratic,
        :results_title,
        :scoring_mode,
        :slug,
        :sort,
        :title,
        :triangle_base,
        :vote_on_percent,
        :voting_style,
        :weighting,
        :xor
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "Decision update ignored" do
      %{option_category: to_update} = create_option_category()
      decision2 = create_decision()

      attrs = %{weighting: 43, decision: decision2}
      result = Structure.update_option_category(to_update, attrs)

      assert {:ok, updated} = result
      assert updated.weighting == attrs.weighting
      refute updated.decision.id == decision2.id
      assert updated.decision.id == to_update.decision_id
    end

    test "duplicate title with no slug defined does not update slug" do
      %{option_category: duplicate, decision: decision} = create_option_category()
      %{option_category: to_update} = deps = create_option_category(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, duplicate.title) |> Map.drop([:slug])
      result = Structure.update_option_category(to_update, attrs)

      assert {:ok, %OptionCategory{} = updated} = result

      assert to_update.slug == updated.slug
    end

    test "duplicate title with nil slug defined generates variant slug" do
      %{option_category: duplicate, decision: decision} = create_option_category()
      %{option_category: to_update} = deps = create_option_category(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, duplicate.title) |> Map.put(:slug, nil)
      result = Structure.update_option_category(to_update, attrs)

      assert {:ok, %OptionCategory{} = updated} = result
      refute to_update.slug == updated.slug
      refute to_update.slug == duplicate.slug
    end

    test "duplicate slug returns changeset" do
      %{option_category: duplicate, decision: decision} = create_option_category()
      %{option_category: to_update} = deps = create_option_category(decision)

      attrs = deps |> valid_attrs() |> Map.put(:slug, duplicate.slug)
      result = Structure.update_option_category(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "delete_option_category/2" do
    test "deletes when is not default" do
      %{option_category: to_delete, decision: decision} = create_option_category()

      result = Structure.delete_option_category(to_delete, decision.id)
      assert {:ok, %OptionCategory{}} = result
      assert nil == Repo.get(OptionCategory, to_delete.id)
      assert nil !== Repo.get(Decision, decision.id)
    end

    test "deleting default OptionCategory returns changeset" do
      decision = create_decision()

      default_category =
        EtheloApi.Structure.Queries.OptionCategory.ensure_default_option_category(decision)

      result =
        Structure.delete_option_category(%OptionCategory{id: default_category.id}, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "cannot be deleted" in errors.id
      assert %OptionCategory{} = Repo.get(OptionCategory, default_category.id)
      assert nil !== Repo.get(Decision, decision.id)
    end

    test "deleting OptionCategory with Optionn returns changeset" do
      %{decision: decision, option_category: to_delete} = create_option()

      result = Structure.delete_option_category(%OptionCategory{id: to_delete.id}, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "cannot be deleted" in errors.id
      assert %OptionCategory{} = Repo.get(OptionCategory, to_delete.id)
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
