defmodule EtheloApi.Structure.TestHelper.ConstraintHelper do
  @moduledoc """
  Constraint specific test tools
  """

  import EtheloApi.TestHelper.GenericHelper
  import ExUnit.Assertions

  def fields() do
    %{
      calculation_id: :string,
      id: :string,
      inserted_at: :date,
      lhs: :float,
      operator: :enum,
      option_filter_id: :string,
      relaxable: :boolean,
      rhs: :float,
      slug: :string,
      title: :string,
      updated_at: :date,
      variable_id: :string
    }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  def input_field_names() do
    [
      :calculation_id,
      :inserted_at,
      :lhs,
      :operator,
      :option_filter_id,
      :relaxable,
      :rhs,
      :slug,
      :title,
      :updated_at,
      :variable_id
    ]
  end

  def empty_attrs() do
    %{
      calculation_id: nil,
      enabled: nil,
      lhs: nil,
      operator: nil,
      option_filter_id: nil,
      relaxable: nil,
      rhs: nil,
      slug: nil,
      title: nil,
      variable_id: nil
    }
  end

  def invalid_attrs(deps \\ %{}) do
    %{
      calculation_id: 400,
      enabled: 37,
      lhs: "seven",
      operator: "not valid",
      option_filter_id: 400,
      relaxable: "3",
      rhs: "three",
      slug: "@@@",
      title: "",
      variable_id: 400
    }
    |> add_record_id(deps)
    |> add_variable_id(deps)
    |> add_calculation_id(deps)
    |> add_option_filter_id(deps)
    |> add_decision_id(deps)
  end

  def valid_attrs(deps \\ %{}) do
    %{
      calculation_id: nil,
      enabled: true,
      lhs: nil,
      operator: :greater_than_or_equal_to,
      option_filter_id: nil,
      relaxable: true,
      rhs: 300,
      slug: "slug",
      title: "Title",
      variable_id: nil
    }
    |> add_record_id(deps)
    |> add_variable_id(deps)
    |> add_calculation_id(deps)
    |> add_option_filter_id(deps)
    |> add_decision_id(deps)
  end

  def valid_between_attrs(deps) do
    deps
    |> valid_attrs()
    |> Map.put(:operator, :between)
    |> Map.put(:lhs, 1)
  end

  def assert_equivalent(expected, result) do
    assert expected.calculation_id == result.calculation_id
    assert expected.enabled == result.enabled
    assert expected.lhs == result.lhs
    assert expected.operator == result.operator
    assert expected.option_filter_id == result.option_filter_id
    assert expected.relaxable == result.relaxable
    assert expected.rhs == result.rhs
    assert_equivalent_slug(expected.slug, result.slug)
    assert expected.title == result.title
    assert expected.variable_id == result.variable_id
  end

  def add_record_id(attrs, %{constraint: constraint}), do: Map.put(attrs, :id, constraint.id)
  def add_record_id(attrs, _deps), do: attrs
end
