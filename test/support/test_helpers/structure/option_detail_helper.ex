defmodule EtheloApi.Structure.TestHelper.OptionDetailHelper do
  @moduledoc """
  OptionDetail specific test tools
  """

  import EtheloApi.TestHelper.GenericHelper
  import ExUnit.Assertions

  def fields() do
    %{
      display_hint: :string,
      format: :enum,
      id: :string,
      input_hint: :string,
      inserted_at: :date,
      public: :boolean,
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
      :display_hint,
      :format,
      :input_hint,
      :public,
      :slug,
      :sort,
      :title
    ]
  end

  def empty_attrs() do
    %{
      display_hint: nil,
      format: nil,
      input_hint: nil,
      public: nil,
      slug: nil,
      title: nil
    }
  end

  def invalid_attrs(deps \\ %{}) do
    %{
      format: :decimal,
      public: 3,
      slug: "@@@",
      sort: false,
      title: " "
    }
    |> add_decision_id(deps)
    |> add_record_id(deps)
  end

  def valid_attrs(%{} = deps \\ %{}) do
    %{
      display_hint: "Display",
      format: :string,
      input_hint: "Input",
      public: true,
      slug: "slug",
      sort: 9,
      title: "Title"
    }
    |> add_decision_id(deps)
    |> add_record_id(deps)
  end

  def assert_equivalent(expected, result) do
    assert expected.display_hint == result.display_hint
    assert expected.format == result.format
    assert expected.input_hint == result.input_hint
    assert expected.public == result.public
    assert_equivalent_slug(expected.slug, result.slug)
    assert expected.title == result.title
  end

  def add_record_id(attrs, %{option_detail: option_detail}),
    do: Map.put(attrs, :id, option_detail.id)

  def add_record_id(attrs, _deps), do: attrs
end
