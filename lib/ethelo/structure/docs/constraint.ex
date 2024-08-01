defmodule EtheloApi.Structure.Docs.Constraint do
  @moduledoc "Central repository for documentation strings about Constraints."

  require DocsComposer

  @decision_id "Unique identifier for the Decision the Constraint belongs to. All Constraints are associated with a single Decision."
  @decision "The Decision the Constraint belongs to. All Constraints are associated with a single Decision."

  @title "Name of Constraint. Used to generate slug if none supplied"

  @relaxable "Indicates if the constraint can be ignored if necessary to get a result"
  @operators ~w(between equal_to greater_than_or_equal_to less_than_or_equal_to)
  @operators_and Enum.join(tl(@operators), ", ") <> " and " <> hd(@operators)
  @operators_string Enum.join(@operators, ", ")

  @operator_between "Calculated value must be greater than or equal to (>=) the lower bound, and less than or equal to (<=) the upper bound."
  @operator_equal_to "Calculated value must be equal to (=) the boundary value."
  @operator_greater_than_or_equal_to "Calculated value must be greater than or equal to (>=) the boundary value."
  @operator_less_than_or_equal_to "Calculated value must be less than or equal to (<=) the boundary value."

  @constraint """
  Constraints are used to limit the options that appear in your decision's solutions.
  Use constraints to add requirements for the number or combination of options, or
  to constrain on calculated values.
  """

  @mini_tutorial """
  #{@constraint}

  Each Constraint takes a calculation or variable, a comparison to use, and
  a number to compare to. If the comparison fails, the scenario is not included.
  Comparisions for #{@operators_and} are supported.

  Example: `The calculation for "Total Cost"` must be `less_than` `85` when filtered by `All Options`.

  Constraints also have an OptionFilter associated with them. This specifies the
  options to be included in the calculation. An "All Options" filter is used for
  global constraints, while specific filters let you constrain on specific aspects

  Example:
  `The calculation for "Total Cost"` must be `less_than` `25` when filtered by `Drinks`.
  `The calculation for "Total Cost"` must be `less_than` `60` when filtered by `Food`.

  While most calculations take a single value to compare to, the "between" comparison
  allows two values, so you can build a comparison like
  `The calculation for "Total Cost"` must be `between` `70` and `100` when filtered by `Drinks`.
  """

  @operator """
  Comparison to support. Allowed values: #{@operators_and}
  """

  @calculation "Configuration for mathmatical expressions applied to a secnario"

  @calculation_id "The Calculation compare to. Constraints must define either a Variable or a Calculation."

  @variable "Configuration for sums, totals and counts of Options and OptionDetailValues."

  @variable_id "The Variable to compare to. Constraints must define either a Variable or a Calculation."

  @option_filter "Configuration for filters that match a subset of Options."

  @option_filter_id "The OptionFilter to apply when calculating values."

  @enabled """
  A boolean that indicates if the Constraint should be included in the Ethelo calculation. Defaults to "true".

  This is a convenience setting to allow you to quickly iterate on a Decision setup without having to recreate Constraints.
  """

  @rhs """
  The right-hand-side of the Constraint, when expressed as `calculated value` `operator` `rhs` or `total_cost less_than 85`.
  """

  @lhs """
  The left-hand-side of the Constraint, when expressed as `calculated value` `between` `lhs` and `rhs` or `total_cost between 70 and 100`.
  """

  @value "Boundary for a single value constraint (all operators except between). Will be null for between constraints."
  @between_low "Lower boundary for a between constraint. Will be null for all other operators."
  @between_high "Upper boundary for a between constraint.  Will be null for all other operators."

  defp constraint_fields() do
    [
     %{name: :title, info: @title, type: :string, validation: "Must include at least one word", required: true, automatic: false, immutable: false},
     %{name: :relaxable, info: @relaxable, type: :boolean, required: true, validation: "must be a boolean"},
     %{name: :operator, info: @operator, type: :string, required: true, validation: "one of #{@operators_string}"},
     %{name: :lhs, info: @lhs, type: :float, required: "if operator is `between`", validation: "Must be a float."},
     %{name: :rhs, info: @rhs, type: :float, required: true, validation: "Must be a float."},
     %{name: :calculation_id, match_value: @calculation_id, type: "id", required: "unless variable_id is configured", validation: "must be part of the same Decision"},
     %{name: :variable_id, match_value: @variable_id, type: "id", required: "unless calculation_id is configured", validation: "must be part of the same Decision"},
     %{name: :option_filter_id, match_value: @option_filter_id, type: "id", required: "unless option_detail_id is configured", validation: "must be part of the same Decision"},
     %{name: :enabled, info: @enabled, type: :boolean, required: false},
     %{name: :decision_id, info: @decision_id, type: "id", required: true},
   ]
  end

  @doc """
  a list of maps describing all constraint schema fields

  Suitable for use with `DocsComposer.schema_fields`.
  """
  def fields() do
    DocsComposer.common_fields([:id, :slug, :inserted_at, :updated_at]) ++ constraint_fields()
  end

  @doc """
  Map describing example records

  Suitable for use with `DocsComposer.schema_examples`.
  """
  def examples() do
    %{
      "Equal To" => %{
        id: 1,
        operator: :equal_to,
        relaxable: true,
        lhs: nil,
        rhs: 6,
        title: "Option Count equal to 6",
        slug: "options-6",
        option_filter_id: 1,
        calculation_id: 0,
        variable_id: 1,
        decision_id: 1,
        enabled: true,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      },
      "Less Than or Equal To" => %{
        id: 3,
        operator: :less_than_or_equal_to,
        relaxable: true,
        lhs: nil,
        rhs: 50,
        title: "Food Cost <= 50",
        slug: "food-cost-no-more-than-50",
        option_filter_id: 2,
        calculation_id: 2,
        variable_id: 2,
        decision_id: 1,
        enabled: true,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      },
      "Greater Than or Equal To" => %{
        id: 5,
        operator: :greater_than_or_equal_to,
        relaxable: true,
        lhs: nil,
        rhs: 20,
        title: "Profit Margin >= 20",
        slug: "profit-at-least-20",
        option_filter_id: 1,
        calculation_id: 4,
        variable_id: nil,
        decision_id: 1,
        enabled: true,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      },
      "Between" => %{
        id: 6,
        operator: :between,
        relaxable: true,
        lhs: 2,
        rhs: 3,
        title: "2 or 3 Vegetarian Options",
        slug: "2-or-3-veg",
        option_filter_id: 4,
        calculation_id: nil,
        variable_id: 5,
        decision_id: 1,
        enabled: true,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T18:48:16+00:00",
      },
    }
  end

  @doc """
  strings describing each field as well as the general concept of "constraints"
  """
  def strings() do
    constraint_strings = %{
      constraint: @constraint,
      operators: @operators,
      operator: @operator,
      rhs: @rhs,
      lhs: @lhs,
      relaxable: @relaxable,
      mini_tutorial: @mini_tutorial,
      calculation: @calculation,
      calculation_id: @calculation_id,
      variable: @variable,
      variable_id: @variable_id,
      option_filter: @option_filter,
      option_filter_id: @option_filter_id,
      enabled: @enabled,
      title: @title,
      decision_id: @decision_id,
      decision: @decision,
      operator_between: @operator_between,
      operator_equal_to: @operator_equal_to,
      operator_greater_than_or_equal_to: @operator_greater_than_or_equal_to,
      operator_less_than_or_equal_to: @operator_less_than_or_equal_to,
      value: @value,
      between_low: @between_low,
      between_high: @between_high,
    }
    DocsComposer.common_strings() |> Map.merge(constraint_strings)
  end

end
