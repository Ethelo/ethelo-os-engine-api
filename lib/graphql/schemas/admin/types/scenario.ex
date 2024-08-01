defmodule GraphQL.EtheloApi.AdminSchema.Scenario do
  @moduledoc """
  Base access to decisions
  """
  use DocsComposer, module: Engine.Scenarios.Docs.Scenario

  use Absinthe.Schema.Notation
  alias GraphQL.EtheloApi.Resolvers.Scenario, as: ScenarioResolver
  alias GraphQL.EtheloApi.Resolvers.ScenarioStats, as: ScenarioStatsResolver

  object :scenario, description: @doc_map.strings.scenario do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :status, non_null(:string), description: @doc_map.strings.status
    field :json_stats, non_null(:string), description: @doc_map.strings.status
    field :collective_identity, non_null(:float), description: @doc_map.strings.collective_identity
    field :tipping_point, non_null(:float), description: @doc_map.strings.tipping_point
    field :minimize, non_null(:boolean), description: @doc_map.strings.minimize
    field :global, non_null(:boolean), description: @doc_map.strings.global
    field :inserted_at, non_null(:datetime), description: @doc_map.strings.inserted_at
    field :updated_at, non_null(:datetime), description: @doc_map.strings.updated_at
    field :options, list_of(:option), resolve: &ScenarioResolver.batch_load_options/3
    field :stats, :scenario_stats do resolve &ScenarioStatsResolver.get_scenario_stats/3 end
    field :displays, list_of(:scenario_display) do
      arg :id, :id, description: "Filter by ScenarioDisplay id"
      arg :is_constraint, :id, description: "Filter for constraints"
      resolve &ScenarioResolver.batch_load_scenario_displays/3
    end
  end

  object :scenario_list do
    field :scenarios, list_of(:scenario) do
      arg :id, :id, description: "Filter by Scenario id"
      arg :status, :string, description: "Filter by Scenario status"
      arg :global, :boolean, description: "Filter by Scenario global flag"
      arg :rank, :integer, description: "Filter by Scenario rank"
      arg :count, :integer, description: "Number to return (defaults to 1)"
    resolve &ScenarioResolver.list/3
    end
  end

end
