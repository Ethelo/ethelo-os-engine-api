defmodule Engine.Scenarios.Docs.ScenarioStats do
  @moduledoc "Central repository for documentation strings about ScenarioStats."
  require DocsComposer

  @scenario_stats "Statistics for some aspect of a Scenario."

  @histogram "A histogram for the distribution of support."
  @advanced_stats "A histogram for votes cast through advanced topic voting"
  @total_votes "The number of votes cast."
  @abstain_votes "The difference between the number of influents in total and the number counted in this result."
  @negative_votes "The number of negative votes cast (bin is below neutral)."
  @neutral_votes "The number of neutral votes cast (bin is neutral)."
  @positive_votes "The number of positive votes cast (bin is above neutral)."

  @support "The amount of support garnered (positive vote percentage)."
  @approval "The ratio of positive votes to total votes."
  @dissonance "A measure of how polarized the votes are."
  @ethelo "The value of the Ethelo function, the strength of support."
  @average_weight "The average weight assigned by voters."
  @default "Whether or not the stats were generated for the default (display) CI."

  @scenario_set_id "The scenario set the stats belong to."
  @scenario_id "The scenario the stats belong to if any. If generated from the default (display) CI no scenario is associated."
  @criteria_id "The criteria the stats belong to."
  @option_id "The option the stats belong to."
  @issue_id "The issue the stats belong to."

  #quad_data
  @seed_allocation "Quadratic Voting Amount allocated due to seeds"
  @vote_allocation "Quadratic Voting Amount allocated due to votes"
  @combined_allocation "Quadratic Voting Amount including seed and vote allocations"
  @final_allocation "Quadratic Voting Amount filtered through cutoff"
  @positive_seed_votes_sq "Quadratic Voting Amount positive votes squared"
  @positive_seed_votes_sum "Quadratic Voting Amount positive votes total"
  @seeds_assigned "Quadratic Voting Amount Seeds assigned through voting"

  defp scenario_stats_fields() do
    [
     %{name: :histogram, info: @histogram, type: :array, required: true},
     %{name: :advanced_stats, info: @advanced_stats, type: :array, required: false},
     %{name: :total_votes, info: @total_votes, type: :integer, required: true},
     %{name: :abstain_votes, info: @abstain_votes, type: :integer, required: true},
     %{name: :negative_votes, info: @negative_votes, type: :integer, required: true},
     %{name: :neutral_votes, info: @neutral_votes, type: :integer, required: true},
     %{name: :positive_votes, info: @positive_votes, type: :integer, required: true},

     %{name: :support, info: @support, type: :float, required: true},
     %{name: :approval, info: @approval, type: :float, required: true},
     %{name: :dissonance, info: @dissonance, type: :float, required: true},
     %{name: :ethelo, info: @ethelo, type: :float, required: true},
     %{name: :average_weight, info: @ethelo, type: :float, required: true},
     %{name: :default, info: @default, type: :boolean, required: true},

     %{name: :scenario_set_id, info: @scenario_set_id, type: "id", required: true},
     %{name: :scenario_id, info: @scenario_id, type: "id", required: true},
     %{name: :criteria_id, info: @criteria_id, type: "id", required: true},
     %{name: :option_id, info: @option_id, type: "id", required: true},
     %{name: :issue_id, info: @issue_id, type: "id", required: true},

     #quad_data
     %{name: :combined_allocation, info: @combined_allocation, type: :integer, required: false},
     %{name: :final_allocation, info: @final_allocation, type: :integer, required: false},
     %{name: :positive_seed_votes_sq, info: @positive_seed_votes_sq, type: :integer, required: false},
     %{name: :positive_seed_votes_sum, info: @positive_seed_votes_sum, type: :integer, required: false},
     %{name: :seed_allocation, info: @seed_allocation, type: :integer, required: false},
     %{name: :seeds_assigned, info: @seeds_assigned, type: :integer, required: false},
   ]
  end

  @doc """
  a list of maps describing all scenario schema fields

  Suitable for use with `DocsComposer.schema_fields`.
  """
  def fields() do
    DocsComposer.common_fields([:id, :inserted_at, :updated_at]) ++ scenario_stats_fields()
  end

  @doc """
  Map describing example records

  Suitable for use with `DocsComposer.schema_examples`.
  """
  def examples() do
    %{}
  end

  @doc """
  strings describing each field as well as the general concept of "scenario"
  """
  def strings() do
    scenario_stats_strings = %{
      scenario_stats: @scenario_stats,
      histogram: @histogram,
      advanced_stats: @advanced_stats,
      total_votes: @total_votes,
      abstain_votes: @abstain_votes,
      negative_votes: @negative_votes,
      neutral_votes: @neutral_votes,
      positive_votes: @positive_votes,
      support: @support,
      approval: @approval,
      dissonance: @dissonance,
      ethelo: @ethelo,
      average_weight: @average_weight,
      default: @default,
      scenario_set_id: @scenario_set_id,
      scenario_id: @scenario_id,
      criteria_id: @criteria_id,
      option_id: @option_id,
      issue_id: @issue_id,

      seed_allocation: @seed_allocation,
      vote_allocation: @vote_allocation,
      combined_allocation: @combined_allocation,
      final_allocation: @final_allocation,
      positive_seed_votes_sq: @positive_seed_votes_sq,
      positive_seed_votes_sum: @positive_seed_votes_sum,
      seeds_assigned: @seeds_assigned,
    }
    DocsComposer.common_strings() |> Map.merge(scenario_stats_strings)
  end

end
