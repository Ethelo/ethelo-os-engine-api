defmodule EtheloApi.Structure.TestHelper.OptionHelper do
  @moduledoc false

  import EtheloApi.Structure.TestHelper.GenericHelper
  import ExUnit.Assertions

  def empty_attrs() do
    %{
      slug: nil, title: nil, info: nil, enabled: nil,
      option_category_id: nil, sort: nil
    }
  end

  def invalid_attrs(deps \\ %{}) do
     %{slug: "  ", title: "@@@", enabled: 3, sort: false, option_category_id: 3020}
     |> add_option_category_id(deps)
     |> add_option_id(deps)
     |> add_decision_id(deps)
  end

  def valid_attrs(%{} = deps) do
    %{
      title: "Title",
      slug: "slug",
      info: "Information provided.",
      enabled: true,
      sort: 1
    }
    |> add_option_category_id(deps)
    |> add_option_id(deps)
    |> add_decision_id(deps)
  end

  def assert_equivalent(expected, result) do
    assert expected.title == result.title
    assert_equivalent_slug(expected.slug, result.slug)
    assert expected.info == result.info
    assert expected.enabled == result.enabled
    assert expected.sort == result.sort

    if Map.get(expected, :option_category_id) do
      assert expected.option_category_id == result.option_category_id
    end
  end

  def to_graphql_attrs(attrs) do
    attrs
  end

  def add_decision_id(attrs, %{decision: decision}), do: Map.put(attrs, :decision_id, decision.id)
  def add_decision_id(attrs, _deps), do: attrs

  def add_option_id(attrs, %{option: option}), do: Map.put(attrs, :id, option.id)
  def add_option_id(attrs, _deps), do: attrs

  def add_option_category_id(attrs, %{option_category: option_category}), do: Map.put(attrs, :option_category_id, option_category.id)
  def add_option_category_id(attrs, _deps), do: attrs

end
