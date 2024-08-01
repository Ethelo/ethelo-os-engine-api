defmodule EtheloApi.Structure.OptionTest do
  @moduledoc """
  Validations and basic access for Options
  Includes both the context EtheloApi.Structure, and specific functionality on the Option schema
  """
  use EtheloApi.DataCase
  @moduletag option: true, ethelo: true, ecto: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.OptionHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Option
  alias EtheloApi.Structure.OptionCategory

  describe "list_options/1" do
    test "returns records matching a Decision" do
      # should not be returned
      create_option()
      %{option: first, decision: decision} = create_option()
      %{option: second} = create_option(decision)

      result = Structure.list_options(decision)

      assert [%Option{} = first_result, %Option{}] = result
      assert_result_ids_match([first, second], result)
      refute %Ecto.Association.NotLoaded{} == first_result.option_detail_values
    end

    test "returns record matching id" do
      %{option: matching, decision: decision} = create_option()
      %{option: _not_matching} = create_option(decision)

      filters = %{id: matching.id}
      result = Structure.list_options(decision, filters)

      assert [%Option{}] = result
      assert_result_ids_match([matching], result)
    end

    test "returns record matching slug" do
      %{option: matching, decision: decision} = create_option()
      %{option: _not_matching} = create_option(decision)

      filters = %{slug: matching.slug}
      result = Structure.list_options(decision, filters)

      assert [%Option{}] = result
      assert_result_ids_match([matching], result)
    end

    test "returns records matching an OptionCategory" do
      %{option: matching, decision: decision} = create_option()
      %{option: _not_matching} = create_option(decision)

      filters = %{option_category_id: matching.option_category_id}
      result = Structure.list_options(decision, filters)

      assert [%Option{}] = result
      assert_result_ids_match([matching], result)
    end

    test "returns record matching enabled" do
      decision = create_decision()
      %{option: matching} = create_option(decision, %{enabled: true})
      %{option: _not_matching} = create_option(decision, %{enabled: false})

      filters = %{enabled: matching.enabled}
      result = Structure.list_options(decision, filters)

      assert [%Option{}] = result
      assert_result_ids_match([matching], result)
    end

    test "returns record matching OptionFilter" do
      deps = create_option()
      %{decision: decision, option: matching, option_category: option_category} = deps

      %{option_filter: option_filter} =
        create_option_category_filter_matching(decision, option_category, "in_category")

      %{option: _not_matching} = create_option(decision)

      filters = %{option_filter_id: option_filter.id}
      result = Structure.list_options(decision, filters)

      assert [%Option{}] = result
      assert_result_ids_match([matching], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Structure.list_options(nil) end
    end

    test "returns select fields" do
      %{option: first, decision: decision} = create_option()
      %{option: second} = create_option(decision)
      %{option: third} = create_option()

      result = Structure.list_options(decision, %{}, [:id, :title])

      assert [%{id: _, title: _}, %{}] = result
      assert_result_ids_match([first, second], result)
      refute_id_in_result(third.id, result)
    end

    test "returns distinct records" do
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
    test "returns records matching ids" do
      %{option: first, decision: decision} = create_option()
      %{option: second} = create_option(decision)
      %{option: third} = create_option(decision)
      %{option: fourth} = create_option()

      result = Structure.list_options_by_ids([first.id, second.id, fourth.id], decision)

      assert [%Option{} = first_result, %Option{}] = result
      assert_result_ids_match([first, second], result)
      refute_id_in_result(third.id, result)
      refute_id_in_result(fourth.id, result)
      refute %Ecto.Association.NotLoaded{} == first_result.option_detail_values
    end

    test "returns empty list with no ids" do
      %{option: _, decision: decision} = create_option()

      result = Structure.list_options_by_ids([], decision.id)

      assert [] = result
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Structure.list_options_by_ids([], nil) end
    end
  end

  describe "get_option/2" do
    test "returns the matching record by Decision object" do
      %{option: record, decision: decision} = create_option()

      result = Structure.get_option(record.id, decision)

      assert %Option{} = result
      assert result.id == record.id
      refute %Ecto.Association.NotLoaded{} == result.option_detail_values
    end

    test "returns the matching record by Decision.id" do
      %{option: record, decision: decision} = create_option()

      result = Structure.get_option(record.id, decision.id)

      assert %Option{} = result
      assert result.id == record.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Structure.get_option(1, nil) end
    end

    test "raises without an Option id" do
      assert_raise ArgumentError, ~r/Option/, fn ->
        Structure.get_option(nil, create_decision())
      end
    end

    test "returns nil if id does not exist" do
      decision = create_decision()

      result = Structure.get_option(1929, decision.id)

      assert result == nil
    end

    test "returns nil with invalid decision id " do
      %{option: record} = create_option()
      decision2 = create_decision()

      result = Structure.get_option(record.id, decision2)

      assert result == nil
    end
  end

  describe "create_option/2 " do
    test "creates with valid data" do
      deps = option_deps()
      %{decision: decision} = deps
      attrs = valid_attrs(deps)

      result = Structure.create_option(decision, attrs)

      assert {:ok, %Option{} = new_record} = result

      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "upserts default option category" do
      %{decision: decision} = deps = option_deps()
      attrs = valid_attrs(deps)

      assert nil == Structure.get_default_option_category(decision)

      Structure.create_option(decision, attrs)

      # default category created
      assert %OptionCategory{id: id} = Structure.get_default_option_category(decision)

      Structure.create_option(decision, attrs)

      # default category created
      assert %OptionCategory{id: ^id} = Structure.get_default_option_category(decision)
    end

    test "applies default option category if not supplied" do
      %{decision: decision} = deps = option_deps()
      attrs = deps |> valid_attrs() |> Map.drop([:option_category_id])

      result = Structure.create_option(decision, attrs)

      assert {:ok, %Option{} = new_record} = result

      option_category = Structure.get_default_option_category(decision)

      assert_equivalent(attrs, new_record)
      assert new_record.option_category_id == option_category.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn ->
        Structure.create_option(nil, invalid_attrs())
      end
    end

    test "with empty data returns errors" do
      %{decision: decision} = option_deps()

      result = Structure.create_option(decision, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "can't be blank" in errors.title
      refute :enabled in Map.keys(errors)
      refute :info in Map.keys(errors)
      refute :sort in Map.keys(errors)
      refute :results_title in Map.keys(errors)
      refute :determinative in Map.keys(errors)
      refute :option_category_id in Map.keys(errors)
      assert [_, _] = Map.keys(errors)
    end

    test "with invalid data returns errors" do
      %{decision: decision} = option_deps()

      attrs = invalid_attrs()
      result = Structure.create_option(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "must include at least one word" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.enabled
      assert "is invalid" in errors.sort
      assert "does not exist" in errors.option_category_id
      refute :info in Map.keys(errors)
      refute :determinative in Map.keys(errors)
      refute :results_title in Map.keys(errors)
      assert [_, _, _, _, _] = Map.keys(errors)
    end

    test "duplicate title with no slug defined generates variant slug" do
      %{option: existing, decision: decision} = deps = create_option()
      attrs = deps |> valid_attrs() |> Map.put(:title, existing.title) |> Map.drop([:slug])

      result = Structure.create_option(decision, attrs)

      assert {:ok, %Option{} = new_record} = result

      refute existing.slug == new_record.slug
    end

    test "duplicate slug returns errors" do
      %{option: existing, decision: decision} = deps = create_option()
      attrs = deps |> valid_attrs() |> Map.put(:slug, existing.slug)

      result = Structure.create_option(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "update_option/2" do
    test "updates with valid data" do
      deps = create_option()
      %{option: existing} = deps
      attrs = valid_attrs(deps)

      result = Structure.update_option(existing, attrs)

      assert {:ok, %Option{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "empty data returns errors" do
      deps = create_option()
      %{option: existing} = deps

      result = Structure.update_option(existing, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      refute :info in Map.keys(errors)
      refute :enabled in Map.keys(errors)
      refute :sort in Map.keys(errors)
      refute :option_category_id in Map.keys(errors)
      refute :determinative in Map.keys(errors)
      refute :results_title in Map.keys(errors)
      assert [_, _] = Map.keys(errors)
    end

    test "invalid data returns errors" do
      %{option: existing} = create_option()

      attrs = invalid_attrs()
      result = Structure.update_option(existing, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "must include at least one word" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.enabled
      assert "is invalid" in errors.sort
      assert "does not exist" in errors.option_category_id
      refute :determinative in Map.keys(errors)
      refute :results_title in Map.keys(errors)
      refute :info in Map.keys(errors)
      assert [_, _, _, _, _] = Map.keys(errors)
    end

    test "an OptionCategory from different decision returns errors" do
      deps = option_deps()
      %{decision: decision} = deps
      %{option_category: option_category} = create_option_category()

      attrs = deps |> Map.put(:option_category, option_category) |> valid_attrs()

      result = Structure.create_option(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "does not exist" in errors.option_category_id
    end

    test "Decision update ignored" do
      %{option: existing} = create_option()
      decision2 = create_decision()

      attrs = %{title: "Updated Title", decision: decision2}
      result = Structure.update_option(existing, attrs)

      assert {:ok, updated} = result
      assert updated.title == attrs.title
      refute updated.decision.id == decision2.id
      assert updated.decision.id == existing.decision_id
    end

    test "duplicate title with no slug defined does not update slug" do
      %{option: first, decision: decision} = create_option()
      %{option: second} = deps = create_option(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, first.title) |> Map.drop([:slug])
      result = Structure.update_option(second, attrs)

      assert {:ok, %Option{} = updated} = result

      assert second.slug == updated.slug
    end

    test "duplicate title with nil slug defined generates variant slug" do
      %{option: first, decision: decision} = create_option()
      %{option: second} = deps = create_option(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, first.title) |> Map.put(:slug, nil)
      result = Structure.update_option(second, attrs)

      assert {:ok, %Option{} = updated} = result
      refute second.slug == updated.slug
      refute second.slug == first.slug
    end

    test "duplicate slug returns errors" do
      %{option: first, decision: decision} = create_option()
      %{option: second} = deps = create_option(decision)

      attrs = deps |> valid_attrs() |> Map.put(:slug, first.slug)
      result = Structure.update_option(second, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "update_option/2 with OptionDetailValues" do
    test "can create OptionDetailValues" do
      %{option: option, decision: decision, option_detail: option_detail1} =
        option_detail_value_deps()

      %{option_detail: option_detail2} = create_option_detail(decision)
      first = %{option_detail_id: option_detail1.id, value: "1"}
      second = %{option_detail_id: option_detail2.id, value: "2"}

      attrs = %{title: "test", option_detail_values: [first, second]}
      result = Structure.update_option(option, attrs)

      assert {:ok, %Option{} = updated} = result
      assert attrs.title == updated.title

      expected_odvs =
        Enum.map(
          attrs.option_detail_values,
          fn odv -> Map.put(odv, :option_id, option.id) end
        )

      assert_odvs_in_result(expected_odvs, updated.option_detail_values)
    end

    test "can update OptionDetailValues" do
      %{option: option, decision: decision, option_detail_value: first} =
        create_option_detail_value()

      %{option_detail_value: second} = create_option_detail_value(decision, option, "foo")

      odv_params =
        [first, second]
        |> Enum.map(fn odv -> %{option_detail_id: odv.option_detail_id, value: "test"} end)

      attrs = %{title: "test", option_detail_values: odv_params}
      result = Structure.update_option(option, attrs)

      assert {:ok, %Option{} = updated} = result

      expected_odvs =
        Enum.map(
          odv_params,
          fn odv -> Map.put(odv, :option_id, option.id) end
        )

      assert_odvs_in_result(expected_odvs, updated.option_detail_values)
    end

    test "can remove OptionDetailValues" do
      %{option: option, decision: decision} = create_option_detail_value()
      create_option_detail_value(decision, option, "foo")

      attrs = %{title: "test", option_detail_values: []}
      result = Structure.update_option(option, attrs)

      assert {:ok, %Option{} = updated} = result

      assert [] == updated.option_detail_values
    end

    test "can update without changing OptionDetailValues" do
      %{option: option, decision: decision} = create_option_detail_value()
      create_option_detail_value(decision, option, "foo")

      option = Option |> preload(:option_detail_values) |> EtheloApi.Repo.get(option.id)

      attrs = %{title: "test"}
      result = Structure.update_option(option, attrs)

      assert {:ok, %Option{} = updated} = result
      assert_odvs_in_result(option.option_detail_values, updated.option_detail_values)
    end

    test "with invalid OptionDetailValue data returns errors" do
      %{option: option} = create_option_detail_value()

      first = %{value: "foo"}
      second = %{}
      attrs = %{title: "@", option_detail_values: [first, second]}

      result = Structure.update_option(option, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)

      expected_errors = [
        %{},
        %{option_detail_id: ["can't be blank"]},
        %{option_detail_id: ["can't be blank"]}
      ]

      assert expected_errors == errors.option_detail_values
    end

    test "can replace existing OptionDetailValues assocation with new list" do
      %{option: option, decision: decision, option_detail_value: first} =
        create_option_detail_value()

      %{option_detail_value: second} = create_option_detail_value(decision, option, "foo")
      %{option_detail_value: _third} = create_option_detail_value(decision, option, "foo")

      option_detail_values = [
        %{option_detail_id: first.option_detail_id, value: "10"},
        %{option_detail_id: second.option_detail_id, value: "20"}
      ]

      attrs = %{title: "foo", option_detail_values: option_detail_values}

      result = Structure.update_option(option, attrs)

      assert {:ok, %Option{} = updated} = result

      expected_odvs =
        Enum.map(
          option_detail_values,
          fn odv -> Map.put(odv, :option_id, option.id) end
        )

      assert_odvs_in_result(expected_odvs, updated.option_detail_values)
    end
  end

  describe "delete_option/2" do
    test "deletes" do
      %{option: existing, decision: decision, option_category: option_category} = create_option()
      to_delete = %Option{id: existing.id}

      result = Structure.delete_option(to_delete, decision.id)
      assert {:ok, %Option{}} = result
      assert nil == Repo.get(Option, existing.id)
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
