defmodule EtheloApi.Structure.OptionFilterTest do
  @moduledoc """
  Validations and basic access for OptionFilters
  Includes both the context EtheloApi.Structure, and specific functionality on the OptionFilter schema
  """
  use EtheloApi.DataCase
  @moduletag option_filter: true, ecto: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.OptionFilterHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.OptionFilter
  alias EtheloApi.Structure.OptionCategory
  alias EtheloApi.Structure.OptionDetail

  describe "list_option_filters/1" do
    test "filters by decision_id" do
      %{option_filter: _excluded} = create_option_detail_filter()
      %{option_filter: to_match1, decision: decision} = create_option_detail_filter()
      %{option_filter: to_match2} = create_option_category_filter(decision)

      result = Structure.list_option_filters(decision)
      assert [%OptionFilter{}, %OptionFilter{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Structure.list_option_filters(nil) end
    end

    test "filters by id" do
      %{option_filter: to_match, decision: decision} = create_option_detail_filter()
      %{option_filter: _excluded} = create_option_detail_filter(decision)

      modifiers = %{id: to_match.id}
      result = Structure.list_option_filters(decision, modifiers)

      assert [%OptionFilter{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by slug" do
      %{option_filter: to_match, decision: decision} = create_option_detail_filter()
      %{option_filter: _excluded} = create_option_detail_filter(decision)

      modifiers = %{slug: to_match.slug}
      result = Structure.list_option_filters(decision, modifiers)

      assert [%OptionFilter{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by option_category_id" do
      %{option_filter: to_match, decision: decision} = create_option_category_filter()
      %{option_filter: _excluded} = create_option_category_filter(decision)

      modifiers = %{option_category_id: to_match.option_category_id}
      result = Structure.list_option_filters(decision, modifiers)

      assert [%OptionFilter{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by option_detail_id" do
      %{option_filter: to_match, decision: decision} = create_option_detail_filter()
      %{option_filter: _excluded} = create_option_detail_filter(decision)

      modifiers = %{option_detail_id: to_match.option_detail_id}
      result = Structure.list_option_filters(decision, modifiers)

      assert [%OptionFilter{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "Decision without OptionDetails returns empty array" do
      decision = create_decision()

      result = Structure.list_option_filters(decision)
      assert [] = result
      assert_result_ids_match([], result)
    end
  end

  describe "option_ids_matching_filter/2" do
    # see EtheloApi.Structure.FilterBuilder for full tests, this just tests the interface

    test "returns Option ids" do
      deps = create_option_detail_value(:integer)

      %{
        decision: decision,
        option_detail: option_detail,
        option_detail_value: option_detail_value
      } = deps

      %{option_filter: option_filter} =
        create_option_detail_filter(decision, option_detail, option_detail_value.value)

      result = Structure.option_ids_matching_filter(option_filter)

      assert [_] = result
    end
  end

  describe "get_option_filter/2" do
    test "filters by decision_id as struct" do
      %{option_filter: to_match, decision: decision} = create_option_detail_filter()

      result = Structure.get_option_filter(to_match.id, decision)

      assert %OptionFilter{} = result
      assert result.id == to_match.id
    end

    test "filters by decision_id" do
      %{option_filter: to_match, decision: decision} = create_option_detail_filter()

      result = Structure.get_option_filter(to_match.id, decision.id)

      assert %OptionFilter{} = result
      assert result.id == to_match.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Structure.get_option_filter(1, nil) end
    end

    test "raises without an OptionFilter id" do
      assert_raise ArgumentError, ~r/OptionFilter/, fn ->
        Structure.get_option_filter(nil, create_decision())
      end
    end

    test "missing record returns nil" do
      decision = create_decision()

      result = Structure.get_option_filter(1929, decision.id)

      assert result == nil
    end

    test "invalid Decision returns nil" do
      %{option_filter: to_match} = create_option_detail_filter()
      decision2 = create_decision()

      result = Structure.get_option_filter(to_match.id, decision2)

      assert result == nil
    end
  end

  describe "create_option_filter/2" do
    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn ->
        Structure.create_option_filter(invalid_attrs(), nil)
      end
    end

    test "empty data returns changeset" do
      decision = create_decision()

      result = Structure.create_option_filter(empty_attrs(), decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "can't be blank" in errors.match_mode
      assert hd(errors.option_category_id) =~ ~r/must specify either/
      assert hd(errors.option_detail_id) =~ ~r/must specify either/
      expected = [:title, :slug, :match_mode, :option_category_id, :option_detail_id]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      decision = create_decision()

      attrs = invalid_attrs()

      result = Structure.create_option_filter(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "must include at least one word" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.match_mode

      assert "is invalid" in errors.option_category_id
      assert "is invalid" in errors.option_detail_id

      expected = [
        :match_mode,
        :option_category_id,
        :option_detail_id,
        :slug,
        :title
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "both OptionDetail and OptionCategory defined returns changeset" do
      deps = option_detail_filter_deps()
      %{decision: decision} = deps
      %{option_category: option_category} = create_option_category(decision)

      attrs = deps |> valid_attrs() |> Map.put(:option_category_id, option_category.id)

      result = Structure.create_option_filter(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert hd(errors.option_category_id) =~ ~r/must be blank/
      expected = [:option_category_id]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "create_option_filter/2 with OptionDetail" do
    test "creates with valid data" do
      deps = option_detail_filter_deps()
      %{decision: decision} = deps
      attrs = valid_attrs(deps)

      result = Structure.create_option_filter(attrs, decision)

      assert {:ok, %OptionFilter{} = new_record} = result

      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "duplicate config returns changeset" do
      deps = create_option_detail_filter()
      %{decision: decision, option_filter: existing} = deps
      attrs = valid_attrs(deps)

      attrs =
        attrs
        |> Map.put(:slug, "foobar")
        |> Map.put(:match_value, existing.match_value)
        |> Map.put(:match_mode, existing.match_mode)

      result = Structure.create_option_filter(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.match_value
    end

    test "OptionDetail from different Decision returns changeset" do
      deps = option_detail_filter_deps()
      %{decision: decision} = deps
      %{option_detail: mismatch} = create_option_detail()

      attrs = deps |> Map.put(:option_detail, mismatch) |> valid_attrs()

      result = Structure.create_option_filter(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.option_detail_id
    end
  end

  describe "create_option_filter/2 with OptionCategory" do
    test "creates with valid data" do
      deps = option_category_filter_deps()
      %{decision: decision} = deps
      attrs = valid_attrs(deps)

      result = Structure.create_option_filter(attrs, decision)

      assert {:ok, %OptionFilter{} = new_record} = result

      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "duplicate config returns changeset" do
      deps = create_option_category_filter()
      %{decision: decision, option_filter: existing} = deps
      attrs = valid_attrs(deps)

      attrs =
        attrs
        |> Map.put(:slug, "foobar")
        |> Map.put(:match_value, existing.match_value)
        |> Map.put(:match_mode, existing.match_mode)

      result = Structure.create_option_filter(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.match_mode
    end

    test "OptionCategory from different Decision returns changeset" do
      %{decision: decision} = deps = option_category_filter_deps()
      %{option_category: mismatch} = create_option_category()

      attrs = deps |> Map.put(:option_category, mismatch) |> valid_attrs()
      #   result = Structure.create_option_filter(attrs, decision)

      result =
        attrs
        |> Structure.OptionFilter.create_changeset(decision)
        |> EtheloApi.Repo.insert()

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.option_category_id
    end
  end

  describe "create_option_filter/2 all_options OptionFilter" do
    test "duplicate all_options filter returns changeset" do
      decision = create_decision()

      attrs = all_options() |> Map.put(:slug, "foo")
      result = Structure.create_option_filter(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.match_mode
    end
  end

  describe "create_option_filter/2 OptionCategory match modes" do
    @category_match_modes ~w(in_category not_in_category)

    test "allows category match modes with OptionCategory associated" do
      deps = option_category_filter_deps()
      %{decision: decision} = deps
      attrs = deps |> valid_attrs() |> Map.put(:slug, "")

      for match_mode <- @category_match_modes do
        attrs = %{attrs | match_mode: match_mode, title: match_mode}

        result = Structure.create_option_filter(attrs, decision)

        assert {:ok, %OptionFilter{} = option_filter} = result
        assert %OptionFilter{match_mode: ^match_mode} = option_filter
      end
    end

    test "disallows category match modes with OptionDetail associated" do
      deps = option_detail_filter_deps(:string)
      %{decision: decision} = deps
      attrs = deps |> valid_attrs() |> Map.put(:slug, "")

      for match_mode <- @category_match_modes do
        attrs = %{attrs | match_mode: match_mode, title: match_mode}

        result = Structure.create_option_filter(attrs, decision)

        assert {:error, %Ecto.Changeset{} = changeset} = result
        errors = error_map(changeset) |> Map.keys()
        assert :option_detail_id in errors
      end
    end
  end

  describe "create_option_filter/2 slug checks" do
    test "duplicate title with no slug defined generates variant slug" do
      deps = create_option_detail_filter()
      %{option_filter: existing, decision: decision} = deps

      attrs = deps |> valid_attrs() |> Map.put(:title, existing.title) |> Map.drop([:slug])
      result = Structure.create_option_filter(attrs, decision)

      assert {:ok, %OptionFilter{} = new_record} = result

      refute existing.slug == new_record.slug
    end

    test "duplicate slug returns changeset" do
      deps = create_option_detail_filter()
      %{option_filter: existing, decision: decision} = deps
      attrs = deps |> valid_attrs() |> Map.put(:slug, existing.slug)

      result = Structure.create_option_filter(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "update_option_filter/2" do
    test "empty data returns changeset" do
      %{option_filter: to_update} = create_option_detail_filter()

      result = Structure.update_option_filter(to_update, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "can't be blank" in errors.match_mode
      assert hd(errors.option_category_id) =~ ~r/must specify either/
      assert hd(errors.option_detail_id) =~ ~r/must specify either/
      expected = [:title, :slug, :match_mode, :option_category_id, :option_detail_id]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      %{option_filter: to_update} = create_option_detail_filter()

      result = Structure.update_option_filter(to_update, invalid_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "must include at least one word" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.match_mode
      assert "is invalid" in errors.option_category_id
      assert "is invalid" in errors.option_detail_id
      expected = [:title, :slug, :match_mode, :option_category_id, :option_detail_id]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "both OptionDetail and OptionCategory defined returns changeset" do
      deps = create_option_category_filter()
      %{option_filter: to_update, decision: decision} = deps
      %{option_detail: option_detail} = create_option_detail(decision)

      attrs = deps |> valid_attrs() |> Map.put(:option_detail_id, option_detail.id)

      result = Structure.update_option_filter(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert hd(errors.option_detail_id) =~ ~r/must specify either/
    end

    test "Decision update ignored" do
      %{option_filter: to_update} = create_option_detail_filter()
      decision2 = create_decision()

      attrs = %{title: "Updated Title", decision: decision2}
      result = Structure.update_option_filter(to_update, attrs)

      assert {:ok, updated} = result
      assert updated.title == attrs.title
      refute updated.decision.id == decision2.id
      assert updated.decision.id == to_update.decision_id
    end
  end

  describe "update_option_filter/2 with OptionDetail" do
    test "updates with valid data" do
      deps = create_option_detail_filter()
      %{option_filter: to_update} = deps
      attrs = valid_attrs(deps)

      result = Structure.update_option_filter(to_update, attrs)

      assert {:ok, %OptionFilter{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "OptionDetail from different Decision returns changeset" do
      deps = create_option_detail_filter()
      %{option_filter: to_update} = deps
      %{option_detail: mismatch} = create_option_detail()
      attrs = deps |> Map.put(:option_detail, mismatch) |> valid_attrs()

      result = Structure.update_option_filter(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.option_detail_id
    end
  end

  describe "update_option_filter/2 with OptionCategory" do
    test "updates with valid data" do
      %{option_filter: to_update} = deps = create_option_category_filter()
      attrs = valid_attrs(deps)

      result = Structure.update_option_filter(to_update, attrs)

      assert {:ok, %OptionFilter{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "OptionCategory from different Decision returns changeset" do
      deps = create_option_category_filter()
      %{option_filter: to_update} = deps
      %{option_category: mismatch} = create_option_category()
      attrs = deps |> Map.put(:option_category, mismatch) |> valid_attrs()

      result = Structure.update_option_filter(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.option_category_id
    end
  end

  describe "update_option_filter/2 with all_options OptionFilter" do
    test "updates to all_options_filter returns changeset" do
      deps = create_all_options_filter()
      %{option_filter: to_update} = deps

      attrs = %{match_mode: "equals", title: "Updated", slug: "updated"}
      result = Structure.update_option_filter(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "cannot be changed" in errors.id
    end
  end

  describe "update_option_filter/2 slug checks" do
    test "duplicate title with no slug defined does not update slug" do
      %{option_filter: duplicate, decision: decision} = create_option_detail_filter()
      %{option_filter: to_update} = deps = create_option_detail_filter(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, duplicate.title) |> Map.drop([:slug])
      result = Structure.update_option_filter(to_update, attrs)

      assert {:ok, %OptionFilter{} = updated} = result

      assert to_update.slug == updated.slug
    end

    test "duplicate title with nil slug defined generates variant slug" do
      %{option_filter: duplicate, decision: decision} = create_option_detail_filter()
      %{option_filter: to_update} = deps = create_option_detail_filter(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, duplicate.title) |> Map.put(:slug, nil)
      result = Structure.update_option_filter(to_update, attrs)

      assert {:ok, %OptionFilter{} = updated} = result
      refute to_update.slug == updated.slug
      refute to_update.slug == duplicate.slug
    end

    test "duplicate slug returns changeset" do
      %{option_filter: duplicate, decision: decision} = create_option_detail_filter()
      %{option_filter: to_update} = deps = create_option_detail_filter(decision)

      attrs = deps |> valid_attrs() |> Map.put(:slug, duplicate.slug)
      result = Structure.update_option_filter(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "delete_option_filter/2" do
    test "deletes detail filter" do
      %{option_filter: to_delete, decision: decision, option_detail: option_detail} =
        create_option_detail_filter()

      result = Structure.delete_option_filter(to_delete, decision.id)
      assert {:ok, %OptionFilter{}} = result
      assert nil == Repo.get(OptionFilter, to_delete.id)
      assert nil !== Repo.get(Decision, decision.id)
      assert nil !== Repo.get(OptionDetail, option_detail.id)
    end

    test "deletes category filter" do
      %{option_filter: to_delete, decision: decision, option_category: option_category} =
        create_option_category_filter()

      result = Structure.delete_option_filter(to_delete, decision.id)
      assert {:ok, %OptionFilter{}} = result
      assert nil == Repo.get(OptionFilter, to_delete.id)
      assert nil !== Repo.get(Decision, decision.id)
      assert nil !== Repo.get(OptionCategory, option_category.id)
    end

    test "deleting all options OptionFilter returns changeset" do
      deps = create_all_options_filter()
      %{option_filter: to_delete, decision: decision} = deps

      result = Structure.delete_option_filter(to_delete, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "cannot be deleted" in errors.id
      assert %OptionFilter{} = Repo.get(OptionFilter, to_delete.id)
      assert nil !== Repo.get(Decision, decision.id)
    end
  end

  describe "documentation" do
    test "has documentation module" do
      assert %{} = OptionFilter.strings()
      assert %{} = OptionFilter.examples()
      assert is_list(OptionFilter.fields())
    end
  end
end
