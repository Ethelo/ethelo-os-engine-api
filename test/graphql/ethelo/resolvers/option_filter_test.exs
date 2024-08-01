defmodule GraphQL.EtheloApi.Resolvers.OptionFilterTest do
  @moduledoc """
  Validations and basic access for "OptionFilter" resolver, used to load option_filter records
  through graphql.
  Note: Functionality is provided through the OptionFilterResolver.OptionFilter context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Structure.OptionFilterTest`

  """
  use EtheloApi.DataCase
  @moduletag option_filter: true, graphql: true

  import EtheloApi.Structure.Factory
  alias Kronky.ValidationMessage
  alias EtheloApi.Structure
  alias EtheloApi.Structure.OptionFilter
  alias GraphQL.EtheloApi.Resolvers.OptionFilter, as: OptionFilterResolver

  def valid_attrs(%{option_detail: option_detail, decision: decision} = deps) do
    %{
      slug: "baz",
      title: "bar",
      match_mode: "equals",
      match_value: "blue",
      option_detail_id: option_detail.id,
      option_category_id: nil,
      decision_id: decision.id,
    }
    |> add_option_filter_id(deps)
  end

   def valid_attrs(%{option_category: option_category, decision: decision} = deps) do
    %{
      slug: "baz",
      title: "bar",
      match_mode: "in_category",
      match_value: "blue",
      option_category_id: option_category.id,
      option_detail_id: nil,
      decision_id: decision.id,
    }
    |> add_option_filter_id(deps)
  end

  def invalid_attrs(%{option_detail: option_detail, decision: decision} = deps) do
    %{
      slug: "  ",
      title: "@@@",
      match_mode: nil,
      match_value: " ",
      decision_id: decision.id,
      option_category_id: nil,
      option_detail_id: option_detail.id,
    }
    |> add_option_filter_id(deps)
  end

  def invalid_attrs(%{option_category: option_category, decision: decision} = deps) do
    %{
      slug: "  ",
      title: "@@@",
      match_mode: nil,
      match_value: " ",
      decision_id: decision.id,
      option_category_id: option_category.id,
      option_detail_id: nil,
    }
    |> add_option_filter_id(deps)
  end

  def add_option_filter_id(attrs, %{option_filter: option_filter}), do: Map.put(attrs, :id, option_filter.id)
  def add_option_filter_id(attrs, _deps), do: attrs

  def assert_equivalent(expected, result) do
    assert expected.title == result.title
    assert_equivalent_slug(expected.slug, result.slug)
    assert expected.match_value == result.match_value
    assert expected.match_mode == result.match_mode
    assert expected.option_detail_id == result.option_detail_id
    if Map.has_key?(expected, :option_detail_id) do
      assert expected.option_detail_id == result.option_detail_id
    end
    if Map.has_key?(expected, :option_category_id) do
      assert expected.option_category_id == result.option_category_id
    end
  end

  describe "list/2" do

    test "returns records matching a Decision" do
      %{option_filter: first, decision: decision} = create_option_detail_filter()
      %{option_filter: second} = create_option_detail_filter(decision)

      parent = %{decision: decision}
      args = %{}
      result = OptionFilterResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionFilter{}, %OptionFilter{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "filters by OptionFilter.id" do
      %{option_filter: matching, decision: decision} = create_option_detail_filter()
      create_option_detail_filter(decision)

      parent = %{decision: decision}
      args = %{id: matching.id}
      result = OptionFilterResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionFilter{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by OptionFilter.slug" do
      %{option_filter: matching, decision: decision} = create_option_detail_filter()
      create_option_detail_filter(decision)

      parent = %{decision: decision}
      args = %{slug: matching.slug}
      result = OptionFilterResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionFilter{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by OptionFilter.option_detail_id" do
      %{option_filter: matching, decision: decision} = create_option_detail_filter()
      create_option_detail_filter(decision)

      parent = %{decision: decision}
      args = %{option_detail_id: matching.option_detail_id}
      result = OptionFilterResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionFilter{}] = result
      assert_result_ids_match([matching], result)
    end


    test "filters by OptionFilter.option_category_id" do
      %{option_filter: matching, decision: decision} = create_option_category_filter()
      create_option_category_filter(decision)

      parent = %{decision: decision}
      args = %{option_category_id: matching.option_category_id}
      result = OptionFilterResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionFilter{}] = result
      assert_result_ids_match([matching], result)
    end

    test "no OptionFilter matches" do
      decision = create_decision()

      parent = %{decision: decision}
      args = %{}
      result = OptionFilterResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [] = result
    end
  end

  describe "create/2" do
    test "creates with valid data" do
      deps = option_detail_filter_deps()
      %{decision: decision} = deps

      attrs = valid_attrs(deps)
      result = OptionFilterResolver.create(decision, attrs)

      assert {:ok, %OptionFilter{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "returns a changeset with invalid data" do
      deps = option_detail_filter_deps()
      %{option_detail: option_detail, decision: decision} = deps
      delete_option_detail(option_detail.id)

      attrs = invalid_attrs(deps)

      result = OptionFilterResolver.create(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = changeset |> errors_on() |> Map.keys()
      assert :title in errors
      assert :slug in errors
      assert :match_mode in errors
      assert :option_detail_id in errors
      refute :option_category_id in errors
      assert [_, _, _, _] = errors
    end
  end

  describe "update/2" do

    test "updates with valid data" do
      deps = create_option_detail_filter()
      %{decision: decision} = deps

      attrs = valid_attrs(deps)
      result = OptionFilterResolver.update(decision, attrs)

      assert {:ok, %OptionFilter{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "returns errors when OptionFilter does not exist" do
      deps = create_option_detail_filter()
      %{option_filter: option_filter, decision: decision} = deps
      delete_option_filter(option_filter.id)

      attrs = valid_attrs(deps)
      result = OptionFilterResolver.update(decision, attrs)

      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "returns errors when Decision does not match" do
      deps = create_option_detail_filter()
      decision = create_decision()

      attrs = valid_attrs(deps)
      result = OptionFilterResolver.update(decision, attrs)

      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "returns a changeset with invalid data" do
      deps = create_option_category_filter()
      %{decision: decision} = deps

      attrs = invalid_attrs(deps)
      result = OptionFilterResolver.update(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = changeset |> errors_on() |> Map.keys()
      assert :title in errors
      assert :slug in errors
      assert :match_mode in errors
      refute :option_category_id in errors
      refute :option_detail_id in errors
      assert [_, _, _, _] = errors
    end
  end

  describe "delete/2" do
    test "deletes" do
      deps = create_option_detail_filter()
      %{option_filter: option_filter, decision: decision} = deps

      attrs = %{decision_id: decision.id, id: option_filter.id}
      result = OptionFilterResolver.delete(decision, attrs)

      assert {:ok, %OptionFilter{}} = result
      assert nil == Structure.get_option_filter(option_filter.id, decision)
    end

    test "delete/2 does not return errors when OptionFilter does not exist" do
      %{option_filter: option_filter, decision: decision} = create_option_detail_filter()
      delete_option_filter(option_filter.id)

      attrs = %{decision_id: decision.id, id: option_filter.id}
      result = OptionFilterResolver.delete(decision, attrs)

      assert {:ok, nil} = result
    end
  end
end
