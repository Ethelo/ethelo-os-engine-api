defmodule EtheloApi.Structure.TestHelper.VariableHelper do
  @moduledoc false

  import ExUnit.Assertions

  def empty_attrs() do
    %{slug: nil, title: nil, method: nil, option_filter_id: nil, option_detail_id: nil}
  end

  def invalid_attrs(deps \\ %{}) do
     %{slug: " ", title: "@@@", method: "not valid method", option_filter_id: nil, option_detail_id: nil}
     |> add_variable_id(deps)
     |> add_option_detail_id(deps)
     |> add_option_filter_id(deps)
     |> add_decision_id(deps)
  end

  def valid_attrs(%{option_detail: _} = deps) do
    %{title: "0Detail", method: :mean_selected, option_filter_id: nil}
    |> add_slug()
    |> add_variable_id(deps)
    |> add_option_detail_id(deps)
    |> add_decision_id(deps)
  end

  def valid_attrs(%{option_filter: _} = deps) do
    %{title: "Filter", method: :count_all, option_detail_id: nil}
    |> add_variable_id(deps)
    |> add_slug
    |> add_option_filter_id(deps)
    |> add_decision_id(deps)
  end

  def assert_equivalent(expected, result) do
    assert expected.title == result.title
    assert expected.slug == result.slug
    assert expected.method == result.method
    assert expected.option_filter_id == result.option_filter_id
    assert expected.option_detail_id == result.option_detail_id
  end

  def add_variable_id(attrs, %{variable: variable}), do: Map.put(attrs, :id, variable.id)
  def add_variable_id(attrs, _deps), do: attrs

  def add_option_filter_id(attrs, %{option_filter: option_filter}), do: Map.put(attrs, :option_filter_id, option_filter.id)
  def add_option_filter_id(attrs, _deps), do: attrs

  def add_option_detail_id(attrs, %{option_detail: option_detail}), do: Map.put(attrs, :option_detail_id, option_detail.id)
  def add_option_detail_id(attrs, _deps), do: attrs

  def add_decision_id(attrs, %{decision: decision}), do: Map.put(attrs, :decision_id, decision.id)
  def add_decision_id(attrs, _deps), do: attrs

  def add_slug(%{title: title} = attrs) do
    Map.put(attrs, :slug, EtheloApi.Structure.Variable.slugger(title))
  end

end
