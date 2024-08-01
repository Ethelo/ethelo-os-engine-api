defmodule EtheloApi.Graphql.Schemas.ScenarioSet do
  @moduledoc """
  Base access to ScenarioSets
  """

  use Absinthe.Schema.Notation
  use DocsComposer, module: EtheloApi.Scenarios.Docs.ScenarioSet

  alias EtheloApi.Graphql.Docs.ScenarioSet, as: ScenarioSetDocs
  alias EtheloApi.Graphql.Resolvers.ScenarioSet, as: ScenarioSetResolver
  alias EtheloApi.Graphql.Resolvers.Scenario, as: ScenarioResolver

  import AbsintheErrorPayload.Payload
  import Absinthe.Resolution.Helpers, only: [dataloader: 2]
  import EtheloApi.Graphql.Middleware

  @desc @doc_map.strings.scenario_set
  object :scenario_set do
    @desc @doc_map.strings.cached_decision
    field :cached_decision, non_null(:boolean)

    @desc "The number of scenarios in the ScenarioSet"
    field :count, non_null(:integer) do
      @desc "Filter by Scenario global flag"
      arg(:global, :boolean)

      @desc "Filter by Scenario id"
      arg(:id, :id)

      @desc "Filter by Scenario rank"
      arg(:rank, :integer)

      @desc "Filter by Scenario status"
      arg(:status, :string)

      resolve(&ScenarioResolver.count/3)
    end

    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc @doc_map.strings.engine_end
    field :engine_end, :datetime

    @desc @doc_map.strings.engine_start
    field :engine_start, :datetime

    @desc @doc_map.strings.error
    field :error, :string

    @desc @doc_map.strings.hash
    field :hash, :string

    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.inserted_at
    field :inserted_at, non_null(:datetime)

    @desc @doc_map.strings.status
    field :json_stats, non_null(:string)

    @desc @doc_map.strings.participant_id
    field :participant_id, :id

    @desc @doc_map.strings.scenario_config_id
    field :participant, :participant, resolve: dataloader(:repo, :participant)

    @desc @doc_map.strings.scenario_config_id
    field :scenario_config_id, :id

    @desc @doc_map.strings.scenario_config_id
    field :scenario_config, :scenario_config, resolve: dataloader(:repo, :scenario_config)

    field :solve_dump, :solve_dump, resolve: dataloader(:repo, :solve_dump)

    @desc @doc_map.strings.status
    field :status, non_null(:string)

    @desc @doc_map.strings.updated_at
    field :updated_at, non_null(:datetime)

    import_fields(:scenario_list)
    import_fields(:scenario_stats_list)
  end

  object :scenario_set_list do
    field :scenario_sets, list_of(:scenario_set) do
      @desc "Filter by cached_decision flag"
      arg(:cached_decision, :boolean)

      @desc "Filter by latest ScenarioSet"
      arg(:latest, :boolean)

      @desc "Filter by id"
      arg(:id, :id)

      @desc "Filter by Participant id"
      arg(:participant_id, :id)

      @desc "Filter by ScenarioConfig id"
      arg(:scenario_config_id, :id)

      @desc "Filter by status"
      arg(:status, :string)
      resolve(&ScenarioSetResolver.list/3)
    end
  end

  # mutations

  payload_object(:scenario_set_payload, :scenario_set)
  payload_object(:integer_payload, :integer)

  @desc ScenarioSetDocs.solve()
  input_object :solve_decision_params do
    @desc "Run the solver in the background (and return from this request immediately)"
    field :async, :boolean

    @desc "Use cached Decision andScenarioConfig"
    field :cached, :boolean

    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc "Force run the solver even if there are no changes since the last invocation"
    field :force, :boolean

    @desc @doc_map.strings.participant_id
    field :participant_id, :id

    @desc "Save dump files for this solve run"
    field :save_dump, :boolean

    @desc @doc_map.strings.scenario_config_id
    field :scenario_config_id, non_null(:id)
  end

  object :scenario_set_mutations do
    @desc ScenarioSetDocs.solve()
    field :solve_decision, type: :scenario_set_payload do
      arg(:input, :solve_decision_params)
      middleware(&preload_decision/2)
      resolve(&ScenarioSetResolver.solve/2)
      middleware(&build_payload/2)
    end
  end
end
