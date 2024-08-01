defmodule Engine.Invocation.ConstraintBuilder do
  @moduledoc """
  Convert constraints and calculations into constraint and display segments
  used by the engine
  """
  import Engine.Invocation.Slugger
  alias Engine.Invocation.ScoringData
  alias EtheloApi.Helpers.ExportHelper
  alias EtheloApi.Constraints.ExpressionParser

  def constraint_and_display_segments(%ScoringData{} = decision_json_data) do
    expressions = expressions(decision_json_data)

    %{
      constraints: constraint_segments(expressions, decision_json_data),
      displays: display_segments(expressions, decision_json_data)
    }
  end

  defp constraint_segments(expressions, decision_json_data) do
    filters_by_id = ExportHelper.group_by_id(decision_json_data.option_filters)

    configured =
      Enum.map(decision_json_data.constraints, fn constraint ->
        expression =
          constraint
          |> expression_for_constraint(expressions)
          |> apply_expression_filter(constraint, filters_by_id)

        code = build_code(expression, constraint.operator, constraint.lhs, constraint.rhs)

        %{name: constraint.slug, code: code, relaxable: constraint.relaxable}
      end)

    auto =
      Enum.map(decision_json_data.auto_constraints, fn constraint ->
        expression =
          constraint
          |> expression_for_constraint(expressions)
          |> apply_expression_filter(constraint, filters_by_id)

        code = build_code(expression, constraint.operator, constraint.lhs, constraint.rhs)

        %{name: constraint.slug, code: code, relaxable: constraint.relaxable}
      end)

    configured ++ auto
  end

  defp display_segments(expressions, decision_json_data) do
    Enum.map(decision_json_data.calculations, fn calculation ->
      %{name: calculation.slug, code: Map.get(expressions.calculations, calculation.id)}
    end)
  end

  defp build_code(expression, operator, lhs, rhs)
  defp build_code(nil, _, _, _), do: nil

  defp build_code(expression, operator, lhs, rhs) when not is_binary(rhs) do
    build_code(expression, operator, lhs, string_for_json(rhs))
  end

  defp build_code(expression, :equal_to, _, rhs) do
    "[#{expression}] = #{rhs}"
  end

  defp build_code(expression, :less_than_or_equal_to, _, rhs) do
    "[#{expression}] <= #{rhs}"
  end

  defp build_code(expression, :greater_than_or_equal_to, _, rhs) do
    "[#{expression}] >= #{rhs}"
  end

  defp build_code(expression, :between, lhs, rhs) do
    "#{string_for_json(lhs)} <= [#{expression}] <= #{rhs}"
  end

  defp expressions(%ScoringData{} = decision_json_data) do
    %{
      calculations:
        decision_json_data.calculations |> Enum.map(&expression_for_calculation/1) |> Map.new(),
      variables: decision_json_data.variables |> Enum.map(&expression_for_variable/1) |> Map.new()
    }
  end

  defp expression_for_constraint(constraint, expressions) do
    Map.get(expressions.variables, constraint.variable_id) ||
      Map.get(expressions.calculations, constraint.calculation_id) || nil
  end

  defp apply_expression_filter(nil, _, _), do: nil

  defp apply_expression_filter(expression, constraint, filters_by_id) do
    case Map.get(filters_by_id, constraint.option_filter_id) do
      nil ->
        nil

      %{match_mode: "all_options"} ->
        expression

      %{slug: slug} ->
        slug = filter_group_slug(slug)
        "filter[$#{slug}]{#{expression}}"

      _ ->
        nil
    end
  end

  defp expression_for_variable(%{} = variable) do
    {variable.id, "@#{variable.slug}"}
  end

  defp expression_for_calculation(%{} = calculation) do
    # ensure spaces around all variables
    expression = " #{calculation.expression} "
    %{variables: variables, parsed: parsed} = ExpressionParser.parse(expression)

    expression =
      variables
      |> Enum.reduce(parsed, fn variable, expression ->
        String.replace(" #{expression} ", " #{variable} ", " @#{variable} ")
      end)
      |> String.replace("{", "(")
      |> String.replace("}", ")")
      |> String.trim()

    {calculation.id, expression}
  end

  defp expression_for_calculation(_), do: nil

  def string_for_json(value) when is_float(value) do
    if Float.floor(value) == Float.ceil(value) do
      value |> :erlang.float_to_binary(decimals: 0)
    else
      value |> :erlang.float_to_binary(decimals: 4)
    end
  end

  def string_for_json(value), do: value |> to_string()
end
