defmodule EtheloApi.Structure.TestHelper.OptionHelper do
  @moduledoc """
  Option specific test tools
  """
  import EtheloApi.TestHelper.GenericHelper
  import ExUnit.Assertions

  def fields() do
    %{
      #  determinative: :boolean,
      enabled: :boolean,
      id: :string,
      info: :string,
      inserted_at: :date,
      option_category_id: :id,
      results_title: :string,
      slug: :string,
      sort: :integer,
      title: :string,
      updated_at: :date
    }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  def input_field_names() do
    [
      #  :determinative,
      :enabled,
      :info,
      :option_category_id,
      :results_title,
      :slug,
      :sort,
      :title
    ]
  end

  def empty_attrs() do
    %{
      enabled: nil,
      info: nil,
      option_category_id: nil,
      slug: nil,
      sort: nil,
      title: nil
    }
  end

  def invalid_attrs(deps \\ %{}) do
    %{
      sort: false,
      slug: "@@@",
      enabled: 3,
      title: ""
    }
    |> add_option_category_id(deps)
    |> add_record_id(deps)
    |> add_decision_id(deps)
  end

  def valid_attrs(%{} = deps) do
    %{
      enabled: true,
      info: "Information provided.",
      slug: "slug",
      sort: 1,
      title: "Title"
    }
    |> add_record_id(deps)
    |> add_option_category_id(deps)
    |> add_decision_id(deps)
  end

  def assert_equivalent(expected, result) do
    assert expected.enabled == result.enabled
    assert expected.info == result.info
    assert expected.option_category_id == result.option_category_id
    assert expected.sort == result.sort
    assert_equivalent_slug(expected.slug, result.slug)
    assert expected.title == result.title
  end

  def add_record_id(attrs, %{option: option}), do: Map.put(attrs, :id, option.id)
  def add_record_id(attrs, _deps), do: attrs
end
