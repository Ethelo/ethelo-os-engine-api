defmodule EtheloApi.Structure.TestHelper.VariableHelper do
  @moduledoc """
  Variable specific test tools
  """

  import EtheloApi.TestHelper.GenericHelper
  import ExUnit.Assertions

  def fields() do
    %{
      id: :string,
      inserted_at: :date,
      method: :enum,
      option_detail_id: :string,
      option_filter_id: :string,
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
      :method,
      :option_detail_id,
      :option_filter_id,
      :slug,
      :title
    ]
  end

  def empty_attrs() do
    %{
      slug: nil,
      title: nil,
      method: nil,
      option_filter_id: nil,
      option_detail_id: nil
    }
  end

  def invalid_attrs(deps \\ %{}) do
    %{
      method: "not valid method",
      option_detail_id: nil,
      option_filter_id: nil,
      slug: "@@@",
      title: ""
    }
    |> add_record_id(deps)
    |> add_option_detail_id(deps)
    |> add_option_filter_id(deps)
    |> add_decision_id(deps)
  end

  def valid_attrs(%{option_detail: _} = deps) do
    %{
      method: :mean_selected,
      option_filter_id: nil,
      title: "0Detail"
    }
    |> add_slug()
    |> add_record_id(deps)
    |> add_option_detail_id(deps)
    |> add_decision_id(deps)
  end

  def valid_attrs(%{option_filter: _} = deps) do
    %{
      method: :count_all,
      option_detail_id: nil,
      title: "Filter"
    }
    |> add_record_id(deps)
    |> add_slug
    |> add_option_filter_id(deps)
    |> add_decision_id(deps)
  end

  def assert_equivalent(expected, result) do
    assert expected.method == result.method
    assert expected.option_detail_id == result.option_detail_id
    assert expected.option_filter_id == result.option_filter_id
    assert expected.slug == result.slug
    assert expected.title == result.title
  end

  def add_record_id(attrs, %{variable: variable}), do: Map.put(attrs, :id, variable.id)
  def add_record_id(attrs, _deps), do: attrs

  def add_slug(%{title: title} = attrs) do
    Map.put(attrs, :slug, EtheloApi.Structure.Variable.slugger(title))
  end
end
