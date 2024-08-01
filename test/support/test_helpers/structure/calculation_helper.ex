defmodule EtheloApi.Structure.TestHelper.CalculationHelper do
  @moduledoc """
  Calculation specific test tools
  """

  import EtheloApi.TestHelper.GenericHelper
  import ExUnit.Assertions

  def fields() do
    %{
      display_hint: :string,
      expression: :string,
      id: :string,
      inserted_at: :date,
      personal_results_title: :string,
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
      :expression,
      :personal_results_title,
      :public,
      :slug,
      :sort,
      :title
    ]
  end

  def empty_attrs() do
    %{
      display_hint: nil,
      expression: nil,
      personal_results_title: nil,
      public: nil,
      slug: nil,
      sort: nil,
      title: nil
    }
  end

  def invalid_attrs(deps \\ %{}) do
    %{
      expression: "1 -",
      public: 3,
      slug: "@@@",
      sort: "a",
      title: ""
    }
    |> add_record_id(deps)
    |> add_decision_id(deps)
  end

  def valid_attrs(deps \\ %{}) do
    %{
      display_hint: "sample display_hint",
      expression: "1 + 2",
      personal_results_title: "PR Title",
      public: true,
      slug: "slug",
      sort: 1,
      title: "Title"
    }
    |> add_record_id(deps)
    |> add_decision_id(deps)
  end

  def assert_equivalent(expected, result) do
    assert expected.display_hint == result.display_hint
    assert expected.expression == result.expression
    assert expected.personal_results_title == result.personal_results_title
    assert expected.public == result.public
    assert_equivalent_slug(expected.slug, result.slug)
    assert expected.sort == result.sort
    assert expected.title == result.title
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

  def add_record_id(attrs, %{calculation: calculation}),
    do: Map.put(attrs, :id, calculation.id)

  def add_record_id(attrs, _deps), do: attrs
end
