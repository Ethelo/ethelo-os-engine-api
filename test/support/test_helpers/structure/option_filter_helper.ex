defmodule EtheloApi.Structure.TestHelper.OptionFilterHelper do
  @moduledoc """
  OptionFilter specific test tools
  """

  import EtheloApi.TestHelper.GenericHelper
  import ExUnit.Assertions
  alias EtheloApi.Structure.OptionFilter
  alias EtheloApi.Structure.OptionCategory
  alias EtheloApi.Structure.OptionDetail

  def all_options(), do: OptionFilter.all_options_values()

  def fields() do
    %{
      id: :string,
      inserted_at: :date,
      match_mode: :string,
      match_value: :string,
      option_category_id: :string,
      option_detail_id: :string,
      slug: :string,
      title: :string,
      updated_at: :date
    }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  def input_field_names() do
    [
      :match_mode,
      :match_value,
      :option_category_id,
      :option_detail_id,
      :slug,
      :title
    ]
  end

  # Graphql Enum -> Ecto String requires special procesing
  # to properly generate graphql
  def upcase_enum(%{match_mode: match_mode} = attrs) do
    upcased = match_mode |> to_string |> String.upcase() |> String.to_atom()
    Map.put(attrs, :match_mode, upcased)
  end

  def empty_attrs() do
    %{
      match_mode: nil,
      match_value: nil,
      option_category_id: nil,
      option_detail_id: nil,
      slug: nil,
      title: nil
    }
  end

  def invalid_attrs(deps \\ %{}) do
    %{
      match_mode: "invalid mode",
      match_value: "",
      option_category_id: false,
      option_detail_id: "foo",
      slug: "@@@",
      title: " "
    }
    |> add_record_id(deps)
    |> add_decision_id(deps)
  end

  def valid_attrs(%{option_detail: %OptionDetail{}} = deps) do
    %{
      slug: "slug",
      title: "Title",
      option_detail_id: nil,
      option_category_id: nil
    }
    |> Map.put(:match_mode, "equals")
    |> Map.put(:match_value, "foo")
    |> add_record_id(deps)
    |> add_decision_id(deps)
    |> add_option_detail_id(deps)
  end

  def valid_attrs(%{option_category: %OptionCategory{}} = deps) do
    %{
      slug: "slug",
      title: "Title",
      option_detail_id: nil,
      option_category_id: nil
    }
    |> Map.put(:match_mode, "in_category")
    |> Map.put(:match_value, "")
    |> add_record_id(deps)
    |> add_decision_id(deps)
    |> add_option_category_id(deps)
  end

  def assert_equivalent(expected, result) do
    assert expected.match_value == result.match_value
    assert expected.title == result.title
    assert to_string(expected.match_mode) == to_string(result.match_mode)
    assert_equivalent_slug(expected.slug, result.slug)

    if Map.has_key?(expected, :option_detail_id) do
      assert expected.option_detail_id == result.option_detail_id
    end

    if Map.has_key?(expected, :option_category_id) do
      assert expected.option_category_id == result.option_category_id
    end
  end

  def add_record_id(attrs, %{option_filter: option_filter}),
    do: Map.put(attrs, :id, option_filter.id)

  def add_record_id(attrs, _deps), do: attrs
end
