# Note - this is designed to be easily skimmable to see differences
# used when a complete decision is needed instead of a subset
# if you need a json-like format, use the Factories directly

defmodule EtheloApi.Blueprints.PizzaProject do
  @moduledoc "contains all content needed to build out the test pizza project "

  import EtheloApi.Blueprints.QuickBuilder
  import EtheloApi.Structure.Factory

  def build(with_voting \\ true) do
    data =
      %{}
      |> add_decision(decision_content())
      |> add_criterias(criteria_content())
      |> add_option_details(option_detail_content())
      |> add_option_categories(option_category_content())
      |> add_options(option_content())
      |> add_option_detail_values(option_detail_value_content())
      |> add_option_filters(option_filter_content())
      |> add_variables(variable_content())
      |> add_calculations()
      |> add_constraints(constraint_content())
      |> add_scenario_config(scenario_config_content())

    data =
      if with_voting === true do
        data
        |> add_participants(participant_content())
        |> add_bin_votes(bin_vote_content())
        |> add_option_category_range_votes(option_category_range_vote_content())
        |> add_criteria_weights(criteria_weight_content())
        |> add_option_category_weights(option_category_weight_content())
      else
        data
        # nothing
      end

    EtheloApi.Structure.ensure_filters_and_vars(data[:decision])

    data
  end

  def decision_content() do
    %{title: "Pizza Project", slug: "pizza-project", info: ""}
  end

  def criteria_content() do
    # record_key, bins, support_only, title, slug, info, apply_participant_weights
    [
      [:value, 5, true, "Value", "value", "", true],
      [:taste, 5, false, "Taste", "taste", "", false]
    ]
  end

    def option_detail_content() do
      # record_key, format, title, slug, public
      [
        [:cost, :float, "Cost", "cost", true],
        [:cheese, :boolean, "Cheese", "cheese", false],
        [:vegetarian, :boolean, "Vegetarian", "vegetarian", false],
        [:inches, :integer, "Inches", "inches", true],
        [:crust, :string, "Crust", "crust", true],
      ]
    end

  def option_category_content() do
    # record_key, title, slug, info, weighting, xor, scoring_mode, primary_detail_key,
    # triangle_base, apply_participant_weights, voting_style, quadratic

    [
      [
        :uncategorized,
        "Uncategorized Options",
        "uncategorized",
        "",
        100,
        false,
        :none,
        nil,
        nil,
        false,
        :one,
        false
      ],
      [:mèat, "Mèat", "mèat", "", 100, false, :none, nil, nil, false, :one, false],
      [:vegetarian, "Vegetarian", "vegetarian", "", 100, false, :none, nil, nil, true, :one, false],
      [:xorcat, "xorCat", "xorcat", "", 100, true, :rectangle, :cost, 3, false, :one, false],
      [:xorcat2, "xorCat2", "xorcat2", "", 100, true, :rectangle, :cost, 3, false, :one, false]
    ]
  end

  def option_content() do
    # record_key, title, slug, option_category_key, info, enabled

    [
      [
        :pepperoni_mushroom,
        "Pepperoni Mushroom",
        "pepperoni_mushroom",
        :mèat,
        "The classic combination, a perennial favorite.",
        true,
      ],
      [
        :large_cheese,
        "Large Cheese",
        "large_cheese",
        :vegetarian,
        "Cheese, Tomatoe Sauce, Crust. In large size.",
        true,
      ],
      [
        :regular_cheese,
        "Regular Cheese",
        "regular_cheese",
        :vegetarian,
        "Cheese. Tomatoe Sauce. Crust. All you need.",
        true,
      ],
      [
        :mèat_lovers,
        "Mèat Lovers",
        "mèat_lovers",
        :mèat,
        "Mèat on mèat on mèat - a carnivore's delight!",
        true,
      ],
      [
        :veggie_lovers,
        "Veggie Lovers",
        "veggie_lovers",
        :vegetarian,
        "Peppers, Onions and Tomatoes with a White Garlic sauce.",
        true,
      ],
      [
        :xor1,
        "XOR 1",
        "xor-1",
        :xorcat,
        "XOR example 1",
        true,
      ],
      [
        :xor2,
        "XOR 2",
        "xor-2",
        :xorcat,
        "XOR example 2",
        true,
      ],
    ]
  end

  def option_detail_value_content() do
    # option_key, option_detail_key, value
    [
      [:pepperoni_mushroom, :cost, "1800000"],
      [:pepperoni_mushroom, :vegetarian, "false"],
      [:pepperoni_mushroom, :cheese, "false"],
      [:pepperoni_mushroom, :inches, "1400000"],
      [:pepperoni_mushroom, :crust, "Thick"],
      [:large_cheese, :cost, "30001"],
      [:large_cheese, :vegetarian, "true"],
      [:large_cheese, :cheese, "true"],
      [:large_cheese, :inches, "20"],
      [:large_cheese, :crust, "Thin"],
      [:regular_cheese, :cost, "12000.25"],
      [:regular_cheese, :vegetarian, "true"],
      [:regular_cheese, :cheese, "true"],
      [:regular_cheese, :inches, "14"],
      [:regular_cheese, :crust, "Thin"],
      [:mèat_lovers, :cost, "22.95"],
      [:mèat_lovers, :vegetarian, "false"],
      [:mèat_lovers, :cheese, "false"],
      [:mèat_lovers, :inches, "14"],
      [:mèat_lovers, :crust, "Thick"],
      [:veggie_lovers, :cost, "18.75"],
      [:veggie_lovers, :vegetarian, "true"],
      [:veggie_lovers, :cheese, "false"],
      [:veggie_lovers, :inches, "14"],
      [:veggie_lovers, :crust, "Thick"]
    ]
  end

  def option_filter_content() do
    # record_key, option_detail_key, match_mode, match_value, title, slug
    [
      [:all_options, nil, "all_options", "", "All Options", "all_options"],
      [:mèat, :vegetarian, "equals", "false", "Mèat Pizzas", "mèat"],
      [:vegetarian, :vegetarian, "equals", "true", "Vegetarian Pizzas", "vegetarian"],
      [:cheese, :cheese, "equals", "true", "Cheese Pizzas", "cheese"]
    ]
  end

  def variable_content() do
    # option_detail_key, option_filter_key, method, title, slug,
    # some of these will be automatically renamed by ensure_filters_and_vars
    [
      [:pizza_count, nil, :all_options, :count_selected, "# of Pizzas", "count_all_options"],
      [
        :vegetarian_count,
        nil,
        :vegetarian,
        :count_selected,
        "# of Vegetarian Pizzas",
        "count_vegetarian"
      ],
      [:mèat_count, nil, :mèat, :count_selected, "# of Mèat Pizzas", "mèat_selected_count"],
      [
        :cheese_count,
        nil,
        :cheese,
        :count_selected,
        "# of Cheese Pizzas",
        "cheese_selected_count"
      ],
      [:total_cost, :cost, nil, :sum_selected, "Total Cost", "total_cost"],
      [:total_inches, :inches, nil, :sum_selected, "Total Inches", "total_inches"]
    ]
  end

  # add_calculations cannot be simplified because of the string interpolation needed
  # and specifiying multiple variables is tedious
  def add_calculations(%{decision: decision, variables: variables} = data) do
    calculations = %{
      total_cost:
        create_calculation_without_deps(decision, %{
          expression: "#{variables[:total_cost].slug} * 1.20",
          title: "Total Cost with Tip",
          slug: "total_cost",
          personal_results_title: "with Tip",
          variables: [variables[:total_cost]]
        }),
      feeds:
        create_calculation_without_deps(decision, %{
          # number fed is area divided by 14 sq inches per slice, modified so cheese pizzas only feed 0.8 as many people
          expression:
            "#{variables[:total_inches].slug} * #{variables[:total_inches].slug}  * (3.14 / 4) / 14 - (0.2 * #{
              variables[:cheese_count].slug
            })",
          title: "# Fed",
          slug: "feeds",
          variables: [variables[:total_inches], variables[:cheese_count]]
        }),
      pizza_count:
        create_calculation_without_deps(decision, %{
          expression: variables[:pizza_count].slug,
          title: "# of Pizzas",
          slug: "pizza_count",
          variables: [variables[:pizza_count]]
        })
    }

    Map.put(data, :calculations, calculations)
  end

  def constraint_content() do
    # record_key, variable_key, calculation_key, operator, rhs, title, slug, option_filter_key,
    [
      # variable constraints
      [
        :one_cheese,
        :cheese_count,
        nil,
        :greater_than_or_equal_to,
        1.0,
        "Require One Cheese",
        "one_cheese",
        :all_options
      ],
      [
        :veg_min,
        :vegetarian_count,
        nil,
        :greater_than_or_equal_to,
        1.0,
        "Require one Veggie",
        "veg_min",
        :all_options
      ],
      [
        :mèat_min,
        :mèat_count,
        nil,
        :greater_than_or_equal_to,
        1.0,
        "Require one Mèat",
        "mèat_min",
        :all_options
      ],

      # calculation constraints
      [
        :budget,
        nil,
        :total_cost,
        :less_than_or_equal_to,
        91000.0,
        "Max Cost $90",
        "budget",
        :all_options
      ],
      [
        :veg_fed,
        nil,
        :feeds,
        :greater_than_or_equal_to,
        2.0,
        "Feed at least 2 Vegetarian",
        "veg_fed",
        :vegetarian
      ],
      [
        :mèat_fed,
        nil,
        :feeds,
        :greater_than_or_equal_to,
        2.0,
        "Feed at least 2 Mèateater",
        "mèat_fed",
        :mèat
      ]
    ]
  end

  def participant_content() do
    # record_key, weighting
    [
      [:one, Decimal.from_float(1.0)],
      [:two, Decimal.from_float(1.5)],
      [:no_influence, Decimal.from_float(0.0)],
      [:no_votes, Decimal.from_float(1.4)]
    ]
  end

  def bin_vote_content() do
    # [participant_key, option_key, criteria_key, bin]
    [
      [:no_influence, :pepperoni_mushroom, :taste, 1],
      [:no_influence, :pepperoni_mushroom, :value, 1],
      [:no_influence, :large_cheese, :taste, 3],
      [:no_influence, :large_cheese, :value, 3],
      [:no_influence, :regular_cheese, :taste, 4],
      [:no_influence, :regular_cheese, :value, 5],
      [:no_influence, :mèat_lovers, :taste, 4],
      [:no_influence, :mèat_lovers, :value, 4],
      [:no_influence, :veggie_lovers, :taste, 1],
      [:no_influence, :veggie_lovers, :value, 1],
      [:one, :pepperoni_mushroom, :taste, 3],
      [:one, :pepperoni_mushroom, :value, 3],
      [:one, :large_cheese, :taste, 5],
      [:one, :large_cheese, :value, 5],
      [:one, :regular_cheese, :taste, 2],
      [:one, :regular_cheese, :value, 5],
      [:one, :mèat_lovers, :taste, 2],
      [:one, :mèat_lovers, :value, 2],
      [:one, :veggie_lovers, :taste, 5],
      [:one, :veggie_lovers, :value, 1],
      [:two, :pepperoni_mushroom, :taste, 2],
      [:two, :pepperoni_mushroom, :value, 2],
      [:two, :large_cheese, :taste, 5],
      [:two, :large_cheese, :value, 5],
      [:two, :regular_cheese, :taste, 2],
      [:two, :regular_cheese, :value, 5],
      [:two, :mèat_lovers, :taste, 1],
      [:two, :mèat_lovers, :value, 3],
      [:two, :veggie_lovers, :taste, 2],
      [:two, :veggie_lovers, :value, 5]
    ]
  end

  def option_category_range_vote_content() do
    # [participant_key, low_option_key, high_option_key, option_category_key]
    [
      [:no_influence, :xor1, :xor1, :xorcat],
      [:one, :xor2, :xor2, :xorcat],
      [:two, :xor1, :xor1, :xorcat]
    ]
  end

  def criteria_weight_content() do
    # participant_key, criteria_key, weighting
    [
      [:no_influence, :taste, 7],
      [:no_influence, :value, 89],
      [:one, :taste, 48],
      [:one, :value, 68],
      [:two, :taste, 100],
      [:two, :value, 50]
    ]
  end

  def option_category_weight_content() do
    # participant_key, option_category_key, weighting
    [
      [:no_influence, :mèat, 17],
      [:no_influence, :vegetarian, 29],
      [:one, :mèat, 78],
      [:one, :vegetarian, 63],
      [:two, :mèat, 80],
      [:two, :vegetarian, 99]
    ]
  end

  # so far we're only creating one, so we're not using the [] format
  def scenario_config_content() do
    %{
      title: "group",
      slug: "group",
      bins: 5,
      support_only: false,
      quadratic: false,
      per_option_satisfaction: false,
      normalize_satisfaction: true,
      normalize_influents: false,
      max_scenarios: 10,
      ci: Decimal.from_float(0.5),
      tipping_point: Decimal.from_float(0.3333),
      enabled: true,
      skip_solver: false,
      ttl: 0,
      engine_timeout: 10*1000,
    }
  end
end
