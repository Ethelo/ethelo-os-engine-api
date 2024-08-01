defmodule EtheloApi.Structure.TestHelper.CalculationHelper do
  @moduledoc false

  import EtheloApi.Structure.TestHelper.GenericHelper
  import ExUnit.Assertions

  def empty_attrs() do
    %{slug: nil, title: nil, expression: nil, personal_results_title: nil,  display_hint: nil, public: nil, sort: nil}
  end

  def invalid_attrs(deps \\ %{}) do
     %{slug: "  ", expression: "1 -", title: "@@@", public: 3, sort: "a"}
     |> add_calculation_id(deps)
     |> add_decision_id(deps)
  end

  def valid_attrs(deps \\ %{}) do
    %{
      slug: "slug", title: "Title", sort: 1, personal_results_title: "PR Title",
      expression: "1 + 2", display_hint: "sample display_hint", public: true
    }
    |> add_calculation_id(deps)
    |> add_decision_id(deps)
  end

  def assert_equivalent(expected, result) do
    assert expected.title == result.title
    assert expected.personal_results_title == result.personal_results_title
    assert_equivalent_slug(expected.slug, result.slug)
    assert expected.expression == result.expression
    assert expected.public == result.public
    assert expected.display_hint == result.display_hint
    assert expected.sort == result.sort
  end

  def assert_variables_in_result(variables, result) do
    variables = convert_variables_to_tuples(variables)
    result = convert_variables_to_tuples(result)

    for variable <- variables do
      assert variable in result
    end
  end

  def convert_variables_to_tuples(list), do: Enum.map(list, &convert_variable_to_tuple/1)
  def convert_variable_to_tuple(variable) do
    option_filter_id = id_if_present(variable, :option_filter)
    option_detail_id = id_if_present(variable, :option_detail)
    {option_detail_id, option_filter_id, Map.get(variable, :method)}
  end

  def to_graphql_attrs(attrs) do
    attrs
  end

  def add_calculation_id(attrs, %{calculation: calculation}), do: Map.put(attrs, :id, calculation.id)
  def add_calculation_id(attrs, _deps), do: attrs

  def add_decision_id(attrs, %{decision: decision}), do: Map.put(attrs, :decision_id, decision.id)
  def add_decision_id(attrs, _deps), do: attrs

end
