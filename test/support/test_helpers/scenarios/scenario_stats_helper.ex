defmodule EtheloApi.Scenarios.TestHelper.ScenarioStatsHelper do
  @moduledoc """
  Scenario specific test tools
  """

  import EtheloApi.TestHelper.GenericHelper

  def fields() do
    %{
      abstain_votes: :integer,
      approval: :float,
      average_weight: :float,
      combined_allocation: :integer,
      criteria_id: :string,
      dissonance: :float,
      ethelo: :float,
      final_allocation: :integer,
      issue_id: :string,
      negative_votes: :integer,
      neutral_votes: :integer,
      option_id: :string,
      positive_seed_votes_sq: :integer,
      positive_seed_votes_sum: :integer,
      positive_votes: :integer,
      scenario_id: :string,
      seeds_assigned: :integer,
      seed_allocation: :integer,
      support: :float,
      total_votes: :integer,
      vote_allocation: :integer
    }
  end

  def decimals_to_floats(attrs) do
    attrs = decimal_attr_to_float(attrs, :support)
    attrs = decimal_attr_to_float(attrs, :approval)
    attrs = decimal_attr_to_float(attrs, :average_weight)
    attrs = decimal_attr_to_float(attrs, :dissonance)
    attrs = decimal_attr_to_float(attrs, :ethelo)
    attrs
  end

  def add_associations(values, %{} = deps \\ %{}) do
    values
    |> add_criteria_id(deps)
    |> add_issue_id(deps)
    |> add_option_id(deps)
    |> add_scenario_config_id(deps)
    |> add_scenario_id(deps)
  end

  def base_quadratic_stats(%{} = deps \\ %{}) do
    %{
      abstain_votes: 0,
      advanced_stats: [],
      approval: 1.0,
      combined_allocation: 780_000,
      dissonance: 0.0,
      ethelo: 0.5042355300353356,
      final_allocation: 175_000,
      histogram: [0, 0, 0, 0, 0],
      negative_votes: 0,
      neutral_votes: 0,
      positive_seed_votes_sq: 7,
      positive_seed_votes_sum: 7,
      positive_votes: 0,
      seed_allocation: 585_001,
      seeds_assigned: 82,
      support: 0.008471060070671233,
      total_votes: 2,
      vote_allocation: 194_999
    }
    |> add_associations(deps)
  end

  def base_scenario_stats(%{} = deps \\ %{}) do
    %{
      total_votes: 3,
      support: 0.5,
      positive_votes: 4,
      neutral_votes: 0,
      negative_votes: 0,
      histogram: [0, 0, 0, 2, 2],
      ethelo: 0.5,
      dissonance: 0.25,
      approval: 0.6666666666666666,
      advanced_stats: [0, 0],
      abstain_votes: 0
    }
    |> add_associations(deps)
  end

  def add_issue_id(attrs, %{option_category: option_category}),
    do: Map.put(attrs, :issue_id, option_category.id)

  def add_issue_id(attrs, _deps), do: attrs
end
