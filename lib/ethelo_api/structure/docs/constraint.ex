defmodule EtheloApi.Structure.Docs.Constraint do
  @moduledoc "Central repository for documentation strings about Constraints."

  require DocsComposer

  @decision_id "The Decision the Constraint belongs to."

  @title "Name of Constraint. Used to generate slug if none supplied"

  @relaxable "Indicates if the Constraint can be ignored if necessary to get a result"
  @operators ~w(between equal_to greater_than_or_equal_to less_than_or_equal_to)
  @operators_and Enum.join(tl(@operators), ", ") <> " and " <> hd(@operators)
  @operators_string Enum.join(@operators, ", ")

  @operator_between "Calculated value must be greater than or equal to (>=) the lower bound, and less than or equal to (<=) the upper bound."
  @operator_equal_to "Calculated value must be equal to (=) the boundary value."
  @operator_greater_than_or_equal_to "Calculated value must be greater than or equal to (>=) the boundary value."
  @operator_less_than_or_equal_to "Calculated value must be less than or equal to (<=) the boundary value."

  @constraint """
  Constraints are used to limit the Options that appear in your Decision's Scenario Sets (Solutions).
  Use Constraints to add requirements for the number or combination of Options, or
  to Constrain on calculated values.
  """

  @mini_tutorial """
  #{@constraint}

  Each Constraint takes a Calculation or Variable, a comparison to use, and
  a number to compare to. If the comparison fails, the Scenario is not included.
  Comparisions for #{@operators_and} are supported.

  Example: `The Calculation for "Total Cost"` must be `less_than` `85` when filtered by `All Options`.

  Constraints also have an OptionFilter associated with them. This specifies the
  Options to be included in the Calculation. An "All Options" OptionFilters is used for
  global Constraints, while specific OptionFilters let you constrain on specific aspects

  Example:
  `The Calculation for "Total Cost"` must be `less_than` `25` when filtered by `Drinks`.
  `The Calculation for "Total Cost"` must be `less_than` `60` when filtered by `Food`.

  While most Calculations take a single value to compare to, the "between" comparison
  allows two values, so you can build a comparison like
  `The Calculation for "Total Cost"` must be `between` `70` and `100` when filtered by `Drinks`.
  """

  @operator """
  Comparison to support. Allowed values: #{@operators_and}
  """

  @calculation_id "The Calculation compare to. Calculations are mathmatical expressions applied to a secnario, Constraints must define either a Variable or a Calculation."

  @variable_id "The Variable to compare to. Variables define sums, totals and counts of Options and OptionDetailValues. Constraints must define either a Variable or a Calculation."

  @option_filter_id "The OptionFilter to apply when calculating values. Option Filters match a subset of Options."

  @enabled """
  A boolean that indicates if the Constraint should be included when solving with the Ethelo alogrythm. Defaults to "true".

  This is a convenience setting to allow you to quickly iterate on a Decision setup without having to recreate Constraints.
  """

  @rhs """
  The right-hand-side of the Constraint, when expressed as `calculated value` `operator` `rhs` or `total_cost less_than 85`.
  """

  @lhs """
  The left-hand-side of the Constraint, when expressed as `calculated value` `between` `lhs` and `rhs` or `total_cost between 70 and 100`.
  """

  @value "Boundary for a single value Constraint (all operators except between). Will be null for between Constraints."
  @between_low "Lower boundary for a between Constraint. Will be null for all other operators."
  @between_high "Upper boundary for a between Constraint.  Will be null for all other operators."

  defp constraint_fields() do
    [
      %{
        name: :title,
        info: @title,
        type: :string,
        validation: "Must include at least one word",
        required: true,
        automatic: false,
        immutable: false
      },
      %{
        name: :relaxable,
        info: @relaxable,
        type: :boolean,
        required: true,
        validation: "must be a boolean"
      },
      %{
        name: :operator,
        info: @operator,
        type: :string,
        required: true,
        validation: "one of #{@operators_string}"
      },
      %{
        name: :lhs,
        info: @lhs,
        type: :float,
        required: "if operator is `between`",
        validation: "Must be a float."
      },
      %{name: :rhs, info: @rhs, type: :float, required: true, validation: "Must be a float."},
      %{
        name: :calculation_id,
        match_value: @calculation_id,
        type: "id",
        required: "unless variable_id is configured",
        validation: "must be part of the same Decision"
      },
      %{
        name: :variable_id,
        match_value: @variable_id,
        type: "id",
        required: "unless calculation_id is configured",
        validation: "must be part of the same Decision"
      },
      %{
        name: :option_filter_id,
        match_value: @option_filter_id,
        type: "id",
        required: "unless option_detail_id is configured",
        validation: "must be part of the same Decision"
      },
      %{name: :enabled, info: @enabled, type: :boolean, required: false},
      %{name: :decision_id, info: @decision_id, type: "id", required: true}
    ]
  end

  @doc """
  a list of maps describing all Constraint schema fields

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
        updated_at: "2017-05-05T16:48:16+00:00"
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
        updated_at: "2017-05-05T16:48:16+00:00"
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
        updated_at: "2017-05-05T16:48:16+00:00"
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
        updated_at: "2017-05-05T18:48:16+00:00"
      }
    }
  end

  @doc """
  strings describing each field as well as the general concept of "constraints"
  """
  def strings() do
    constraint_strings = %{
      between_high: @between_high,
      between_low: @between_low,
      calculation_id: @calculation_id,
      calculation: @calculation_id,
      constraint: @constraint,
      decision_id: @decision_id,
      enabled: @enabled,
      lhs: @lhs,
      mini_tutorial: @mini_tutorial,
      operator_between: @operator_between,
      operator_equal_to: @operator_equal_to,
      operator_greater_than_or_equal_to: @operator_greater_than_or_equal_to,
      operator_less_than_or_equal_to: @operator_less_than_or_equal_to,
      operator: @operator,
      operators: @operators,
      option_filter_id: @option_filter_id,
      option_filter: @option_filter_id,
      relaxable: @relaxable,
      rhs: @rhs,
      title: @title,
      value: @value,
      variable_id: @variable_id,
      variable: @variable_id
    }

    DocsComposer.common_strings() |> Map.merge(constraint_strings)
  end
end
