defmodule EtheloApi.Constraints.VariableBuilderTest do
  @moduledoc """
  Validations and basic access for VariableBuilder
  """
  use EtheloApi.DataCase
  import EtheloApi.Structure.Factory

  alias EtheloApi.Constraints.VariableBuilder
  alias EtheloApi.Structure.Variable

  # helper method to make it easier to compare lists of variables
  def convert_variables_to_expanded_tuples(list), do: Enum.map(list, &convert_variable_to_expanded_tuple/1)
  def convert_variable_to_expanded_tuple(variable) do
    option_detail_id = id_if_present(variable, :option_detail)
    option_filter_id = id_if_present(variable, :option_filter)
    decision_id = id_if_present(variable, :decision)
    {variable.method, variable.slug, variable.title, option_detail_id, option_filter_id, decision_id}
  end

  def assert_variables_in_result(%Variable{} = variable, result) do
    assert_variables_in_result([variable], result)
  end

  def assert_variables_in_result(variables, result) when is_list(variables) do
    variables = convert_variables_to_expanded_tuples(variables)
    result = convert_variables_to_expanded_tuples(result)

    for variable <- variables do
      assert variable in result
    end
  end

  def setup_filter(format, title, slug, value) do
    decision = create_decision()
    %{option_detail: option_detail} = create_option_detail(decision, %{format: format, title: "#{title}", slug: "#{slug}"})
    create_option_detail_filter(decision, %{
      option_detail: option_detail, match_value: value,
      title: "#{title} #{value}", slug: "#{option_detail.slug}_#{String.downcase(value)}"
      })
  end

  def assert_expected_number_of_variables(variables, result) do
    assert Enum.count(variables) == Enum.count(result),
      message: "expected #{Enum.count(variables)} variables, got #{Enum.count(result)}"
  end

  def detail_variable_struct(option_detail, method, title, slug) do
    %Variable{
      method: method,
      option_detail_id: option_detail.id,
      decision_id: option_detail.decision_id,
      slug: slug,
      title: title,
    }
  end

  def filter_variable_struct(option_filter, method, title, slug) do
    %Variable{
      method: method,
      option_filter_id: option_filter.id,
      decision_id: option_filter.decision_id,
      slug: slug,
      title: title,
    }
  end

  describe "with no details or filters" do
    test "suggests no variables" do
      result = VariableBuilder.valid_variables([], [])
      assert [] = result
    end
  end

  describe "id values filled in" do
    test "with a single variable" do
      %{variable: variable, option_detail: option_detail} = create_detail_variable()
      id = variable.id

      result = VariableBuilder.valid_variables([option_detail], [])
      ids = extract_ids(result)

      assert id in ids

    end

    test "with multiple variables" do
      decision = create_decision()
      %{variable: detail_var, option_detail: option_detail} = create_detail_variable(decision)
      %{variable: filter_var, option_filter: option_filter} = create_filter_variable(decision)

      result = VariableBuilder.valid_variables([option_detail], [option_filter])
      ids = extract_ids(result)

      assert detail_var.id in ids
      assert filter_var.id in ids
    end
  end

  describe "with filtered float detail" do
    test "creates variables" do
      %{option_detail: option_detail, option_filter: option_filter} = setup_filter(:float, "Float", "float", "1.3")

      result = VariableBuilder.valid_variables([option_detail], [option_filter])

      expected = [
        filter_variable_struct(option_filter, :count_selected, "Count Float 1.3", "count_float_1_3"),
        detail_variable_struct(option_detail, :sum_selected, "Total Float", "total_float"),
        detail_variable_struct(option_detail, :mean_selected, "Avg Float", "avg_float"),
      ]

      assert_variables_in_result(expected, result)
      assert_expected_number_of_variables(expected, result)
    end
  end

  describe "with filtered integer detail" do
    test "creates variables" do
      %{option_detail: option_detail, option_filter: option_filter} = setup_filter(:integer, "Integer", "integer", "1")

      result = VariableBuilder.valid_variables([option_detail], [option_filter])

      expected = [
        filter_variable_struct(option_filter, :count_selected, "Count Integer 1", "count_integer_1"),
        detail_variable_struct(option_detail, :sum_selected, "Total Integer", "total_integer"),
        detail_variable_struct(option_detail, :mean_selected, "Avg Integer", "avg_integer"),
      ]

      assert_variables_in_result(expected, result)
      assert_expected_number_of_variables(expected, result)
    end
  end

  describe "with filtered string detail " do

    test "creates expected variables" do
      %{option_detail: option_detail, option_filter: option_filter} = setup_filter(:string, "String", "string", "foo")

      result = VariableBuilder.valid_variables([option_detail], [option_filter])
      expected = [
        filter_variable_struct(option_filter, :count_selected, "Count String foo", "count_string_foo"),
      ]
      assert_variables_in_result(expected, result)
      assert_expected_number_of_variables(expected, result)
    end

  end

  describe "with filtered boolean detail" do

    test "create expected variables" do
      %{option_detail: option_detail, option_filter: option_filter} = setup_filter(:boolean, "Boolean", "boolean", "true")

      result = VariableBuilder.valid_variables([option_detail], [option_filter])

      expected = [
        filter_variable_struct(option_filter, :count_selected, "Count Boolean true", "count_boolean_true"),
      ]

      assert_variables_in_result(expected, result)
      assert_expected_number_of_variables(expected, result)
    end

  end
end
