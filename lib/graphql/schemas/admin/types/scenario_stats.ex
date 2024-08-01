defmodule GraphQL.EtheloApi.AdminSchema.ScenarioStats do
  @moduledoc """
  Base access to decisions
  """
  use DocsComposer, module: Engine.Scenarios.Docs.ScenarioStats

  use Absinthe.Schema.Notation
  alias GraphQL.EtheloApi.Resolvers.ScenarioStats, as: ScenarioStatsResolver

  object :scenario_stats, description: @doc_map.strings.scenario_stats do
    field :scenario_id, :id, description: @doc_map.strings.scenario_id
    field :criteria_id, :id, description: @doc_map.strings.criteria_id
    field :issue_id, :id, description: @doc_map.strings.issue_id
    field :option_id, :id, description: @doc_map.strings.option_id
    field :histogram, list_of(:integer), description: @doc_map.strings.histogram
    field :advanced_stats, list_of(:integer), description: @doc_map.strings.advanced_stats
    field :total_votes, non_null(:integer), description: @doc_map.strings.total_votes
    field :abstain_votes, :integer, description: @doc_map.strings.abstain_votes
    field :negative_votes, non_null(:integer), description: @doc_map.strings.negative_votes
    field :neutral_votes, non_null(:integer), description: @doc_map.strings.neutral_votes
    field :positive_votes, non_null(:integer), description: @doc_map.strings.positive_votes
    field :support, :float, description: @doc_map.strings.support
    field :approval, :float, description: @doc_map.strings.approval
    field :dissonance, :float, description: @doc_map.strings.dissonance
    field :ethelo, :float, description: @doc_map.strings.ethelo
    field :average_weight, :float, description: @doc_map.strings.ethelo

    field :seed_allocation, :integer, description: @doc_map.strings.seed_allocation
    field :vote_allocation, :integer, description: @doc_map.strings.vote_allocation
    field :combined_allocation, :integer, description: @doc_map.strings.combined_allocation
    field :final_allocation, :integer, description: @doc_map.strings.final_allocation
    field :positive_seed_votes_sq, :integer, description: @doc_map.strings.positive_seed_votes_sq
    field :positive_seed_votes_sum, :integer, description: @doc_map.strings.positive_seed_votes_sum
    field :seeds_assigned, :integer, description: @doc_map.strings.seeds_assigned

  end

  object :scenario_stats_list do
    field :scenario_stats, list_of(:scenario_stats) do
      arg :scenario_id, :id, description: "Filter by Scenario id"
      arg :criteria_id, :id, description: "Filter by Criteria id"
      arg :issue_id, :id, description: "Filter by Issue id"
      arg :option_id, :id, description: "Filter by Option id"
    resolve &ScenarioStatsResolver.list/3
    end
  end

end
