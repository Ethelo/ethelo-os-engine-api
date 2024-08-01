defmodule EtheloApi.Structure.OptionTest do
  @moduledoc """
  Validations and basic access for Options
  Includes both the context EtheloApi.Structure, and specific functionality on the Option schema
  """
  use EtheloApi.DataCase
  @moduletag option: true, ecto: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.OptionHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Option
  alias EtheloApi.Structure.OptionCategory

  describe "list_options/1" do
    test "filters by decision_id" do
      %{option: _excluded} = create_option()
      %{option: to_match1, decision: decision} = create_option()
      %{option: to_match2} = create_option(decision)

      result = Structure.list_options(decision)

      assert [%Option{} = first_result, %Option{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
      refute %Ecto.Association.NotLoaded{} == first_result.option_detail_values
    end

    test "filters by id" do
      %{option: to_match, decision: decision} = create_option()
      %{option: _excluded} = create_option(decision)

      modifiers = %{id: to_match.id}
      result = Structure.list_options(decision, modifiers)

      assert [%Option{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by slug" do
      %{option: to_match, decision: decision} = create_option()
      %{option: _excluded} = create_option(decision)

      modifiers = %{slug: to_match.slug}
      result = Structure.list_options(decision, modifiers)

      assert [%Option{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by option_category_id" do
      %{option: to_match, decision: decision} = create_option()
      %{option: _excluded} = create_option(decision)

      modifiers = %{option_category_id: to_match.option_category_id}
      result = Structure.list_options(decision, modifiers)

      assert [%Option{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by enabled" do
      decision = create_decision()
      %{option: to_match} = create_option(decision, %{enabled: true})
      %{option: _excluded} = create_option(decision, %{enabled: false})

      modifiers = %{enabled: to_match.enabled}
      result = Structure.list_options(decision, modifiers)

      assert [%Option{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by option_filter_id" do
      deps = create_option()
      %{decision: decision, option: to_match, option_category: option_category} = deps

      %{option_filter: option_filter} =
        create_option_category_filter_matching(decision, option_category, "in_category")

      %{option: _excluded} = create_option(decision)

      modifiers = %{option_filter_id: option_filter.id}
      result = Structure.list_options(decision, modifiers)

      assert [%Option{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Structure.list_options(nil) end
    end

    test "returns selected fields" do
      %{option: to_match1, decision: decision} = create_option()
      %{option: to_match2} = create_option(decision)

      result = Structure.list_options(decision, %{}, [:id, :title])

      assert [%{id: _, title: _}, %{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "filters distinct records" do
      sort_10 = %{sort: 10}
      sort_0 = %{sort: 0}

      decision = create_decision()
      create_option(decision, sort_10)
      create_option(decision, sort_10)
      create_option(decision, sort_0)

      result = Structure.list_options(decision, %{distinct: true}, [:sort])

      assert [_, _] = result
      assert sort_10 in result
      assert sort_0 in result
    end
  end

  describe "list_options_by_ids/1" do
    test "filters by ids" do
      %{option: to_match1, decision: decision} = create_option()
      %{option: to_match2} = create_option(decision)
      %{option: excluded1} = create_option(decision)
      %{option: excluded2} = create_option()

      result = Structure.list_options_by_ids([to_match1.id, to_match2.id, excluded2.id], decision)

      assert [%Option{} = first_result, %Option{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
      refute_id_in_result(excluded1.id, result)
      refute_id_in_result(excluded2.id, result)
      refute %Ecto.Association.NotLoaded{} == first_result.option_detail_values
    end

    test "empty id list returns empty list" do
      %{option: _, decision: decision} = create_option()

      result = Structure.list_options_by_ids([], decision.id)

      assert [] = result
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Structure.list_options_by_ids([], nil) end
    end
  end

  describe "get_option/2" do
    test "filters by decision_id as struct" do
      %{option: to_match, decision: decision} = create_option()

      result = Structure.get_option(to_match.id, decision)

      assert %Option{} = result
      assert result.id == to_match.id

      refute %Ecto.Association.NotLoaded{} == result.option_detail_values
    end

    test "filters by decision_id" do
      %{option: to_match, decision: decision} = create_option()

      result = Structure.get_option(to_match.id, decision.id)

      assert %Option{} = result
      assert result.id == to_match.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Structure.get_option(1, nil) end
    end

    test "raises without an Option id" do
      assert_raise ArgumentError, ~r/Option/, fn ->
        Structure.get_option(nil, create_decision())
      end
    end

    test "missing record returns nil" do
      decision = create_decision()

      result = Structure.get_option(1929, decision.id)

      assert result == nil
    end

    test "invalid Decision returns nil" do
      %{option: to_match} = create_option()
      decision2 = create_decision()

      result = Structure.get_option(to_match.id, decision2)

      assert result == nil
    end
  end

  describe "create_option/2" do
    test "creates with valid data" do
      deps = option_deps()
      %{decision: decision} = deps
      attrs = valid_attrs(deps)

      result = Structure.create_option(attrs, decision)

      assert {:ok, %Option{} = new_record} = result

      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "upserts default OptionCategory" do
      %{decision: decision} = deps = option_deps()
      attrs = valid_attrs(deps)

      assert nil == Structure.get_default_option_category(decision)

      Structure.create_option(attrs, decision)

      # default category created
      assert %OptionCategory{id: id} = Structure.get_default_option_category(decision)

      Structure.create_option(attrs, decision)

      # default category created
      assert %OptionCategory{id: ^id} = Structure.get_default_option_category(decision)
    end

    test "applies default OptionCategory if not supplied" do
      %{decision: decision} = deps = option_deps()
      attrs = deps |> valid_attrs() |> Map.drop([:option_category_id])

      result = Structure.create_option(attrs, decision)

      assert {:ok, %Option{} = new_record} = result

      option_category = Structure.get_default_option_category(decision)
      with_category = Map.put(attrs, :option_category_id, option_category.id)

      assert_equivalent(with_category, new_record)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn ->
        Structure.create_option(invalid_attrs(), nil)
      end
    end

    test "empty data returns changeset" do
      %{decision: decision} = option_deps()

      result = Structure.create_option(empty_attrs(), decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title

      expected = [:title, :slug]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      %{decision: decision} = option_deps()

      attrs = invalid_attrs()
      result = Structure.create_option(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.enabled
      assert "is invalid" in errors.sort
      expected = [:title, :slug, :enabled, :sort]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "duplicate title with no slug defined generates variant slug" do
      %{option: existing, decision: decision} = deps = create_option()
      attrs = deps |> valid_attrs() |> Map.put(:title, existing.title) |> Map.drop([:slug])

      result = Structure.create_option(attrs, decision)

      assert {:ok, %Option{} = new_record} = result

      refute existing.slug == new_record.slug
    end

    test "duplicate slug returns changeset" do
      %{option: existing, decision: decision} = deps = create_option()
      attrs = deps |> valid_attrs() |> Map.put(:slug, existing.slug)

      result = Structure.create_option(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "update_option/2" do
    test "updates with valid data" do
      deps = create_option()
      %{option: to_update} = deps
      attrs = valid_attrs(deps)

      result = Structure.update_option(to_update, attrs)

      assert {:ok, %Option{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "empty data returns changeset" do
      deps = create_option()
      %{option: to_update} = deps

      result = Structure.update_option(to_update, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      expected = [:title, :slug]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      %{option: to_update} = create_option()

      attrs = invalid_attrs()
      result = Structure.update_option(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.enabled
      assert "is invalid" in errors.sort
      expected = [:title, :slug, :enabled, :sort]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "OptionCategory from different Decision returns changeset" do
      %{option: to_update} = deps = create_option()
      %{option_category: mismatch} = create_option_category()

      attrs = deps |> Map.put(:option_category, mismatch) |> valid_attrs()
      result = Structure.update_option(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "does not exist" in errors.option_category_id
    end

    test "Decision update ignored" do
      %{option: to_update} = create_option()
      decision2 = create_decision()

      attrs = %{title: "Updated Title", decision: decision2}
      result = Structure.update_option(to_update, attrs)

      assert {:ok, updated} = result
      assert updated.title == attrs.title
      refute updated.decision.id == decision2.id
      assert updated.decision.id == to_update.decision_id
    end

    test "duplicate title with no slug defined does not update slug" do
      %{option: duplicate, decision: decision} = create_option()
      %{option: to_update} = deps = create_option(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, duplicate.title) |> Map.drop([:slug])
      result = Structure.update_option(to_update, attrs)

      assert {:ok, %Option{} = updated} = result

      assert to_update.slug == updated.slug
    end

    test "duplicate title with nil slug defined generates variant slug" do
      %{option: duplicate, decision: decision} = create_option()
      %{option: to_update} = deps = create_option(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, duplicate.title) |> Map.put(:slug, nil)
      result = Structure.update_option(to_update, attrs)

      assert {:ok, %Option{} = updated} = result
      refute to_update.slug == updated.slug
      refute to_update.slug == duplicate.slug
    end

    test "duplicate slug returns changeset" do
      %{option: duplicate, decision: decision} = create_option()
      %{option: to_update} = deps = create_option(decision)

      attrs = deps |> valid_attrs() |> Map.put(:slug, duplicate.slug)
      result = Structure.update_option(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "update_option/2 with OptionDetailValues" do
    test "can create OptionDetailValues" do
      %{option: to_update, decision: decision, option_detail: option_detail1} =
        option_detail_value_deps()

      %{option_detail: option_detail2} = create_option_detail(decision)
      odv1 = %{option_detail_id: option_detail1.id, value: "1"}
      odv2 = %{option_detail_id: option_detail2.id, value: "2"}

      attrs = %{title: "test", option_detail_values: [odv1, odv2]}
      result = Structure.update_option(to_update, attrs)

      assert {:ok, %Option{} = updated} = result
      assert attrs.title == updated.title

      expected_odvs =
        Enum.map(
          attrs.option_detail_values,
          fn odv -> Map.put(odv, :option_id, to_update.id) end
        )

      assert_odvs_in_result(expected_odvs, updated.option_detail_values)
    end

    test "can update OptionDetailValues" do
      %{option: to_update, decision: decision, option_detail_value: to_update_odv1} =
        create_option_detail_value()

      %{option_detail_value: to_update_odv2} =
        create_option_detail_value(decision, to_update, "foo")

      odv_params =
        [to_update_odv1, to_update_odv2]
        |> Enum.map(fn odv -> %{option_detail_id: odv.option_detail_id, value: "test"} end)

      attrs = %{title: "test", option_detail_values: odv_params}
      result = Structure.update_option(to_update, attrs)

      assert {:ok, %Option{} = updated} = result

      expected_odvs =
        Enum.map(
          odv_params,
          fn odv -> Map.put(odv, :option_id, to_update.id) end
        )

      assert_odvs_in_result(expected_odvs, updated.option_detail_values)
    end

    test "can remove OptionDetailValues" do
      %{option: to_update, decision: decision} = create_option_detail_value()
      create_option_detail_value(decision, to_update, "foo")

      attrs = %{title: "test", option_detail_values: []}
      result = Structure.update_option(to_update, attrs)

      assert {:ok, %Option{} = updated} = result

      assert [] == updated.option_detail_values
    end

    test "can update without changing OptionDetailValues" do
      %{option: to_update, decision: decision} = create_option_detail_value()
      create_option_detail_value(decision, to_update, "foo")

      to_update = Option |> preload(:option_detail_values) |> EtheloApi.Repo.get(to_update.id)

      attrs = %{title: "test"}
      result = Structure.update_option(to_update, attrs)

      assert {:ok, %Option{} = updated} = result
      assert_odvs_in_result(to_update.option_detail_values, updated.option_detail_values)
    end

    test "invalid OptionDetailValue data returns changeset" do
      %{option: to_update} = create_option_detail_value()

      invalid1 = %{value: "foo"}
      invalid2 = %{}
      attrs = %{title: "@", option_detail_values: [invalid1, invalid2]}

      result = Structure.update_option(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)

      expected_errors = [
        %{},
        %{option_detail_id: ["can't be blank"]},
        %{option_detail_id: ["can't be blank"]}
      ]

      assert expected_errors == errors.option_detail_values
    end

    test "can replace existing OptionDetailValues assocation with new list" do
      %{option: to_update, decision: decision, option_detail_value: to_update_odv1} =
        create_option_detail_value()

      %{option_detail_value: to_update_odv2} =
        create_option_detail_value(decision, to_update, "foo")

      %{option_detail_value: _excluded_odv} =
        create_option_detail_value(decision, to_update, "foo")

      option_detail_values = [
        %{option_detail_id: to_update_odv1.option_detail_id, value: "10"},
        %{option_detail_id: to_update_odv2.option_detail_id, value: "20"}
      ]

      attrs = %{title: "foo", option_detail_values: option_detail_values}

      result = Structure.update_option(to_update, attrs)

      assert {:ok, %Option{} = updated} = result

      expected_odvs =
        Enum.map(
          option_detail_values,
          fn odv -> Map.put(odv, :option_id, to_update.id) end
        )

      assert_odvs_in_result(expected_odvs, updated.option_detail_values)
    end
  end

  describe "delete_option/2" do
    test "deletes" do
      %{option: to_delete, decision: decision, option_category: option_category} = create_option()

      result = Structure.delete_option(to_delete, decision.id)
      assert {:ok, %Option{}} = result
      assert nil == Repo.get(Option, to_delete.id)
      assert nil !== Repo.get(Decision, decision.id)
      assert nil !== Repo.get(OptionCategory, option_category.id)
    end
  end

  describe "documentation" do
    test "has documentation module" do
      assert %{} = Option.strings()
      assert %{} = Option.examples()
      assert is_list(Option.fields())
    end
  end
end
