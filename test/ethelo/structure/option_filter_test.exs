defmodule EtheloApi.Structure.OptionFilterTest do
  @moduledoc """
  Validations and basic access for OptionFilters
  Includes both the context EtheloApi.Structure, and specific functionality on the OptionFilter schema
  """
  use EtheloApi.DataCase
  @moduletag option_filter: true, ethelo: true, ecto: true
  import EtheloApi.Structure.Factory

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.OptionFilter
  alias EtheloApi.Structure.OptionCategory
  alias EtheloApi.Structure.OptionDetail

  @empty_attrs %{slug: nil, title: nil, match_mode: nil, match_value: nil, option_detail_id: nil, option_category_id: nil}
  @invalid_attrs %{slug: " ", title: "@@@", match_mode: "not valid mode", match_value: "", option_detail_id: "foo", option_category_id: false}
  @all_options OptionFilter.all_options_values()

  def base_attrs() do
    %{slug: "slug", title: "Title", option_detail_id: nil, option_category_id: nil}
  end

  def valid_attrs(%{option_detail: %OptionDetail{} = option_detail}) do
    base_attrs()
    |> Map.put(:option_detail_id, option_detail.id)
    |> Map.put(:match_mode, "equals")
    |> Map.put(:match_value, "foo")
  end

  def valid_attrs(%{option_category: %OptionCategory{} = option_category}) do
    base_attrs()
    |> Map.put(:option_category_id, option_category.id)
    |> Map.put(:match_mode, "in_category")
    |> Map.put(:match_value, "")
  end

  def assert_equivalent(expected, result) do
    assert expected.title == result.title
    assert_equivalent_slug(expected.slug, result.slug)
    assert expected.match_value == result.match_value
    assert expected.match_mode == result.match_mode
    if Map.has_key?(expected, :option_detail_id) do
      assert expected.option_detail_id == result.option_detail_id
    end
    if Map.has_key?(expected, :option_category_id) do
      assert expected.option_category_id == result.option_category_id
    end
  end

  describe "list_option_filters/1" do

    test "returns all records matching a Decision" do
      create_option_detail_filter() # should not be returned
      %{option_filter: first, decision: decision} = create_option_detail_filter()
      %{option_filter: second} = create_option_category_filter(decision)

      result = Structure.list_option_filters(decision)
      assert [%OptionFilter{}, %OptionFilter{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "returns record matching id" do
      %{option_filter: matching, decision: decision} = create_option_detail_filter()
      %{option_filter: _not_matching} = create_option_detail_filter(decision)

      filters = %{id: matching.id}
      result = Structure.list_option_filters(decision, filters)

      assert [%OptionFilter{}] = result
      assert_result_ids_match([matching], result)
    end

    test "returns record matching slug" do
      %{option_filter: matching, decision: decision} = create_option_detail_filter()
      %{option_filter: _not_matching} = create_option_detail_filter(decision)

      filters = %{slug: matching.slug}
      result = Structure.list_option_filters(decision, filters)

      assert [%OptionFilter{}] = result
      assert_result_ids_match([matching], result)
    end

    test "returns records matching an OptionCategory" do
      %{option_filter: matching, decision: decision} = create_option_category_filter()
      %{option_filter: _not_matching} = create_option_category_filter(decision)

      filters = %{option_category_id: matching.option_category_id}
      result = Structure.list_option_filters(decision, filters)

      assert [%OptionFilter{}] = result
      assert_result_ids_match([matching], result)
    end

    test "returns records matching an OptionDetail" do
      %{option_filter: matching, decision: decision} = create_option_detail_filter()
      %{option_filter: _not_matching} = create_option_detail_filter(decision)

      filters = %{option_detail_id: matching.option_detail_id}
      result = Structure.list_option_filters(decision, filters)

      assert [%OptionFilter{}] = result
      assert_result_ids_match([matching], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Structure.list_option_filters(nil) end
    end

    test "decision without details returns empty array" do
      decision = create_decision()

      result = Structure.list_option_filters(decision)
      assert [] = result
      assert_result_ids_match([], result)
    end
  end

  describe "option_ids_matching_filter/2" do
    # see EtheloApi.Constraints.FilterBuilder for full tests, this just tests the interface

    test "returns option ids" do
      deps = create_option_detail_value(:integer)
      %{decision: decision, option_detail: option_detail, option_detail_value: option_detail_value} = deps
      %{option_filter: option_filter} = create_option_detail_filter(decision, option_detail, option_detail_value.value)

      result = Structure.option_ids_matching_filter(option_filter)

      assert [_] = result
    end
  end

  describe "get_option_filter/2" do

    test "returns the matching record by Decision object" do
      %{option_filter: record, decision: decision} = create_option_detail_filter()

      result = Structure.get_option_filter(record.id, decision)

      assert %OptionFilter{} = result
      assert result.id == record.id
    end

    test "returns the matching record by Decision.id" do
      %{option_filter: record, decision: decision} = create_option_detail_filter()

      result = Structure.get_option_filter(record.id, decision.id)

      assert %OptionFilter{} = result
      assert result.id == record.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Structure.get_option_filter(1, nil) end
    end

    test "raises without an OptionFilter id" do
      assert_raise ArgumentError, ~r/OptionFilter/,
        fn -> Structure.get_option_filter(nil, create_decision()) end
    end

    test "returns nil if id does not exist" do
      decision = create_decision()

      result = Structure.get_option_filter(1929, decision.id)

      assert result == nil
    end

    test "returns nil with invalid decision id " do
      %{option_filter: record} = create_option_detail_filter()
      decision2 = create_decision()

      result = Structure.get_option_filter(record.id, decision2)

      assert result == nil
    end
  end


  describe "create_option_filter/2" do
    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Structure.create_option_filter(nil, @invalid_attrs) end
    end

    test "with empty data returns errors" do
      decision = create_decision()

      result = Structure.create_option_filter(decision, @empty_attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "can't be blank" in errors.title
      assert "can't be blank" in errors.match_mode
      assert hd(errors.option_category_id) =~ ~r/can't be blank/
      assert hd(errors.option_detail_id) =~ ~r/can't be blank/
      refute :match_value in Map.keys(errors)
      assert [_, _, _, _, _] = Map.keys(errors)
    end

    test "with invalid data returns errors" do
      decision = create_decision()

      result = Structure.create_option_filter(decision, @invalid_attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "must include at least one word" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.option_category_id
      assert "is invalid" in errors.option_detail_id
      refute :match_mode in Map.keys(errors)
      refute :match_value in Map.keys(errors)
      assert [_, _, _, _] = Map.keys(errors)
    end

    test "with both OptionDetail and OptionCategory defined returns errors" do
      deps = option_detail_filter_deps()
      %{decision: decision} = deps
      %{option_category: option_category} = create_option_category(decision)

      attrs = deps |> valid_attrs() |> Map.put(:option_category_id, option_category.id)

      result = Structure.create_option_filter(decision,  attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert hd(errors.option_category_id) =~ ~r/must be blank/
      assert hd(errors.option_detail_id) =~ ~r/must be blank/
      assert [_, _] = Map.keys(errors)
    end
  end

  describe "create_option_filter/2 with OptionDetail" do
    test "creates with valid data" do
      deps = option_detail_filter_deps()
      %{decision: decision} = deps
      attrs = valid_attrs(deps)

      result = Structure.create_option_filter(decision, attrs)

      assert {:ok, %OptionFilter{} = new_record} = result

      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "a duplicate config returns errors" do
      deps = create_option_detail_filter()
      %{decision: decision, option_filter: existing} = deps
      attrs = valid_attrs(deps)

      attrs = attrs
        |> Map.put(:slug, "foobar")
        |> Map.put(:match_value, existing.match_value)
        |> Map.put(:match_mode, existing.match_mode)
      result = Structure.create_option_filter(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.match_value
    end

    test "an OptionDetail from different decision returns errors" do
      deps = option_detail_filter_deps()
      %{decision: decision} = deps
      %{option_detail: option_detail} = create_option_detail()

      attrs =  deps |> Map.put(:option_detail, option_detail) |> valid_attrs()

      result = Structure.create_option_filter(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.option_detail_id
    end
  end

  describe "create_option_filter/2 with OptionCategory" do
    test "creates with valid data" do
      deps = option_category_filter_deps()
      %{decision: decision} = deps
      attrs = valid_attrs(deps)

      result = Structure.create_option_filter(decision, attrs)

      assert {:ok, %OptionFilter{} = new_record} = result

      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "a duplicate config returns errors" do
      deps = create_option_category_filter()
      %{decision: decision, option_filter: existing} = deps
      attrs = valid_attrs(deps)

      attrs = attrs
        |> Map.put(:slug, "foobar")
        |> Map.put(:match_value, existing.match_value)
        |> Map.put(:match_mode, existing.match_mode)
      result = Structure.create_option_filter(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.match_mode
    end

    test "an OptionCategory from different decision returns errors" do
      %{decision: decision} = deps = option_category_filter_deps()
      %{option_category: option_category} = create_option_category()

      attrs =  deps |> Map.put(:option_category, option_category) |> valid_attrs()

      result = Structure.create_option_filter(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.option_category_id
    end
  end

  describe "create_option_filter/2 all_options OptionFilter" do

    test "cannot create" do
      decision = create_decision()

      attrs =  @all_options |> Map.put(:slug, "foo")
      result = Structure.create_option_filter(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.match_mode
    end
  end

  describe "create_option_filter/2 date match modes" do

    @date_match_modes ~w(
      date
      year month month_year day_of_month day_of_week day_of_year week_of_year
      hour_12 hour_24 minutes time_24_hour time_12_hour am_pm
    )

    test "allows date match modes with date detail" do
      deps = option_detail_filter_deps(:datetime)
      %{decision: decision} = deps
      attrs = deps |> valid_attrs() |> Map.put(:slug, "")

      for match_mode <- @date_match_modes do
        attrs = %{attrs | match_mode: match_mode, title: match_mode}

        result = Structure.create_option_filter(decision, attrs)

        assert {:ok, %OptionFilter{} = option_filter} = result
        assert %OptionFilter{match_mode: ^match_mode} = option_filter
      end
    end

    test "disallows date match modes with string detail" do
      deps = option_detail_filter_deps(:string)
      %{decision: decision} = deps
      attrs = deps |> valid_attrs() |> Map.put(:slug, "")

      for match_mode <- @date_match_modes do
        attrs = %{attrs | match_mode: match_mode, title: match_mode}

        result = Structure.create_option_filter(decision, attrs)

        assert {:error, %Ecto.Changeset{} = changeset} = result
        errors = errors_on(changeset)
        assert "is invalid" in errors.match_mode
      end
    end

    test "disallows date match modes with integer detail" do
      deps = option_detail_filter_deps(:integer)
      %{decision: decision} = deps
      attrs = deps |> valid_attrs() |> Map.put(:slug, "")

      for match_mode <- @date_match_modes do
        attrs = %{attrs | match_mode: match_mode, title: match_mode}

        result = Structure.create_option_filter(decision, attrs)

        assert {:error, %Ecto.Changeset{} = changeset} = result
        errors = errors_on(changeset)
        assert "is invalid" in errors.match_mode
      end
    end

    test "disallows date match modes with float detail" do
      deps = option_detail_filter_deps(:float)
      %{decision: decision} = deps
      attrs = deps |> valid_attrs() |> Map.put(:slug, "")

      for match_mode <- @date_match_modes do
        attrs = %{attrs | match_mode: match_mode, title: match_mode}

        result = Structure.create_option_filter(decision, attrs)

        assert {:error, %Ecto.Changeset{} = changeset} = result
        errors = errors_on(changeset)
        assert "is invalid" in errors.match_mode
      end
    end

    test "disallows date match modes with boolean detail" do
      deps = option_detail_filter_deps(:boolean)
      %{decision: decision} = deps
      attrs = deps |> valid_attrs() |> Map.put(:slug, "")

      for match_mode <- @date_match_modes do
        attrs = %{attrs | match_mode: match_mode, title: match_mode}

        result = Structure.create_option_filter(decision, attrs)

        assert {:error, %Ecto.Changeset{} = changeset} = result
        errors = errors_on(changeset)
        assert "is invalid" in errors.match_mode
      end
    end

    test "disallows equal match mode with date detail" do
      deps = option_detail_filter_deps(:datetime)
      %{decision: decision} = deps
      attrs = deps |> valid_attrs()

      result = Structure.create_option_filter(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "is invalid" in errors.match_mode
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

        result = Structure.create_option_filter(decision, attrs)

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

        result = Structure.create_option_filter(decision, attrs)

        assert {:error, %Ecto.Changeset{} = changeset} = result
        errors = errors_on(changeset)
        assert "is invalid" in errors.match_mode
      end
    end
  end

  describe "create_option_filter/2 slug checks" do

    test "duplicate title with no slug defined generates variant slug" do
      deps = create_option_detail_filter()
      %{option_filter: existing, decision: decision} = deps

      attrs = deps |> valid_attrs() |> Map.put(:title, existing.title) |> Map.drop([:slug])
      result = Structure.create_option_filter(decision, attrs)

      assert {:ok, %OptionFilter{} = new_record} = result

      refute existing.slug == new_record.slug
    end

    test "duplicate slug returns errors" do
      deps = create_option_detail_filter()
      %{option_filter: existing, decision: decision} = deps
      attrs = deps |> valid_attrs() |> Map.put(:slug, existing.slug)

      result = Structure.create_option_filter(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "update_option_filter/2" do
    test "empty data returns errors" do
      %{option_filter: existing} = create_option_detail_filter()

      result = Structure.update_option_filter(existing, @empty_attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "can't be blank" in errors.title
      assert "can't be blank" in errors.match_mode
      assert hd(errors.option_category_id) =~ ~r/can't be blank/
      assert hd(errors.option_detail_id) =~ ~r/can't be blank/
      assert "must have numbers and/or letters" in errors.slug
      refute :match_value in Map.keys(errors)
      assert [_, _, _, _, _] = Map.keys(errors)
    end

    test "invalid data returns errors" do
      %{option_filter: existing} = create_option_detail_filter()

      result = Structure.update_option_filter(existing, @invalid_attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "must include at least one word" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.match_mode
      assert "is invalid" in errors.option_category_id
      assert "is invalid" in errors.option_detail_id
      refute :match_value in Map.keys(errors)
      assert [_, _, _, _, _] = Map.keys(errors)
   end

    test "with both OptionDetail and OptionCategory defined returns errors" do
      deps = create_option_category_filter()
      %{option_filter: option_filter, decision: decision} = deps
      %{option_detail: option_detail} = create_option_detail(decision)

      attrs = deps |> valid_attrs() |> Map.put(:option_detail_id, option_detail.id)

      result = Structure.update_option_filter(option_filter, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert hd(errors.option_category_id) =~ ~r/must be blank/
      assert hd(errors.option_detail_id) =~ ~r/must be blank/
    end

    test "Decision update ignored" do
      %{option_filter: existing} = create_option_detail_filter()
      decision2 = create_decision()

      attrs = %{title: "Updated Title", decision: decision2}
      result = Structure.update_option_filter(existing, attrs)

      assert {:ok, updated} = result
      assert updated.title == attrs.title
      refute updated.decision.id == decision2.id
      assert updated.decision.id == existing.decision_id
    end
  end

  describe "update_option_filter/2 with OptionDetail" do
    test "succeeds with valid data" do
      deps = create_option_detail_filter()
      %{option_filter: existing} = deps
      attrs = valid_attrs(deps)

      result = Structure.update_option_filter(existing, attrs)

      assert {:ok, %OptionFilter{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "OptionDetail from different decision returns errors" do
      deps = create_option_detail_filter()
      %{option_filter: option_filter} = deps
      %{option_detail: option_detail} = create_option_detail()
      attrs = deps |> Map.put(:option_detail, option_detail) |> valid_attrs()

      result = Structure.update_option_filter(option_filter, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.option_detail_id
    end
  end

  describe "update_option_filter/2 with OptionCategory" do
    test "succeeds with valid data" do
      %{option_filter: existing} = deps = create_option_category_filter()
      attrs = valid_attrs(deps)

      result = Structure.update_option_filter(existing, attrs)

      assert {:ok, %OptionFilter{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "OptionCategory from different decision returns errors" do
      deps = create_option_category_filter()
      %{option_filter: option_filter} = deps
      %{option_category: option_category} = create_option_category()
      attrs = deps |> Map.put(:option_category, option_category) |> valid_attrs()

      result = Structure.update_option_filter(option_filter, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.option_category_id
    end
  end

  describe "update_option_filter/2 with all_options OptionFilter" do

    test "returns errors" do
      deps = create_all_options_filter()
      %{option_filter: option_filter} = deps

      attrs = %{match_mode: "equals", title: "Updated", slug: "updated"}
      result = Structure.update_option_filter(option_filter, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "cannot be changed" in errors.id
    end
  end

  describe "update_option_filter/2 slug checks" do

    test "a duplicate title with no slug defined does not update slug" do
      %{option_filter: first, decision: decision} = create_option_detail_filter()
      %{option_filter: second} = deps = create_option_detail_filter(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, first.title) |> Map.drop([:slug])
      result = Structure.update_option_filter(second, attrs)

      assert {:ok, %OptionFilter{} = updated} = result

      assert second.slug == updated.slug
    end

    test "a duplicate title with nil slug defined generates variant slug" do
      %{option_filter: first, decision: decision} = create_option_detail_filter()
      %{option_filter: second} = deps = create_option_detail_filter(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, first.title) |> Map.put(:slug, nil)
      result = Structure.update_option_filter(second, attrs)

      assert {:ok, %OptionFilter{} = updated} = result
      refute second.slug == updated.slug
      refute second.slug == first.slug
    end

    test "a duplicate slug returns errors" do
      %{option_filter: first, decision: decision} = create_option_detail_filter()
      %{option_filter: second} = deps = create_option_detail_filter(decision)

      attrs = deps |> valid_attrs() |> Map.put(:slug, first.slug)
      result = Structure.update_option_filter(second, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "delete_option_filter/2" do

    test "deletes detail filter" do
      %{option_filter: existing, decision: decision, option_detail: option_detail} = create_option_detail_filter()
      to_delete = %OptionFilter{id: existing.id}

      result = Structure.delete_option_filter(to_delete, decision.id)
      assert {:ok, %OptionFilter{}} = result
      assert nil == Repo.get(OptionFilter, existing.id)
      assert nil !== Repo.get(Decision, decision.id)
      assert nil !== Repo.get(OptionDetail, option_detail.id)
    end
    test "deletes category filter" do
      %{option_filter: existing, decision: decision, option_category: option_category} = create_option_category_filter()
      to_delete = %OptionFilter{id: existing.id}

      result = Structure.delete_option_filter(to_delete, decision.id)
      assert {:ok, %OptionFilter{}} = result
      assert nil == Repo.get(OptionFilter, existing.id)
      assert nil !== Repo.get(Decision, decision.id)
      assert nil !== Repo.get(OptionCategory, option_category.id)
  end

    test "deleting all options OptionFilter returns error" do
      deps = create_all_options_filter()
      %{option_filter: option_filter, decision: decision} = deps

      result = Structure.delete_option_filter(%OptionFilter{id: option_filter.id}, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "cannot be deleted" in errors.id
      assert %OptionFilter{} = Repo.get(OptionFilter, option_filter.id)
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
