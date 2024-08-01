defmodule EtheloApi.Scenarios.Docs.ScenarioStats do
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

  @scenario_set_id "The ScenarioSet the stats belong to."
  @scenario_id "The Scenario the stats belong to if any. If generated from the default (display) CI no Scenario is associated."
  @criteria_id "The Criteria the stats belong to."
  @option_id "The Option the stats belong to."
  @issue_id "The Issue (Option Category) the stats belong to."

  # quad_data
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

      # quad_data
      %{name: :combined_allocation, info: @combined_allocation, type: :integer, required: false},
      %{name: :final_allocation, info: @final_allocation, type: :integer, required: false},
      %{
        name: :positive_seed_votes_sq,
        info: @positive_seed_votes_sq,
        type: :integer,
        required: false
      },
      %{
        name: :positive_seed_votes_sum,
        info: @positive_seed_votes_sum,
        type: :integer,
        required: false
      },
      %{name: :seed_allocation, info: @seed_allocation, type: :integer, required: false},
      %{name: :seeds_assigned, info: @seeds_assigned, type: :integer, required: false}
    ]
  end

  @doc """
  a list of maps describing all Scenario schema fields

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
    %{
      "Sample1" => %{
        abstain_votes: 0,
        advanced_stats: [0, 0],
        approval: 0.6666666666666666,
        combined_allocation: nil,
        decision_id: 1,
        default: true,
        dissonance: 0.25,
        ethelo: 0.5,
        final_allocation: nil,
        histogram: [0, 0, 0, 2, 2],
        negative_votes: 0,
        neutral_votes: 0,
        option_id: 2,
        positive_seed_votes_sq: nil,
        positive_seed_votes_sum: nil,
        positive_votes: 4,
        scenario_set_id: 1,
        seed_allocation: nil,
        seeds_assigned: nil,
        support: 0.5,
        total_votes: 3,
        vote_allocation: nil
      },
      "Sample2" => %{
        abstain_votes: 0,
        advanced_stats: [0, 0],
        approval: 0.3333333333333333,
        combined_allocation: 151_459,
        decision_id: 1,
        default: true,
        dissonance: 0.2843780517578125,
        ethelo: 0.10546875000000001,
        final_allocation: 50_000,
        histogram: [1, 0, 1, 1, 1],
        negative_votes: 2,
        neutral_votes: 0,
        option_id: 4,
        positive_seed_votes_sq: 9,
        positive_seed_votes_sum: 3,
        positive_votes: 2,
        scenario_set_id: 1,
        seed_allocation: 121_800,
        seeds_assigned: 42,
        support: 0.10546875000000001,
        total_votes: 3,
        vote_allocation: 29_659
      }
    }
  end

  @doc """
  strings describing each field as well as the general concept of "scenario"
  """
  def strings() do
    scenario_stats_strings = %{
      abstain_votes: @abstain_votes,
      advanced_stats: @advanced_stats,
      approval: @approval,
      average_weight: @average_weight,
      combined_allocation: @combined_allocation,
      criteria_id: @criteria_id,
      criteria: @criteria_id,
      default: @default,
      dissonance: @dissonance,
      ethelo: @ethelo,
      final_allocation: @final_allocation,
      histogram: @histogram,
      issue_id: @issue_id,
      negative_votes: @negative_votes,
      neutral_votes: @neutral_votes,
      option_id: @option_id,
      option: @option_id,
      positive_seed_votes_sq: @positive_seed_votes_sq,
      positive_seed_votes_sum: @positive_seed_votes_sum,
      positive_votes: @positive_votes,
      scenario_id: @scenario_id,
      scenario_set_id: @scenario_set_id,
      scenario_set: @scenario_set_id,
      scenario_stats: @scenario_stats,
      scenario: @scenario_id,
      seed_allocation: @seed_allocation,
      seeds_assigned: @seeds_assigned,
      support: @support,
      total_votes: @total_votes,
      vote_allocation: @vote_allocation
    }

    DocsComposer.common_strings() |> Map.merge(scenario_stats_strings)
  end
end
