defmodule EtheloApi.Structure.FilterOptionsTest do
  @moduledoc """
  Validations and basic access for FilterOptions
  """
  use EtheloApi.DataCase
  @moduletag option_filter: true
  import EtheloApi.Structure.Factory

  alias EtheloApi.Structure.FilterOptions

  def create_detail_option_set(format, match_value) do
    %{decision: decision, option_detail: option_detail} = create_option_detail(format)
    %{option: enabled} = create_option(decision, %{enabled: true})
    %{option: disabled} = create_option(decision, %{enabled: false})
    %{option: no_details} = create_option(decision, %{enabled: true})
    create_option_detail_value(enabled, option_detail, match_value)
    create_option_detail_value(disabled, option_detail, match_value)

    %{option_filter: option_filter} =
      create_option_detail_filter_matching(decision, option_detail, match_value, "equals")

    %{
      decision: decision,
      option_detail: option_detail,
      option_filter: option_filter,
      enabled: enabled,
      disabled: disabled,
      no_details: no_details
    }
  end

  def create_category_option_set() do
    %{decision: decision, option_category: option_category1} = create_option_category()

    %{option: enabled1} =
      create_option(decision, %{enabled: true, option_category: option_category1})

    %{option: disabled1} =
      create_option(decision, %{enabled: false, option_category: option_category1})

    %{option_category: option_category2} = create_option_category(decision)

    %{option: enabled2} =
      create_option(decision, %{enabled: true, option_category: option_category2})

    %{option: disabled2} =
      create_option(decision, %{enabled: false, option_category: option_category2})

    %{
      decision: decision,
      option_category1: option_category1,
      option_category2: option_category2,
      enabled1: enabled1,
      disabled1: disabled1,
      enabled2: enabled2,
      disabled2: disabled2
    }
  end

  describe "matches multiple OptionFilters" do
    test "returns expected Option ids" do
      deps = create_detail_option_set(:string, "foo")
      %{decision: decision, option_filter: detail_filter} = deps
      %{option_filter: all_options_filter} = create_all_options_filter(decision)

      result =
        FilterOptions.option_ids_matching_filters(
          [all_options_filter, detail_filter],
          decision.id
        )

      assert %{ids: _, slugs: slugs} = result
      all_options_result = Map.get(slugs, all_options_filter.slug)
      assert deps.enabled.id in all_options_result
      assert deps.disabled.id in all_options_result
      assert deps.no_details.id in all_options_result

      detail_result = Map.get(slugs, detail_filter.slug)
      assert deps.enabled.id in detail_result
      assert deps.disabled.id in detail_result
      refute deps.no_details.id in detail_result
    end

    test "returns empty map with no OptionFilters" do
      decision = create_decision()
      result = FilterOptions.option_ids_matching_filters([], decision.id)

      assert %{ids: %{}, slugs: %{}} = result
    end
  end

  describe "all options filter" do
    test "matches enabled and disabled Options by default" do
      deps = create_detail_option_set(:string, "foo")
      %{decision: decision} = deps
      %{option: option} = create_option(decision)
      %{option_filter: option_filter} = create_all_options_filter(decision)

      result = FilterOptions.option_ids_matching_filter(option_filter)

      assert deps.enabled.id in result
      assert deps.disabled.id in result
      assert deps.no_details.id in result
      assert option.id in result
    end

    test "matches enabled only" do
      deps = create_detail_option_set(:string, "foo")
      %{decision: decision} = deps
      %{option: option} = create_option(decision)
      %{option_filter: option_filter} = create_all_options_filter(decision)
      result = FilterOptions.option_ids_matching_filter(option_filter, true)

      assert deps.enabled.id in result
      refute deps.disabled.id in result
      assert deps.no_details.id in result
      assert option.id in result
    end
  end

  describe "with OptionCategory OptionFilter" do
    test "matches enabled and disabled by default" do
      deps = create_category_option_set()
      %{decision: decision, option_category1: option_category} = deps

      %{option_filter: filter} =
        create_option_category_filter_matching(decision, option_category, "in_category")

      result = FilterOptions.option_ids_matching_filter(filter)

      assert deps.enabled1.id in result
      assert deps.disabled1.id in result
      refute deps.enabled2.id in result
      refute deps.disabled2.id in result
    end

    test "matches enabled only" do
      deps = create_category_option_set()
      %{decision: decision, option_category1: option_category} = deps

      %{option_filter: filter} =
        create_option_category_filter_matching(decision, option_category, "in_category")

      result = FilterOptions.option_ids_matching_filter(filter, true)

      assert deps.enabled1.id in result
      refute deps.disabled1.id in result
      refute deps.enabled2.id in result
      refute deps.disabled2.id in result
    end

    test "matches not_in_category" do
      deps = create_category_option_set()
      %{decision: decision, option_category1: option_category} = deps

      %{option_filter: filter} =
        create_option_category_filter_matching(decision, option_category, "not_in_category")

      result = FilterOptions.option_ids_matching_filter(filter)

      assert deps.enabled2.id in result
      assert deps.disabled2.id in result
      refute deps.enabled1.id in result
      refute deps.disabled1.id in result
    end
  end

  describe "with OptionDetail OptionFilter" do
    test "matches enabled and disabled by default" do
      match_value = "foo"
      deps = create_detail_option_set(:string, match_value)

      result = FilterOptions.option_ids_matching_filter(deps.option_filter)

      assert deps.enabled.id in result
      assert deps.disabled.id in result
      refute deps.no_details.id in result
    end

    test "matches enabled only" do
      match_value = "foo"
      deps = create_detail_option_set(:string, match_value)

      result = FilterOptions.option_ids_matching_filter(deps.option_filter, true)

      assert deps.enabled.id in result
      refute deps.disabled.id in result
      refute deps.no_details.id in result
    end
  end

  describe "matching with equals" do
    test "float value matches" do
      match_value = "4.3"
      deps = create_detail_option_set(:float, match_value)

      result = FilterOptions.option_ids_matching_filter(deps.option_filter)

      assert deps.enabled.id in result
      assert deps.disabled.id in result
      refute deps.no_details.id in result
    end

    test "integer value matches" do
      match_value = "4"
      deps = create_detail_option_set(:integer, match_value)

      result = FilterOptions.option_ids_matching_filter(deps.option_filter)

      assert deps.enabled.id in result
      assert deps.disabled.id in result
      refute deps.no_details.id in result
    end

    test "boolean true matches" do
      match_value = "true"
      deps = create_detail_option_set(:boolean, match_value)

      result = FilterOptions.option_ids_matching_filter(deps.option_filter)

      assert deps.enabled.id in result
      assert deps.disabled.id in result
      refute deps.no_details.id in result
    end

    test "boolean false matches" do
      match_value = "false"
      deps = create_detail_option_set(:boolean, match_value)

      result = FilterOptions.option_ids_matching_filter(deps.option_filter)

      assert deps.enabled.id in result
      assert deps.disabled.id in result
      refute deps.no_details.id in result
    end
  end
end
