require IEx

# Note - this is designed to be easily skimmable to see differences
# used when a complete decision is needed instead of a subset
# if you need a json-like format, use the Factories directly

defmodule EtheloApi.Blueprints.QuadVotingProject do
  @moduledoc "Generates a decision to test quadratic voting"
  import EtheloApi.Blueprints.QuickBuilder

  def seeds do
    [0, 1, 4, 9, 16, 25]
  end

  def build(with_voting \\ true) do
    data =
      %{}
      |> add_decision(decision_content())
      |> add_criterias(criteria_content())
      |> add_option_details(option_detail_content())
      |> add_option_categories(option_category_content())
      |> add_seed_options_and_values(seed_option_content(), seeds())
      |> add_scenario_config(scenario_config_content())

    data =
      if with_voting === true do
        data
        |> add_participants(participant_content())
        |> add_option_category_range_votes(option_category_range_vote_content())
      else
        data
        # nothing
      end

    EtheloApi.Structure.ensure_filters_and_vars(data[:decision])

    data
  end

  def decision_content() do
    %{title: "Quad Voting Project", slug: "quad_voting", info: ""}
  end

  def criteria_content() do
    # record_key, bins, support_only, title, slug, info, apply_participant_weights
    [
      [:value, 5, true, "Approval", "approval", "", true],
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
        true
      ],
      [:first, "First", "first", "", 100, false, :triangle, :seeds, 5, false, :one, true],
      [:second, "Second", "second", "", 100, false, :triangle, :seeds, 5, false, :one, true],
      [:third, "Third", "third", "", 100, false, :triangle, :seeds, 5, false, :one, true],
      [:fourth, "Fourth", "fourth", "", 100, false, :triangle, :seeds, 5, false, :one, true],
      [:fifth, "Fifth", "fifth", "", 100, false, :triangle, :seeds, 5, false, :one, true],
    ]
  end

  def option_detail_content() do
    # record_key, format, title, slug, public
    [
      [:seeds, :float, "Seeds", "seeds", true],
      ]
  end

  def seed_option_content() do
    # key_base, option_category_key
    [
      [:first, :first],
      [:second, :second],
      [:third, :third],
      [:fourth, :fourth],
      [:fifth, :fifth],
    ]
  end

  def participant_content() do
    # record_key, weighting
    [
      [:one, Decimal.from_float(1.0)],
      [:two, Decimal.from_float(1.0)],
      [:three, Decimal.from_float(1.0)],
      [:four, Decimal.from_float(1.0)],
      [:five, Decimal.from_float(1.0)],
      [:no_influence, Decimal.from_float(0.0)],
      [:no_votes, Decimal.from_float(1.0)]
    ]
  end

  def option_category_range_vote_content() do
    # [participant_key, low_option_key, high_option_key, option_category_key]
    [
      [:one, :first_seed0, :first_seed0, :first],
      [:two, :first_seed16, :first_seed16, :first],
      [:three, :first_seed1, :first_seed1, :first],
      [:four, :first_seed25, :first_seed25, :first],
      [:no_influence, :first_seed1, :first_seed1, :first],

      [:one, :second_seed1, :second_seed1, :second],
      [:two, :second_seed9, :second_seed9, :second],
      [:three, :second_seed0, :second_seed0, :second],
      [:four, :second_seed4, :first_seed4, :second],
      [:five, :second_seed9, :second_seed9, :second],
      [:no_influence, :second_seed1, :second_seed1, :second],

      [:one, :third_seed0, :third_seed0, :third],
      [:two, :third_seed16, :third_seed16, :third],
      [:three, :third_seed1, :third_seed1, :third],
      [:four, :third_seed25, :third_seed25, :third],
      [:no_influence, :third_seed1, :third_seed1, :third],

      [:one, :fourth_seed0, :fourth_seed0, :fourth],
      [:two, :fourth_seed16, :fourth_seed16, :fourth],
      [:three, :fourth_seed1, :fourth_seed1, :fourth],
      [:four, :fourth_seed25, :fourth_seed25, :fourth],
      [:no_influence, :fourth_seed1, :fourth_seed1, :fourth],

      # test amounts below cutoff
      [:one, :fifth_seed1, :fifth_seed1, :fifth],
  ]
  end

  # so far we're only creating one, so we're not using the [] format
  def scenario_config_content() do
    %{
      title: "group",
      slug: "group",
      bins: 5,
      support_only: false,
      per_option_satisfaction: false,
      normalize_satisfaction: true,
      normalize_influents: false,
      max_scenarios: 10,
      ci: Decimal.from_float(0.5),
      tipping_point: Decimal.from_float(0.3333),
      skip_solver: false,
      enabled: true,
      ttl: 0,
      engine_timeout: 10*1000,
      quadratic: true,
      quad_user_seeds: 125,
      quad_total_available: 580_000,
      quad_cutoff: 7500,
      quad_seed_percent: 0.75,
      quad_vote_percent: 0.25,
      quad_max_allocation: 50000,
      quad_round_to: 5000
    }
  end

end
