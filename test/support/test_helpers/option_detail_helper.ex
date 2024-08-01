defmodule EtheloApi.Structure.TestHelper.OptionDetailHelper do
  @moduledoc false

  import EtheloApi.Structure.TestHelper.GenericHelper
  import ExUnit.Assertions

  def empty_attrs() do
  %{
    format: nil, slug: nil, title: nil,
    input_hint: nil, display_hint: nil, public: nil
   }
  end

  def invalid_attrs(deps \\ %{}) do
    %{format: :decimal, slug: "  ", title: "@@@", public: 3, sort: false}
    |> add_decision_id(deps)
    |> add_option_detail_id(deps)
end

  def valid_attrs(%{} = deps) do
    %{
      title: "Title", slug: "slug", sort: 9,
      input_hint: "Input", display_hint: "Display",
      public: true, format: :string,
    }
    |> add_decision_id(deps)
    |> add_option_detail_id(deps)
  end

  def assert_equivalent(expected, result) do
    assert expected.format == result.format
    assert expected.title == result.title
    assert_equivalent_slug(expected.slug, result.slug)
    assert expected.display_hint == result.display_hint
    assert expected.input_hint == result.input_hint
    assert expected.public == result.public
    assert expected.sort == result.sort
  end

  def to_graphql_attrs(attrs) do
    case Map.get(attrs, :format) do
      nil -> attrs
      value -> attrs |> Map.put(:format, to_enum_value(value))
    end
  end

  def add_decision_id(attrs, %{decision: decision}), do: Map.put(attrs, :decision_id, decision.id)
  def add_decision_id(attrs, _deps), do: attrs

  def add_option_detail_id(attrs, %{option_detail: option_detail}), do: Map.put(attrs, :id, option_detail.id)
  def add_option_detail_id(attrs, _deps), do: attrs

end
