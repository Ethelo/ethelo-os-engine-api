defmodule EtheloApi.Structure.TestHelper.ConstraintHelper do
  @moduledoc false

  import EtheloApi.Structure.TestHelper.GenericHelper
  import ExUnit.Assertions

  def empty_attrs() do
    %{
      slug: nil, title: nil, relaxable: nil,
      operator: nil, rhs: nil, lhs: nil, enabled: nil,
      option_filter_id: nil, calculation_id: nil, variable_id: nil
    }
  end

  def invalid_attrs(deps \\ %{}) do
     %{
       slug: " ", title: "@@@", relaxable: "3",
       operator: "not valid", rhs: "three", lhs: "seven",  enabled: 37,
       option_filter_id: 400, calculation_id: 400, variable_id: 400,
     }
     |> add_constraint_id(deps)
     |> add_variable_id(deps)
     |> add_calculation_id(deps)
     |> add_option_filter_id(deps)
     |> add_decision_id(deps)
  end

  def valid_attrs(deps) do
    %{
      slug: "slug", title: "Title", relaxable: true,
      operator: :greater_than_or_equal_to, rhs: 300, lhs: nil, enabled: true,
      option_filter_id: nil, calculation_id: nil, variable_id: nil,
    }
    |> add_constraint_id(deps)
    |> add_variable_id(deps)
    |> add_calculation_id(deps)
    |> add_option_filter_id(deps)
    |> add_decision_id(deps)
  end

  def valid_between_attrs(deps) do
    deps |> valid_attrs()
    |> Map.put(:operator, :between)
    |> Map.put(:lhs, 1)
  end

  def to_graphql_attrs(attrs) do
    attrs = if Map.get(attrs, :operator) == :between do
      attrs |> Map.put(:between_high, Map.get(attrs, :rhs))
    else
      attrs |> Map.put(:value, Map.get(attrs, :rhs))
    end

    attrs
    |> Map.put(:between_low, Map.get(attrs, :lhs))
    |> Map.drop([:rhs, :lhs])
  end

  def assert_equivalent(expected, result) do
    assert expected.title == result.title
    assert_equivalent_slug(expected.slug, result.slug)
    assert expected.rhs == result.rhs
    assert expected.lhs == result.lhs
    assert expected.relaxable == result.relaxable
    assert expected.operator == result.operator
    assert expected.option_filter_id == result.option_filter_id
    assert expected.calculation_id == result.calculation_id
    assert expected.variable_id == result.variable_id
    assert expected.enabled == result.enabled
  end

  def add_constraint_id(attrs, %{constraint: constraint}), do: Map.put(attrs, :id, constraint.id)
  def add_constraint_id(attrs, _deps), do: attrs

  def add_variable_id(attrs, %{variable: variable}), do: Map.put(attrs, :variable_id, variable.id)
  def add_variable_id(attrs, _deps), do: attrs

  def add_option_filter_id(attrs, %{option_filter: option_filter}), do: Map.put(attrs, :option_filter_id, option_filter.id)
  def add_option_filter_id(attrs, _deps), do: attrs

  def add_calculation_id(attrs, %{calculation: calculation}), do: Map.put(attrs, :calculation_id, calculation.id)
  def add_calculation_id(attrs, _deps), do: attrs

  def add_decision_id(attrs, %{decision: decision}), do: Map.put(attrs, :decision_id, decision.id)
  def add_decision_id(attrs, _deps), do: attrs

end
