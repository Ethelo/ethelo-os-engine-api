defmodule EtheloApi.Graphql.Schemas.Scenario do
  @moduledoc """
  Base access to Scenarios
  """

  use Absinthe.Schema.Notation
  use DocsComposer, module: EtheloApi.Scenarios.Docs.Scenario

  alias EtheloApi.Graphql.Resolvers.Scenario, as: ScenarioResolver
  alias EtheloApi.Graphql.Resolvers.ScenarioStats, as: ScenarioStatsResolver

  import Absinthe.Resolution.Helpers, only: [dataloader: 2]

  @desc @doc_map.strings.scenario
  object :scenario do
    @desc @doc_map.strings.collective_identity
    field :collective_identity, non_null(:float)

    field :displays, list_of(:scenario_display), resolve: dataloader(:repo, :scenario_displays)

    @desc @doc_map.strings.global
    field :global, non_null(:boolean)

    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.inserted_at
    field :inserted_at, non_null(:datetime)

    @desc @doc_map.strings.status
    field :json_stats, non_null(:string)

    @desc @doc_map.strings.minimize
    field :minimize, non_null(:boolean)

    field :options, list_of(:option), resolve: dataloader(:repo, :options)

    field :scenario_stats, :scenario_stats do
      resolve(&ScenarioStatsResolver.for_scenario/3)
    end

    @desc @doc_map.strings.status
    field :status, non_null(:string)

    @desc @doc_map.strings.tipping_point
    field :tipping_point, non_null(:float)

    @desc @doc_map.strings.updated_at
    field :updated_at, non_null(:datetime)
  end

  object :scenario_list do
    field :scenarios, list_of(:scenario) do
      @desc "Number to return. If also filtering by rank, this is ignored"
      arg(:limit, :integer)

      @desc "Filter by global"
      arg(:global, :boolean)

      @desc "Filter by id"
      arg(:id, :id)

      @desc "Filter by Scenario rank, will return 0 or 1 scenarios"
      arg(:rank, :integer)

      @desc "Filter by Scenario status"
      arg(:status, :string)

      resolve(&ScenarioResolver.list/3)
    end
  end
end
