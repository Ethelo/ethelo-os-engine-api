defmodule EtheloApi.Graphql.Schemas.ScenarioStats do
  @moduledoc """
  Base access to ScenarioStats
  """
  use DocsComposer, module: EtheloApi.Scenarios.Docs.ScenarioStats

  use Absinthe.Schema.Notation
  alias EtheloApi.Graphql.Resolvers.ScenarioStats, as: ScenarioStatsResolver
  import Absinthe.Resolution.Helpers, only: [dataloader: 2]

  @desc @doc_map.strings.scenario_stats
  object :scenario_stats do
    @desc @doc_map.strings.abstain_votes
    field :abstain_votes, :integer

    @desc @doc_map.strings.advanced_stats
    field :advanced_stats, list_of(:integer)

    @desc @doc_map.strings.approval
    field :approval, :float

    @desc @doc_map.strings.ethelo
    field :average_weight, :float

    @desc @doc_map.strings.combined_allocation
    field :combined_allocation, :integer

    @desc @doc_map.strings.criteria_id
    field :criteria_id, :id

    @desc @doc_map.strings.criteria_id
    field :criteria, :criteria, resolve: dataloader(:repo, :criteira)

    @desc @doc_map.strings.dissonance
    field :dissonance, :float

    @desc @doc_map.strings.ethelo
    field :ethelo, :float

    @desc @doc_map.strings.final_allocation
    field :final_allocation, :integer

    @desc @doc_map.strings.histogram
    field :histogram, list_of(:integer)

    @desc @doc_map.strings.issue_id
    field :issue_id, :id

    @desc @doc_map.strings.issue_id
    field :option_category, :option_category, resolve: dataloader(:repo, :option_category)

    @desc @doc_map.strings.negative_votes
    field :negative_votes, non_null(:integer)

    @desc @doc_map.strings.neutral_votes
    field :neutral_votes, non_null(:integer)

    @desc @doc_map.strings.option_id
    field :option_id, :id

    @desc @doc_map.strings.option_id
    field :option, :option, resolve: dataloader(:repo, :option)

    @desc @doc_map.strings.positive_seed_votes_sq
    field :positive_seed_votes_sq, :integer

    @desc @doc_map.strings.positive_seed_votes_sum
    field :positive_seed_votes_sum, :integer

    @desc @doc_map.strings.positive_votes
    field :positive_votes, non_null(:integer)

    @desc @doc_map.strings.scenario_id
    field :scenario_id, :id

    @desc @doc_map.strings.scenario_id
    field :scenario, :scenario, resolve: dataloader(:repo, :scenario)

    @desc @doc_map.strings.seed_allocation
    field :seed_allocation, :integer

    @desc @doc_map.strings.seeds_assigned
    field :seeds_assigned, :integer

    @desc @doc_map.strings.support
    field :support, :float

    @desc @doc_map.strings.total_votes
    field :total_votes, non_null(:integer)

    @desc @doc_map.strings.vote_allocation
    field :vote_allocation, :integer
  end

  object :scenario_stats_list do
    field :scenario_stats, list_of(:scenario_stats) do
      @desc "Filter by Criteria id"
      arg(:criteria_id, :id)

      @desc "Filter by Issue id"
      arg(:issue_id, :id)

      @desc "Filter by Option id"
      arg(:option_id, :id)

      @desc "Filter by Scenario id"
      arg(:scenario_id, :id)

      resolve(&ScenarioStatsResolver.list/3)
    end
  end
end
