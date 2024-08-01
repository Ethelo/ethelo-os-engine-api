defmodule EtheloApi.Constraints.FilterBuilderTest do
  @moduledoc """
  Validations and basic access for FilterBuilder
  """
  use EtheloApi.DataCase
  import EtheloApi.Structure.Factory

  alias EtheloApi.Constraints.FilterBuilder
  alias EtheloApi.Constraints.FilterData
  alias EtheloApi.Structure
  alias EtheloApi.Structure.OptionFilter
  alias EtheloApi.Structure.OptionDetail
  alias EtheloApi.Structure.OptionCategory

  # helper method to make it easier to compare lists of filters
  def convert_filters_to_tuples(list), do: Enum.map(list, &convert_filter_to_tuple/1)

  def convert_filter_to_tuple(filter) do
    option_detail_id = id_if_present(filter, :option_detail)
    option_category_id = id_if_present(filter, :option_category)
    decision_id = id_if_present(filter, :decision)

    {filter.match_mode, filter.match_value, filter.title, option_detail_id, option_category_id,
     decision_id}
  end

  def assert_filters_in_result(%OptionFilter{} = filter, result) do
    assert_filters_in_result([filter], result)
  end

  def assert_filters_in_result(filters, result) when is_list(filters) do
    filters = convert_filters_to_tuples(filters)
    result = convert_filters_to_tuples(result)

    for filter <- filters do
      assert filter in result
    end
  end

  def assert_expected_number_of_filters(filters, result) do
    assert Enum.count(filters) == Enum.count(result),
      message: "expected #{Enum.count(filters)} filters, got #{Enum.count(result)}"
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
    test "with no details or categories lists no filters" do
      decision = create_decision()

      data = FilterData.initialize_all(decision)

      result = FilterBuilder.possible_filters(data)
      expected = []

      assert_filters_in_result(expected, result)
      assert_expected_number_of_filters(expected, result)
    end

    test "with saved filter returns id value" do
      %{decision: decision, option_filter: option_filter, option_category: option_category} =
        create_option_category_filter()

      id = option_filter.id

      data = FilterData.initialize_option_category(option_category, decision)

      result = FilterBuilder.possible_filters(data)

      assert [%OptionFilter{id: ^id}] = result
    end

    test "with OptionCategory lists one filter" do
      %{decision: decision, option_category: option_category} = create_option_category()

      data = FilterData.initialize_option_category(option_category, decision)

      result = FilterBuilder.possible_filters(data)

      expected = [
        filter_struct(option_category, nil, "#{option_category.title}", "in_category")
      ]

      assert_filters_in_result(expected, result)
      assert_expected_number_of_filters(expected, result)
    end

    test "with float details lists no filters" do
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

    test "with integer details lists no filters" do
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

    test "lists both filters with only a boolean true value" do
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

    test "lists both filters with only a boolean false value" do
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

    test "lists all filters with both detail and category" do
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
      filters = Structure.list_option_filters(decision)
      assert [_, _, _, _, _] = filters  # two detail, 2 category, 1 all options
    end

    test "updates on changed category all" do
      decision = create_decision()

      %{option_category: option_category} = create_option_category(decision)

      result = FilterBuilder.ensure_all_valid_filters(decision)
      assert {:ok, true} = result
      filters = Structure.list_option_filters(decision, %{option_category_id: option_category.id})
      assert [first] = filters

      Structure.update_option_category(option_category, %{slug: "updated_filter", title: "updated filter"}) 
      # ensure all automatically called on update

      filters = Structure.list_option_filters(decision, %{option_category_id: option_category.id})
      assert [updated] = filters

      assert first.id == updated.id
      assert first.slug != updated.slug

    end
  end
end
