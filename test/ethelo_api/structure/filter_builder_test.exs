defmodule EtheloApi.Structure.FilterBuilderTest do
  @moduledoc """
  Validations and basic access for FilterBuilder
  """
  use EtheloApi.DataCase
  @moduletag option_filter: true

  import EtheloApi.Structure.Factory

  alias EtheloApi.Structure.FilterBuilder
  alias EtheloApi.Structure.FilterData
  alias EtheloApi.Structure
  alias EtheloApi.Structure.OptionFilter
  alias EtheloApi.Structure.OptionDetail
  alias EtheloApi.Structure.OptionCategory

  # helper method to make it easier to compare lists of OptionFilters
  def convert_filters_to_tuples(list), do: Enum.map(list, &convert_filter_to_tuple/1)

  def convert_filter_to_tuple(option_filter) do
    option_detail_id = id_if_present(option_filter, :option_detail)
    option_category_id = id_if_present(option_filter, :option_category)
    decision_id = id_if_present(option_filter, :decision)

    {option_filter.match_mode, option_filter.match_value, option_filter.title, option_detail_id,
     option_category_id, decision_id}
  end

  def assert_filters_in_result(%OptionFilter{} = option_filter, result) do
    assert_filters_in_result([option_filter], result)
  end

  def assert_filters_in_result(option_filters, result) when is_list(option_filters) do
    option_filters = convert_filters_to_tuples(option_filters)
    result = convert_filters_to_tuples(result)

    for option_filter <- option_filters do
      assert option_filter in result
    end
  end

  def assert_expected_number_of_filters(option_filters, result) do
    assert Enum.count(option_filters) == Enum.count(result),
      message: "expected #{Enum.count(option_filters)} OptionFilters, got #{Enum.count(result)}"
  end

  def filter_struct(%OptionDetail{} = option_detail, value, title) do
    filter_struct(option_detail, value, title, "equals")
  end

  def filter_struct(%OptionDetail{} = option_detail, value, title, match_mode) do
    %OptionFilter{
      match_mode: match_mode,
      option_detail_id: option_detail.id,
      match_value: value,
      decision_id: option_detail.decision_id,
      title: title
    }
  end

  def filter_struct(%OptionCategory{} = option_category, value, title, match_mode) do
    %OptionFilter{
      match_mode: match_mode,
      option_category_id: option_category.id,
      match_value: value,
      decision_id: option_category.decision_id,
      title: title
    }
  end

  describe "possible_filters/1" do
    test "when OptionDetails or OptionCategories returns no OptionFilters" do
      decision = create_decision()

      data = FilterData.initialize_all(decision)

      result = FilterBuilder.possible_filters(data)
      expected = []

      assert_filters_in_result(expected, result)
      assert_expected_number_of_filters(expected, result)
    end

    test "saved OptionFilter returns id value" do
      %{decision: decision, option_filter: option_filter, option_category: option_category} =
        create_option_category_filter()

      id = option_filter.id

      data = FilterData.initialize_option_category(option_category, decision)

      result = FilterBuilder.possible_filters(data)

      assert [%OptionFilter{id: ^id}] = result
    end

    test "OptionCategory lists one OptionFilter" do
      %{decision: decision, option_category: option_category} = create_option_category()

      data = FilterData.initialize_option_category(option_category, decision)

      result = FilterBuilder.possible_filters(data)

      expected = [
        filter_struct(option_category, nil, "#{option_category.title}", "in_category")
      ]

      assert_filters_in_result(expected, result)
      assert_expected_number_of_filters(expected, result)
    end

    test "float OptionDetail returns no OptionFilters" do
      decision = create_decision()

      %{option_detail: option_detail} =
        create_option_detail(decision, %{title: "Float Detail", format: :float})

      create_option_detail_value(decision, option_detail, 1)
      create_option_detail_value(decision, option_detail, 29.9)

      data = FilterData.initialize_option_detail(option_detail, decision)

      result = FilterBuilder.possible_filters(data)

      expected = []
      assert_filters_in_result(expected, result)
      assert_expected_number_of_filters(expected, result)
    end

    test "integer OptionDetail returns no OptionFilters" do
      decision = create_decision()

      %{option_detail: option_detail} =
        create_option_detail(decision, %{title: "Integer Detail", format: :integer})

      create_option_detail_value(decision, option_detail, 1)
      create_option_detail_value(decision, option_detail, 29.9)

      data = FilterData.initialize_option_detail(option_detail, decision)

      result = FilterBuilder.possible_filters(data)

      expected = []
      assert_filters_in_result(expected, result)
      assert_expected_number_of_filters(expected, result)
    end

    test "lists both OptionFilters with only a boolean true value" do
      decision = create_decision()

      %{option_detail: option_detail} =
        create_option_detail(decision, %{title: "Boolean Detail", format: :boolean})

      create_option_detail_value(decision, option_detail, true)

      data = FilterData.initialize_option_detail(option_detail, decision)

      result = FilterBuilder.possible_filters(data)

      expected = [
        filter_struct(option_detail, "true", "Boolean Detail Yes", "equals"),
        filter_struct(option_detail, "false", "Boolean Detail No", "equals")
      ]

      assert_filters_in_result(expected, result)
      assert_expected_number_of_filters(expected, result)
    end

    test "lists both OptionFilters with only a boolean false value" do
      decision = create_decision()

      %{option_detail: option_detail} =
        create_option_detail(decision, %{title: "Boolean Detail", format: :boolean})

      create_option_detail_value(decision, option_detail, false)

      data = FilterData.initialize_option_detail(option_detail, decision)

      result = FilterBuilder.possible_filters(data)

      expected = [
        filter_struct(option_detail, "true", "Boolean Detail Yes", "equals"),
        filter_struct(option_detail, "false", "Boolean Detail No", "equals")
      ]

      assert_filters_in_result(expected, result)
      assert_expected_number_of_filters(expected, result)
    end

    test "lists all OptionFilter with both detail and category" do
      decision = create_decision()

      %{option_detail: option_detail} =
        create_option_detail(decision, %{title: "Boolean Detail", format: :boolean})

      create_option_detail_value(decision, option_detail, false)

      data = FilterData.initialize_all(decision)

      result = FilterBuilder.possible_filters(data)

      assert [_, _, _] = result
    end
  end

  describe "ensure_all_valid_filters/1" do
    test "creates all" do
      decision = create_decision()

      %{option_detail: option_detail} =
        create_option_detail(decision, %{title: "Boolean Detail", format: :boolean})

      create_option_detail_value(decision, option_detail, false)
      create_option_category(decision)

      result = FilterBuilder.ensure_all_valid_filters(decision)
      assert {:ok, true} = result
      option_filters = Structure.list_option_filters(decision)
      # two detail, 2 category, 1 all options
      assert [_, _, _, _, _] = option_filters
    end

    test "updates on changed category all" do
      decision = create_decision()

      %{option_category: option_category} = create_option_category(decision)

      result = FilterBuilder.ensure_all_valid_filters(decision)
      assert {:ok, true} = result

      option_filters =
        Structure.list_option_filters(decision, %{option_category_id: option_category.id})

      assert [first] = option_filters

      Structure.update_option_category(option_category, %{
        slug: "updated_filter",
        title: "updated filter"
      })

      # ensure all automatically called on update

      option_filters =
        Structure.list_option_filters(decision, %{option_category_id: option_category.id})

      assert [updated] = option_filters

      assert first.id == updated.id
      assert first.slug != updated.slug
    end
  end
end
