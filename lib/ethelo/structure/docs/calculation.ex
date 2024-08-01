defmodule EtheloApi.Structure.Docs.Calculation do
  @moduledoc "Central repository for documentation strings about Calculations."

  require DocsComposer

  @decision_id "Unique identifier for the Decision the Calculation belongs to. All Calculations are associated with a single Decision."

  @title "Name of Calculation. Used to generate slug if none supplied"

  @personal_results_title "Name of Calculation to display on Personal Results"

  @calculation """
  Calculations preform arithmetic on variables, and are applied to the scenarios Ethelo generates for your Decision.
  You can use Calculations to ensure scenarios are valid by adding Constraints.

  Each Calculation has a defined expression, which refers to any number of variables.

  The simplest expressions simply display a variable value, while more complex ones can use simple math.

  The results of each calculation will returned along with each Scenario.
  """

  @variables "Variables provide access to aggregate information about options - counts, sums, and means (averages)."

  @expression """
  Mathmatical operation to perform.
  """

  @expression_rules """

    ## RULES
    * ` + ` (add), ` - ` (delete), ` * ` (multiply) or ` / ` (divide) are supported.
    * `()` are used to group calculations.
    * Positive and Negative numbers can be used.
    * Both Integers and Floats (decimals) can be used.
    * Negative numbers are supported
    * Slugs are used to refer to variables. For example `total_cost * 2` refers to a variable with a slug of `total_cost`
  """

  @expression_validation """
  * must include at least one variable or number
  * all referenced variables must exist
  * all parentheses must be matched
  * if a minus (`-`) sign is followed by a number, there must be a space before the number.
  """

  @display_hint """
  An optional string that can be used to trigger display code on the presentation layer.

  For example, a hint of "Dollars" or "Money" could be added to an Calculation to let the presentation layer know to format it as $x.xx
  It is up to the presentation layer to render or parse this field. The Ethelo engine does not use this value.
  """

  @public """
  A boolean that indicates if the Calculation is appropriate to display to participants.

  It is up to the presentation layer to display or hide Calculations based on this field.
  """

  defp calculation_fields() do
    [
     %{name: :title, info: @title, type: :string, validation: "Must include at least one
     word", required: true, automatic: false, immutable: false},
     %{name: :personal_results_title, info: @personal_results_title, type: :string, required: false, automatic: false, immutable: false},
     %{name: :expression, info: @expression, type: :text, required: true, validation: @expression_validation},
     %{name: :display_hint, info: @display_hint, type: :string, required: false},
     %{name: :public, info: @public, type: :boolean, required: false},
     %{name: :decision_id, info: @decision_id, type: "id", required: true},
   ]
  end


  @doc """
  a list of maps describing all calculation schema fields

  Suitable for use with `DocsComposer.schema_fields`.
  """
  def fields() do
    DocsComposer.common_fields([:id, :slug, :sort, :inserted_at, :updated_at]) ++ calculation_fields()
  end

  @doc """
  Map describing example records

  Suitable for use with `DocsComposer.schema_examples`.
  """
  def examples() do
    %{
      "Variable Display" => %{
        id: 1,
        public: true,
        expression: "total_cost",
        title: "Total Cost",
        personal_results_title: nil,
        slug: "total-cost",
        display_hint: "$",
        decision_id: 1,
        sort: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      },
      "Simple Math" => %{
        id: 2,
        public: true,
        expression: "total_square_feet + 4900",
        display_hint: "",
        title: "Total Square Feet",
        personal_results_title: "Sq Ft",
        slug: "total-square-feet",
        decision_id: 1,
        sort: 2,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      },
      "Negative Number" => %{
        id: 3,
        public: true,
        expression: "discount * -1",
        display_hint: "",
        title: "Savings",
        personal_results_title: nil,
        slug: "savings",
        decision_id: 1,
        sort: 3,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      },
      "Number" => %{
        id: 4,
        public: true,
        expression: "32",
        display_hint: "",
        title: "Standard Markup",
        personal_results_title: nil,
      slug: "standard-markup",
        sort: 4,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      },
      "Multiple Variables" => %{
        id: 5,
        public: true,
        expression: "(total_sq_ft * all_options_avg_cost) - total_cost",
        display_hint: "",
        title: "Overage",
        personal_results_title: nil,
        slug: "overage",
        sort: 5,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      },
    }
  end

  @doc """
  strings describing each field as well as the general concept of "calculations"
  """
  def strings() do
    calculation_strings = %{
      calculation: @calculation,
      display_hint: @display_hint,
      public: @public,
      expression: @expression,
      expression_detail: @expression_rules <> "\n ## VALIDATION \n" <> @expression_validation,
      title: @title,
      personal_results_title: @personal_results_title,
      decision_id: @decision_id,
      variables: @variables,
    }
    DocsComposer.common_strings() |> Map.merge(calculation_strings)
  end

end
