# Note - this is designed to be easily skimmable to see differences
# used when a complete Decision is needed instead of a subset
# if you need a json-like format, use the Factories directly

defmodule EtheloApi.Blueprints.SimpleDecision do
  @moduledoc "contains the smallest possible solvable Decision"

  import EtheloApi.Blueprints.QuickBuilder

  def build(with_voting \\ true) do
    data =
      %{}
      |> add_decision(decision_content())
      |> add_criterias(criteria_content())
      |> add_option_details(option_detail_content())
      |> add_option_categories(option_category_content())
      |> add_options(option_content())
      |> add_scenario_config(scenario_config_content())

    data =
      if with_voting === true do
        data
        |> add_participants(participant_content())
        |> add_bin_votes(bin_vote_content())
      else
        data
        # nothing
      end

    EtheloApi.Structure.ensure_filters_and_vars(data[:decision])

    data
  end

  def decision_content() do
    %{title: "Simplest Decision", slug: "simple-decision", info: ""}
  end

  def criteria_content() do
    # record_key, bins, support_only, title, slug, info, apply_participant_weights, weighting
    [
      [:approval, 5, false, "Approval", "approval", "", false, 50]
    ]
  end

  def option_detail_content() do
    # record_key, format, title, slug, public, sort, input_hint, display_hint]
    []
  end

  def option_category_content() do
    # record_key, title, slug, info, results_title,
    one = [:uncategorized, "Uncategorized Options", "uncategorized", "info", "Result"]

    #  weighting, apply_participant_weights, xor, scoring_mode, triangle_base, voting_style, primary_detail_key
    two = [100, true, false, :none, nil, :one, nil]

    # quadratic, budget_percent, flat_feed, vote_on_percent, keywords
    three = [false, nil, nil, false, []]

    [one ++ two ++ three]
  end

  def option_content() do
    # record_key, title, slug, option_category_key, info, enabled

    [
      [
        :test_option,
        "Test Option",
        "test_option",
        :uncategorized,
        "A single, lonely option",
        true
      ]
    ]
  end

  def participant_content() do
    # record_key, weighting
    [
      [:one, Decimal.from_float(1.0)],
      [:no_votes, Decimal.from_float(1.4)]
    ]
  end

  def bin_vote_content() do
    # [participant_key, option_key, criteria_key, bin]
    [
      [:one, :test_option, :approval, 3]
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
      engine_timeout: 10 * 1000
    }
  end
end
