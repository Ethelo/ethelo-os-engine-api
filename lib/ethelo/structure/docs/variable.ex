defmodule EtheloApi.Structure.Docs.Variable do
  @moduledoc "Central repository for documentation strings about Variables."

  require DocsComposer

  @decision_id "Unique identifier for the Decision the Variable belongs to. All Variables are associated with a single Decision."

  @title "Name of Variable. Used to generate slug if none supplied"
  @slug "A memorable and communicatable id. Must be suitable to use in a Calculation expression. Slugs must start with a letter and contain no dashes (-). Will be generated automatically from title if empty or not supplied."

  @calculations "Calculations preform arithmetic on Variables."

  @fixed_variable "Fixed Variables are used for constants applied to calculations."

  @filter_variable "Filter Variables are used to access the number of Options matching a filter in a particular scenario."

  @detail_variable "Detail Variables are used to access sums and means (averages) of OptionDetailValues associated with a numeric OptionDetail."

  @variable """
  Configuration for variables to be used in a calculation and their associated constraints.

  Variables are of one of three types: Fixed Variables, Detail Variables and Filter Variables.

  #{@fixed_variable}
  #{@detail_variable}
  #{@filter_variable}
  Calculations can be used to restrict Detail Variables to a subset of OptionDetailValues matched by an OptionFilter.

  If a Variable is associated with a Calculation, it cannot be deleted, and it's slug cannot be changed.
  """

  @method """
  Method used to calculate the Variable value.

  """

  @method_fixed "returns the specific value specified in the 'value' field of the record"
  @method_sum_selected "returns the total value (sum) for all OptionDetailValues in a specified scenario"
  @method_sum_all "returns the total value (sum) for all OptionDetailValues in a Decision"
  @method_mean_selected "returns the average value (mean) for all OptionDetailValues in a specified scenario"
  @method_mean_all "returns the average value (mean) for all OptionDetailValues in a Decision"
  @method_count_selected "returns the number of (count) for all OptionDetailValues in a specified scenario"
  @method_count_all "returns the number of (count) for all OptionDetailValues in a Decision"

  @method_tutorial """
  For Fixed Variables, the method is always 'fixed'

  For Detail Variables, the allowed methods are:
  * `sum_selected`: #{@method_sum_selected}
  * `sum_all`: #{@method_sum_all}
  * `mean_selected`: #{@method_mean_selected}
  * `mean_all`: #{@method_mean_selected}

  For Filter Variables, the allowed methods are:
  * `count_selected`: #{@method_count_selected}
  * `count_all`: #{@method_count_selected}
  """

  @option_detail "Configuration for arbitrary data added to an Option."

  @option_detail_id "The OptionDetail to source the value from. Variables must define either an OptionDetail or an OptionFilter."

  @option_filter "Configuration for filters that match a subset of Options."

  @option_filter_id "The OptionFilter to source the value from. Variables must define either an OptionFilter or an OptionFilter."

  @method_validation "
    If an OptionDetail is configured, must be one of: sum_selected, sum_all, mean_selected, mean_all.
    If an OptionFilter is configured, must be one of: count_selected or count_all.
    If neither is configured, must be fixed
  "

  defp option_detail_fields() do
    [
     %{name: :title, info: @title, type: :string, validation: "Must include at least one word", required: true, automatic: false, immutable: false},
     %{name: :slug, info: @slug, type: :string, required: true, automatic: true, immutable: false, validation: "must be unique"},
     %{name: :method, info: @method, type: :string, required: true, validation: @method_validation},
     %{name: :decision_id, info: @decision_id, type: "id", required: true},
     %{name: :option_detail_id, match_value: @option_detail_id, type: "id", required: "unless option_filter_id is configured", validation: "must be part of the same Decision. Must be blank if option_filter_id is suupplied."},
     %{name: :option_filter_id, match_value: @option_filter_id, type: "id", required: "unless option_detail_id is configured", validation: "must be part of the same Decision Must be blank if option_detail_id is suupplied."},
   ]
  end

  @doc """
  a list of maps describing all option_detail schema fields

  Suitable for use with `DocsComposer.schema_fields`.
  """
  def fields() do
    DocsComposer.common_fields([:id, :inserted_at, :updated_at]) ++ option_detail_fields()
  end

  @doc """
  Map describing example records

  Suitable for use with `DocsComposer.schema_examples`.
  """
  def examples() do
    %{
      "Total Cost" => %{
        id: 1,
        method: "sum_selected",
        title: "Total Cost",
        slug: "total_cost",
        option_detail_id: 2,
        option_filter_id: nil,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      },
      "Grand Total Cost" => %{
        id: 2,
        method: "sum_all",
        title: "All Pizzas Total Cost",
        slug: "all_cost",
        option_detail_id: 2,
        option_filter_id: nil,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      },
      "Average Cost" => %{
        id: 3,
        method: "mean_selected",
        title: "Average Cost",
        slug: "total_cost",
        option_detail_id: 2,
        option_filter_id: nil,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      },
      "Grand Average Cost" => %{
        id: 4,
        method: "mean_all",
        title: "All Pizzas Average Cost",
        slug: "all_cost",
        option_detail_id: 2,
        option_filter_id: nil,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      },
      "Count Vegetarian" => %{
        id: 5,
        method: "count_selected",
        title: "# Vegetarian",
        slug: "vegetarian_count",
        option_detail_id: nil,
        option_filter_id: 1,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      },
      "Count All Vegetarian" => %{
        id: 6,
        method: "count_all",
        title: "# Vegetarian Possible",
        slug: "all_vegetarian_count",
        option_detail_id: nil,
        option_filter_id: 1,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T19:48:16+00:00",
      },
      "Automatic Tip"=> %{
        id: 7,
        method: "fixed",
        title: "Tip Amount",
        slug: "tip",
        option_detail_id: nil,
        option_filter_id: nil,
        value: 0.07,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T19:48:16+00:00",
      },
    }
  end

  @doc """
  strings describing each field as well as the general concept of "variables"
  """
  def strings() do
    strings = %{
      variable: @variable,
      detail_variable: @detail_variable,
      filter_variable: @filter_variable,
      option_detail: @option_detail,
      option_detail_id: @option_detail_id,
      option_filter: @option_filter,
      option_filter_id: @option_filter_id,
      method: @method,
      method_fixed: @method_fixed,
      method_sum_selected: @method_sum_selected,
      method_sum_all: @method_sum_all,
      method_mean_selected: @method_mean_selected,
      method_mean_all: @method_mean_all,
      method_count_selected: @method_count_selected,
      method_count_all:   @method_count_all,
      method_tutorial: @method_tutorial,
      title: @title,
      slug: @slug,
      decision_id: @decision_id,
      calculations: @calculations,
    }
    DocsComposer.common_strings() |> Map.merge(strings)
  end

end
