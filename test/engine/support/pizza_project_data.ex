defmodule TestSupport.PizzaProjectData do
  @moduledoc false

  # inspect dump of ScoringData (all_voting, decision_json_data, scenario_import_data)
  # use when database isn't required
  def scoring_data() do
    %Engine.Invocation.ScoringData{
      auto_constraints: [
        %{calculation_id: nil, enabled: true, lhs: nil, operator: :equal_to, option_filter_id: 1, public: false, relaxable: true, rhs: 1.0, slug: "__auto_xor11", title: "__auto_xor11", variable_id: 11}
      ],
      bin_votes: [
        %{bin: 3, criteria_id: 2, decision_id: 1, option_id: 1, participant_id: 1},
        %{bin: 3, criteria_id: 1, decision_id: 1, option_id: 1, participant_id: 1},
        %{bin: 5, criteria_id: 2, decision_id: 1, option_id: 2, participant_id: 1},
        %{bin: 5, criteria_id: 1, decision_id: 1, option_id: 2, participant_id: 1},
        %{bin: 2, criteria_id: 2, decision_id: 1, option_id: 3, participant_id: 1},
        %{bin: 5, criteria_id: 1, decision_id: 1, option_id: 3, participant_id: 1},
        %{bin: 2, criteria_id: 2, decision_id: 1, option_id: 4, participant_id: 1},
        %{bin: 2, criteria_id: 1, decision_id: 1, option_id: 4, participant_id: 1},
        %{bin: 5, criteria_id: 2, decision_id: 1, option_id: 5, participant_id: 1},
        %{bin: 1, criteria_id: 1, decision_id: 1, option_id: 5, participant_id: 1},
        %{bin: 2, criteria_id: 2, decision_id: 1, option_id: 1, participant_id: 2},
        %{bin: 2, criteria_id: 1, decision_id: 1, option_id: 1, participant_id: 2},
        %{bin: 5, criteria_id: 2, decision_id: 1, option_id: 2, participant_id: 2},
        %{bin: 5, criteria_id: 1, decision_id: 1, option_id: 2, participant_id: 2},
        %{bin: 2, criteria_id: 2, decision_id: 1, option_id: 3, participant_id: 2},
        %{bin: 5, criteria_id: 1, decision_id: 1, option_id: 3, participant_id: 2},
        %{bin: 1, criteria_id: 2, decision_id: 1, option_id: 4, participant_id: 2},
        %{bin: 3, criteria_id: 1, decision_id: 1, option_id: 4, participant_id: 2},
        %{bin: 2, criteria_id: 2, decision_id: 1, option_id: 5, participant_id: 2},
        %{bin: 5, criteria_id: 1, decision_id: 1, option_id: 5, participant_id: 2}
      ],
      bin_votes_by_option: %{
        1 => [
          %{bin: 3, criteria_id: 2, decision_id: 1, option_id: 1, participant_id: 1},
    		  %{bin: 3, criteria_id: 1, decision_id: 1, option_id: 1, participant_id: 1},
    		  %{bin: 2, criteria_id: 2, decision_id: 1, option_id: 1, participant_id: 2},
    		  %{bin: 2, criteria_id: 1, decision_id: 1, option_id: 1, participant_id: 2}
        ],
    		2 => [
          %{bin: 5, criteria_id: 2, decision_id: 1, option_id: 2, participant_id: 1},
    		  %{bin: 5, criteria_id: 1, decision_id: 1, option_id: 2, participant_id: 1},
    		  %{bin: 5, criteria_id: 2, decision_id: 1, option_id: 2, participant_id: 2},
    		  %{bin: 5, criteria_id: 1, decision_id: 1, option_id: 2, participant_id: 2}
        ],
    		3 => [
          %{bin: 2, criteria_id: 2, decision_id: 1, option_id: 3, participant_id: 1},
    		  %{bin: 5, criteria_id: 1, decision_id: 1, option_id: 3, participant_id: 1},
    		  %{bin: 2, criteria_id: 2, decision_id: 1, option_id: 3, participant_id: 2},
    		  %{bin: 5, criteria_id: 1, decision_id: 1, option_id: 3, participant_id: 2}
        ],
    		4 => [
          %{bin: 2, criteria_id: 2, decision_id: 1, option_id: 4, participant_id: 1},
    		  %{bin: 2, criteria_id: 1, decision_id: 1, option_id: 4, participant_id: 1},
    		  %{bin: 1, criteria_id: 2, decision_id: 1, option_id: 4, participant_id: 2},
    		  %{bin: 3, criteria_id: 1, decision_id: 1, option_id: 4, participant_id: 2}
        ],
    		5 => [
          %{bin: 5, criteria_id: 2, decision_id: 1, option_id: 5, participant_id: 1},
    		  %{bin: 1, criteria_id: 1, decision_id: 1, option_id: 5, participant_id: 1},
    		  %{bin: 2, criteria_id: 2, decision_id: 1, option_id: 5, participant_id: 2},
    		  %{bin: 5, criteria_id: 1, decision_id: 1, option_id: 5, participant_id: 2}
        ]
      },
      calculations: [
        %{decision_id: 1, expression: " total_inches * total_inches * ( 3.14 / 4 ) / 14 - ( 0.2 * count_cheese_yes ) ", id: 2, public: false, slug: "feeds"},
    		%{decision_id: 1, expression: " count_all_options ", id: 3, public: true, slug: "pizza_count"},
    		%{decision_id: 1, expression: " total_cost * 1.20 ", id: 1, public: true, slug: "total_cost"}
      ],
      calculations_by_slug: %{
        "feeds" => %{decision_id: 1, expression: " total_inches * total_inches * ( 3.14 / 4 ) / 14 - ( 0.2 * count_cheese_yes ) ", id: 2, public: false, slug: "feeds"},
    		 "pizza_count" => %{decision_id: 1, expression: " count_all_options ", id: 3, public: true, slug: "pizza_count"},
    		 "total_cost" => %{decision_id: 1, expression: " total_cost * 1.20 ", id: 1, public: true, slug: "total_cost"
        }
      },
      constraints: [
        %{calculation_id: 1, decision_id: 1, enabled: true, id: 4, lhs: nil, operator: :less_than_or_equal_to, option_filter_id: 1, relaxable: false, rhs: 9.1e4, slug: "budget", variable_id: nil},
    		%{calculation_id: 2, decision_id: 1, enabled: true, id: 6, lhs: nil, operator: :greater_than_or_equal_to, option_filter_id: 2, relaxable: false, rhs: 2.0, slug: "mèat_fed", variable_id: nil},
    		%{calculation_id: nil, decision_id: 1, enabled: true, id: 3, lhs: nil, operator: :greater_than_or_equal_to, option_filter_id: 1, relaxable: false, rhs: 1.0, slug: "mèat_min", variable_id: 3},
    		%{calculation_id: nil, decision_id: 1, enabled: true, id: 1, lhs: nil, operator: :greater_than_or_equal_to, option_filter_id: 1, relaxable: false, rhs: 1.0, slug: "one_cheese", variable_id: 4},
    		%{calculation_id: 2, decision_id: 1, enabled: true, id: 5, lhs: nil, operator: :greater_than_or_equal_to, option_filter_id: 3, relaxable: false, rhs: 2.0, slug: "veg_fed", variable_id: nil},
    		%{calculation_id: nil, decision_id: 1, enabled: true, id: 2, lhs: nil, operator: :greater_than_or_equal_to, option_filter_id: 1, relaxable: false, rhs: 1.0, slug: "veg_min", variable_id: 2}
      ],
      constraints_by_slug: %{
        "budget" => %{calculation_id: 1, decision_id: 1, enabled: true, id: 4, lhs: nil, operator: :less_than_or_equal_to, option_filter_id: 1, relaxable: false, rhs: 9.1e4, slug: "budget", variable_id: nil},
    		"mèat_fed" => %{calculation_id: 2, decision_id: 1, enabled: true, id: 6, lhs: nil, operator: :greater_than_or_equal_to, option_filter_id: 2, relaxable: false, rhs: 2.0, slug: "mèat_fed", variable_id: nil},
    		"mèat_min" => %{calculation_id: nil, decision_id: 1, enabled: true, id: 3, lhs: nil, operator: :greater_than_or_equal_to, option_filter_id: 1, relaxable: false, rhs: 1.0, slug: "mèat_min", variable_id: 3},
    		"one_cheese" => %{calculation_id: nil, decision_id: 1, enabled: true, id: 1, lhs: nil, operator: :greater_than_or_equal_to, option_filter_id: 1, relaxable: false, rhs: 1.0, slug: "one_cheese", variable_id: 4},
    		"veg_fed" => %{calculation_id: 2, decision_id: 1, enabled: true, id: 5, lhs: nil, operator: :greater_than_or_equal_to, option_filter_id: 3, relaxable: false, rhs: 2.0, slug: "veg_fed", variable_id: nil},
    		"veg_min" => %{calculation_id: nil, decision_id: 1, enabled: true, id: 2, lhs: nil, operator: :greater_than_or_equal_to, option_filter_id: 1, relaxable: false, rhs: 1.0, slug: "veg_min", variable_id: 2
        }
      },
      criteria_weights: [
        %{criteria_id: 1, decision_id: 1, participant_id: 1, weighting: 68},
        %{criteria_id: 1, decision_id: 1, participant_id: 2, weighting: 50}
      ],
      criteria_weights_by_criteria: %{
        1 => [
          %{criteria_id: 1, decision_id: 1, participant_id: 1, weighting: 68},
		      %{criteria_id: 1, decision_id: 1, participant_id: 2, weighting: 50}
        ]
      },
      criterias: [
        %{apply_participant_weights: false, decision_id: 1, deleted: false, id: 2, slug: "taste", weighting: 36},
		    %{apply_participant_weights: true, decision_id: 1, deleted: false, id: 1, slug: "value", weighting: 92}
      ],
      criterias_by_slug: %{
        "taste" => %{apply_participant_weights: false, decision_id: 1, deleted: false, id: 2, slug: "taste", weighting: 36},
		    "value" => %{apply_participant_weights: true, decision_id: 1, deleted: false, id: 1, slug: "value", weighting: 92}
      },
      decision: %{
        slug: "pizza-project", title: "Pizza Project", copyable: false, id: 1, keywords: [], influent_hash: "576460752303418590", info: "", internal: false, language: "en", max_users: 25, preview_decision_hash: "3F17976A8DAD1C72E0BC13F227148EB4", published_decision_hash: "576460752303418654", weighting_hash: "576460752303418558"
      },
      quadratic_totals: %{
        by_oc: [],
        global: %{}
       },
      options: [
        %{decision_id: 1, deleted: false, determinative: true, enabled: true, id: 1, option_category_id: 2, slug: "pepperoni_mushroom"},
        %{decision_id: 1, deleted: false, determinative: false, enabled: true, id: 2, option_category_id: 3, slug: "large_cheese"},
    		%{decision_id: 1, deleted: false, determinative: false, enabled: true, id: 3, option_category_id: 3, slug: "regular_cheese"},
        %{decision_id: 1, deleted: false, determinative: false, enabled: true, id: 4, option_category_id: 2, slug: "mèat_lovers"},
    		%{decision_id: 1, deleted: false, determinative: false, enabled: true, id: 5, option_category_id: 3, slug: "veggie_lovers"},
    		%{decision_id: 1, deleted: false, determinative: false, enabled: true, id: 6, option_category_id: 4, slug: "xor-1"},
    		%{decision_id: 1, deleted: false, determinative: false, enabled: true, id: 7, option_category_id: 4, slug: "xor-2"}
      ],
      options_by_id: %{
        1 => %{decision_id: 1, deleted: false, determinative: true, enabled: true, id: 1, option_category_id: 2, slug: "pepperoni_mushroom"},
        2 => %{decision_id: 1, deleted: false, determinative: false, enabled: true, id: 2, option_category_id: 3, slug: "large_cheese"},
        3 => %{decision_id: 1, deleted: false, determinative: false, enabled: true, id: 3, option_category_id: 3, slug: "regular_cheese"},
        4 => %{decision_id: 1, deleted: false, determinative: false, enabled: true, id: 4, option_category_id: 2, slug: "mèat_lovers"},
        5 => %{decision_id: 1, deleted: false, determinative: false, enabled: true, id: 5, option_category_id: 3, slug: "veggie_lovers"},
        6 => %{decision_id: 1, deleted: false, determinative: false, enabled: true, id: 6, option_category_id: 4, slug: "xor-1"},
        7 => %{decision_id: 1, deleted: false, determinative: false, enabled: true, id: 7, option_category_id: 4, slug: "xor-2"}
      },
      options_by_oc: %{
        2 => [
          %{decision_id: 1, deleted: false, determinative: false, enabled: true, id: 4, option_category_id: 2, slug: "mèat_lovers"},
          %{decision_id: 1, deleted: false, determinative: true, enabled: true, id: 1, option_category_id: 2, slug: "pepperoni_mushroom"}
        ],
        3 => [
          %{decision_id: 1, deleted: false, determinative: false, enabled: true, id: 2, option_category_id: 3, slug: "large_cheese"},
          %{decision_id: 1, deleted: false, determinative: false, enabled: true, id: 3, option_category_id: 3, slug: "regular_cheese"},
          %{decision_id: 1, deleted: false, determinative: false, enabled: true, id: 5, option_category_id: 3, slug: "veggie_lovers"}
        ],
        4 => [
          %{decision_id: 1, deleted: false, determinative: false, enabled: true, id: 6, option_category_id: 4, slug: "xor-1"},
          %{decision_id: 1, deleted: false, determinative: false, enabled: true, id: 7, option_category_id: 4, slug: "xor-2"}
        ]
      },
       options_by_slug: %{
        "large_cheese" => %{decision_id: 1, deleted: false, determinative: false, enabled: true, id: 2, option_category_id: 3, slug: "large_cheese"},
    		"mèat_lovers" => %{decision_id: 1, deleted: false, determinative: false, enabled: true, id: 4, option_category_id: 2, slug: "m_at_lovers"},
    		"pepperoni_mushroom" => %{decision_id: 1, deleted: false, determinative: true, enabled: true, id: 1, option_category_id: 2, slug: "pepperoni_mushroom"},
    		"regular_cheese" => %{decision_id: 1, deleted: false, determinative: false, enabled: true, id: 3, option_category_id: 3, slug: "regular_cheese"},
    		"veggie_lovers" => %{decision_id: 1, deleted: false, determinative: false, enabled: true, id: 5, option_category_id: 3, slug: "veggie_lovers"},
    		"xor-1" => %{decision_id: 1, deleted: false, determinative: false, enabled: true, id: 6, option_category_id: 4, slug: "xor-1"},
    		"xor-2" => %{decision_id: 1, deleted: false, determinative: false, enabled: true, id: 7, option_category_id: 4, slug: "xor-2"
        }
      },
   option_ids_by_filter_id: %{
        1 => [2, 4, 1, 3, 5, 6, 7],
        2 => [4, 1],
        3 => [5, 3, 2],
        4 => [3, 2],
        5 => [5, 4, 1],
        6 => [],
        7 => [6, 7],
        8 => [2, 3, 5],
        9 => [4, 1],
        10 => []
      },
       option_ids_by_filter_slug: %{
        "all_options" => [2, 4, 1, 3, 5, 6, 7],
        "cheese-no" => [5, 4, 1],
        "cheese-yes" => [3, 2],
        "mèat-1" => [4, 1],
        "uncategorized-options" => [],
        "vegetarian-1" => [2, 3, 5],
        "vegetarian-no" => [4, 1],
        "vegetarian-yes" => [5, 3, 2],
        "xorcat" => [6, 7],
        "xorcat2" => []
      },

      option_categories: [
        %{apply_participant_weights: false, decision_id: 1, deleted: false, id: 1, primary_detail_id: nil, quadratic: false, scoring_mode: :none, slug: "uncategorized", title: "Uncategorized Options", triangle_base: 2, weighting: 100, xor: false},
        %{apply_participant_weights: false, decision_id: 1, deleted: false, id: 2, primary_detail_id: nil, quadratic: false, scoring_mode: :none, slug: "mèat", title: "Mèat", triangle_base: 2, weighting: 100, xor: false},
        %{apply_participant_weights: true, decision_id: 1, deleted: false, id: 3, primary_detail_id: nil, quadratic: false, scoring_mode: :none, slug: "vegetarian", title: "Vegetarian", triangle_base: 2, weighting: 100, xor: false},
        %{apply_participant_weights: false, decision_id: 1, deleted: false, id: 4, primary_detail_id: 1, quadratic: false, scoring_mode: :rectangle, slug: "xorcat", title: "xorCat", triangle_base: 3, weighting: 100, xor: true},
        %{apply_participant_weights: false, decision_id: 1, deleted: false, id: 5, primary_detail_id: 1, quadratic: false, scoring_mode: :rectangle, slug: "xorcat2", title: "xorCat2", triangle_base: 3, weighting: 100, xor: true}
      ],
      option_categories_by_id: %{
        1 => %{apply_participant_weights: false, decision_id: 1, deleted: false, id: 1, primary_detail_id: nil, quadratic: false, scoring_mode: :none, slug: "uncategorized", title: "Uncategorized Options", triangle_base: 2, weighting: 100, xor: false},
        2 => %{apply_participant_weights: false, decision_id: 1, deleted: false, id: 2, primary_detail_id: nil, quadratic: false, scoring_mode: :none, slug: "mèat", title: "Mèat", triangle_base: 2, weighting: 100, xor: false},
        3 => %{apply_participant_weights: true, decision_id: 1, deleted: false, id: 3, primary_detail_id: nil, quadratic: false, scoring_mode: :none, slug: "vegetarian", title: "Vegetarian", triangle_base: 2, weighting: 100, xor: false},
        4 => %{apply_participant_weights: false, decision_id: 1, deleted: false, id: 4, primary_detail_id: 1, quadratic: false, scoring_mode: :rectangle, slug: "xorcat", title: "xorCat", triangle_base: 3, weighting: 100, xor: true},
        5 => %{apply_participant_weights: false, decision_id: 1, deleted: false, id: 5, primary_detail_id: 1, quadratic: false, scoring_mode: :rectangle, slug: "xorcat2", title: "xorCat2", triangle_base: 3, weighting: 100, xor: true}
      },
      option_categories_by_slug: %{
        "mèat" => %{apply_participant_weights: false, decision_id: 1, deleted: false, id: 2, primary_detail_id: nil, quadratic: false, scoring_mode: :none, slug: "mèat", title: "Mèat", triangle_base: 2, weighting: 100, xor: false},
    		"uncategorized" => %{apply_participant_weights: false, decision_id: 1, deleted: false, id: 1, primary_detail_id: nil, quadratic: false, scoring_mode: :none, slug: "uncategorized", title: "Uncategorized Options", triangle_base: 2, weighting: 100, xor: false},
    		"vegetarian" => %{apply_participant_weights: true, decision_id: 1, deleted: false, id: 3, primary_detail_id: nil, quadratic: false, scoring_mode: :none, slug: "vegetarian", title: "Vegetarian", triangle_base: 2, weighting: 100, xor: false},
    		"xorcat" => %{apply_participant_weights: false, decision_id: 1, deleted: false, id: 4, primary_detail_id: 1, quadratic: false, scoring_mode: :rectangle, slug: "xorcat", title: "xorCat", triangle_base: 3, weighting: 100, xor: true},
    		"xorcat2" => %{apply_participant_weights: false, decision_id: 1, deleted: false, id: 5, primary_detail_id: 1, quadratic: false, scoring_mode: :rectangle, slug: "xorcat2", title: "xorCat2", triangle_base: 3, weighting: 100, xor: true}
      },
      option_category_range_votes: [
        %{decision_id: 1, high_option_id: 7, low_option_id: 7, option_category_id: 4, participant_id: 1},
        %{decision_id: 1, high_option_id: 6, low_option_id: 6, option_category_id: 4, participant_id: 2}
      ],
      option_category_range_votes_by_oc: %{
        4 => [
          %{decision_id: 1, high_option_id: 7, low_option_id: 7, option_category_id: 4, participant_id: 1},
          %{decision_id: 1, high_option_id: 6, low_option_id: 6, option_category_id: 4, participant_id: 2}
        ]
      },
      option_category_weights: [
        %{decision_id: 1, option_category_id: 3, participant_id: 1, weighting: 63},
        %{decision_id: 1, option_category_id: 3, participant_id: 2, weighting: 99}
      ],
      option_category_weights_by_oc: %{
        3 => [
          %{decision_id: 1, option_category_id: 3, participant_id: 1, weighting: 63},
          %{decision_id: 1, option_category_id: 3, participant_id: 2, weighting: 99}
        ]
      },
      option_details: [
        %{decision_id: 1, format: :float, id: 1, slug: "cost", title: "Cost"},
        %{decision_id: 1, format: :boolean, id: 2, slug: "cheese", title: "Cheese"},
        %{decision_id: 1, format: :boolean, id: 3, slug: "vegetarian", title: "Vegetarian"},
        %{decision_id: 1, format: :integer, id: 4, slug: "inches", title: "Inches"},
        %{decision_id: 1, format: :string, id: 5, slug: "crust", title: "Crust"}
      ],
      option_details_by_id: %{
        1 => %{decision_id: 1, format: :float, id: 1, slug: "cost", title: "Cost"},
        2 => %{decision_id: 1, format: :boolean, id: 2, slug: "cheese", title: "Cheese"},
        3 => %{decision_id: 1, format: :boolean, id: 3, slug: "vegetarian", title: "Vegetarian"},
        4 => %{decision_id: 1, format: :integer, id: 4, slug: "inches", title: "Inches"},
        5 => %{decision_id: 1, format: :string, id: 5, slug: "crust", title: "Crust"}
      },
      option_detail_values: [
        %{decision_id: 1, option_detail_id: 5, option_id: 5, value: "Thick"},
        %{decision_id: 1, option_detail_id: 4, option_id: 5, value: "14"},
        %{decision_id: 1, option_detail_id: 2, option_id: 5, value: "false"},
        %{decision_id: 1, option_detail_id: 3, option_id: 5, value: "true"},
        %{decision_id: 1, option_detail_id: 1, option_id: 5, value: "18.75"},
        %{decision_id: 1, option_detail_id: 5, option_id: 4, value: "Thick"},
        %{decision_id: 1, option_detail_id: 4, option_id: 4, value: "14"},
        %{decision_id: 1, option_detail_id: 2, option_id: 4, value: "false"},
        %{decision_id: 1, option_detail_id: 3, option_id: 4, value: "false"},
        %{decision_id: 1, option_detail_id: 1, option_id: 4, value: "22.95"},
        %{decision_id: 1, option_detail_id: 5, option_id: 3, value: "Thin"},
        %{decision_id: 1, option_detail_id: 4, option_id: 3, value: "14"},
        %{decision_id: 1, option_detail_id: 2, option_id: 3, value: "true"},
        %{decision_id: 1, option_detail_id: 3, option_id: 3, value: "true"},
        %{decision_id: 1, option_detail_id: 1, option_id: 3, value: "12000.25"},
        %{decision_id: 1, option_detail_id: 5, option_id: 2, value: "Thin"},
        %{decision_id: 1, option_detail_id: 4, option_id: 2, value: "20"},
        %{decision_id: 1, option_detail_id: 2, option_id: 2, value: "true"},
        %{decision_id: 1, option_detail_id: 3, option_id: 2, value: "true"},
        %{decision_id: 1, option_detail_id: 1, option_id: 2, value: "30001"},
        %{decision_id: 1, option_detail_id: 5, option_id: 1, value: "Thick"},
        %{decision_id: 1, option_detail_id: 4, option_id: 1, value: "1400000"},
        %{decision_id: 1, option_detail_id: 2, option_id: 1, value: "false"},
        %{decision_id: 1, option_detail_id: 3, option_id: 1, value: "false"},
        %{decision_id: 1, option_detail_id: 1, option_id: 1, value: "1800000"}
      ],
      option_filters: [
        %{decision_id: 1, id: 1, match_mode: "all_options", match_value: "", option_category_id: nil, option_detail_id: nil, slug: "all_options", title: "All Options"},
        %{decision_id: 1, id: 2, match_mode: "equals", match_value: "false", option_category_id: nil, option_detail_id: 3, slug: "vegetarian-no", title: "Vegetarian No"},
        %{decision_id: 1, id: 3, match_mode: "equals", match_value: "true", option_category_id: nil, option_detail_id: 3, slug: "vegetarian-yes", title: "Vegetarian Yes"},
        %{decision_id: 1, id: 4, match_mode: "equals", match_value: "true", option_category_id: nil, option_detail_id: 2, slug: "cheese-yes", title: "Cheese Yes"},
        %{decision_id: 1, id: 5, match_mode: "equals", match_value: "false", option_category_id: nil, option_detail_id: 2, slug: "cheese-no", title: "Cheese No"},
        %{decision_id: 1, id: 6, match_mode: "in_category", match_value: "", option_category_id: 5, option_detail_id: nil, slug: "xorcat2", title: "xorCat2"},
        %{decision_id: 1, id: 7, match_mode: "in_category", match_value: "", option_category_id: 4, option_detail_id: nil, slug: "xorcat", title: "xorCat"},
        %{decision_id: 1, id: 8, match_mode: "in_category", match_value: "", option_category_id: 3, option_detail_id: nil, slug: "vegetarian-1", title: "Vegetarian"},
        %{decision_id: 1, id: 9, match_mode: "in_category", match_value: "", option_category_id: 2, option_detail_id: nil, slug: "mèat-1", title: "Mèat"},
        %{decision_id: 1, id: 10, match_mode: "in_category", match_value: "", option_category_id: 1, option_detail_id: nil, slug: "uncategorized-options", title: "Uncategorized Options"}
      ],
      scenario_config: %{
        bins: 5, ci: Decimal.from_float(0.5),
        enabled: true,  engine_timeout: 10000,  id: 1,  max_scenarios: 10,
        normalize_influents: false,  normalize_satisfaction: true,
        override_criteria_weights: true,  override_option_category_weights: true,  per_option_satisfaction: false,
        preview_engine_hash: "576460752303410171",  published_engine_hash: "576460752303410139",
        quadratic: false,  skip_solver: false,  slug: "group",  solve_interval: 3600000,
        support_only: false, tipping_point: Decimal.from_float(0.3333), title: "group", ttl: 0
      },
      participants: [
        %{decision_id: 1, id: 2, weighting: Decimal.from_float(1.50)},
        %{decision_id: 1, id: 1, weighting: Decimal.from_float(1.00)}
      ],
      voting_participant_ids: [1, 2],
      variables: [
        %{decision_id: 1, id: 8, method: :mean_selected, option_detail_id: 1, option_filter_id: nil, slug: "avg_cost"},
        %{decision_id: 1, id: 7, method: :mean_selected, option_detail_id: 4, option_filter_id: nil, slug: "avg_inches"},
        %{decision_id: 1, id: 1, method: :count_selected, option_detail_id: nil, option_filter_id: 1, slug: "count_all_options"},
        %{decision_id: 1, id: 9, method: :count_selected, option_detail_id: nil, option_filter_id: 5, slug: "count_cheese_no"},
        %{decision_id: 1, id: 4, method: :count_selected, option_detail_id: nil, option_filter_id: 4, slug: "count_cheese_yes"},
        %{decision_id: 1, id: 13, method: :count_selected, option_detail_id: nil, option_filter_id: 9, slug: "count_m_at"},
        %{decision_id: 1, id: 14, method: :count_selected, option_detail_id: nil, option_filter_id: 10, slug: "count_uncategorized_options"},
        %{decision_id: 1, id: 12, method: :count_selected, option_detail_id: nil, option_filter_id: 8, slug: "count_vegetarian_1"},
        %{decision_id: 1, id: 3, method: :count_selected, option_detail_id: nil, option_filter_id: 2, slug: "count_vegetarian_no"},
        %{decision_id: 1, id: 2, method: :count_selected, option_detail_id: nil, option_filter_id: 3, slug: "count_vegetarian_yes"},
        %{decision_id: 1, id: 11, method: :count_selected, option_detail_id: nil, option_filter_id: 7, slug: "count_xorcat"},
        %{decision_id: 1, id: 10, method: :count_selected, option_detail_id: nil, option_filter_id: 6, slug: "count_xorcat2"},
        %{decision_id: 1, id: 5, method: :sum_selected, option_detail_id: 1, option_filter_id: nil, slug: "total_cost"},
        %{decision_id: 1, id: 6, method: :sum_selected, option_detail_id: 4, option_filter_id: nil, slug: "total_inches"}
      ],
    }
  end
end
