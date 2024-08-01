defmodule GraphQL.EtheloApi.AdminSchema.ScenarioSet do
  @moduledoc """
  Base access to decisions
  """
  use DocsComposer, module: Engine.Scenarios.Docs.ScenarioSet
  alias GraphQL.EtheloApi.Docs.ScenarioSet, as: ScenarioSetDocs

  use Absinthe.Schema.Notation
  import GraphQL.EtheloApi.ResolveHelper
  import Kronky.Payload, only: [payload_object: 2, build_payload: 2]
  alias GraphQL.EtheloApi.Resolvers.ScenarioSet, as: ScenarioSetResolver
  alias GraphQL.EtheloApi.Resolvers.Scenario, as: ScenarioResolver

  import_types GraphQL.EtheloApi.AdminSchema.Scenario
  import_types GraphQL.EtheloApi.AdminSchema.ScenarioStats

  object :scenario_set, description: @doc_map.strings.scenario_set do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :scenario_config_id, :id, description: @doc_map.strings.scenario_config_id
    field :participant_id, :id, description: @doc_map.strings.participant_id
    field :status, non_null(:string), description: @doc_map.strings.status
    field :json_stats, non_null(:string), description: @doc_map.strings.status
    field :error, :string, description: @doc_map.strings.error
    field :cached_decision, non_null(:boolean), description: @doc_map.strings.cached_decision
    field :count, non_null(:integer), description: "The number of scenarios in the ScenarioSet" do
      arg :id, :id, description: "Filter by Scenario id"
      arg :status, :string, description: "Filter by Scenario status"
      arg :global, :boolean, description: "Filter by Scenario global flag"
      arg :rank, :integer, description: "Filter by Scenario rank"
      resolve &ScenarioResolver.count/3
      end
    field :inserted_at, non_null(:datetime), description: @doc_map.strings.inserted_at
    field :updated_at, non_null(:datetime), description: @doc_map.strings.updated_at
    field :engine_start,:datetime, description: @doc_map.strings.engine_start
    field :engine_end, :datetime, description: @doc_map.strings.engine_end
    field :solve_dump, :solve_dump, resolve: &ScenarioSetResolver.batch_load_solve_dumps/3
    import_fields :scenario_list
    import_fields :scenario_stats_list
  end

  object :scenario_set_list do
    field :scenario_sets, list_of(:scenario_set) do
      arg :id, :id, description: "Filter by ScenarioSet id"
      arg :scenario_config_id, :id, description: "Filter by ScenarioConfig id"
      arg :participant_id, :id, description: "Filter by Participant id"
      arg :status, :string, description: "Filter by ScenarioSet status"
      arg :json_stats, :string, description: "Filter by ScenarioSet status"
      arg :cached_decision, :boolean, description: "Filter by ScenarioSet cached_decision flag"
      arg :latest, :boolean, description: "Return only the latest ScenarioSet"
    resolve &ScenarioSetResolver.list/3
    end
  end

  # mutations
  input_object :solve_decision_params, description: ScenarioSetDocs.create() do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :scenario_config_id, non_null(:id), description: @doc_map.strings.scenario_config_id
    field :participant_id, :id, description: @doc_map.strings.participant_id
    field :cached, :boolean, description: "Use cached decision and scenario configuration"
    field :force, :boolean, description: "Force run the solver even if there are no changes since the last invocation"
    field :async, :boolean, description: "Run the solver in the background (and return from this request immediately)"
    field :save_dump, :boolean, description: "Save dump files for this solve run"
  end

  input_object :purge_expired_params, description: ScenarioSetDocs.create() do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
  end

  payload_object(:scenario_set_payload, :scenario_set)
  payload_object(:integer_payload, :integer)


  # provide an object that can be imported into the base mutations query.
  object :scenario_set_mutations do
    field :solve_decision, type: :scenario_set_payload, description: ScenarioSetDocs.create() do
      arg :input, :solve_decision_params
      resolve mutation_resolver(&ScenarioSetResolver.solve/2)
      middleware &build_payload/2
    end

    field :purge_expired, type: :integer_payload, description: "Purge expired scenario sets" do
      arg :input, :purge_expired_params
      resolve mutation_resolver(&ScenarioSetResolver.purge/2)
      middleware &build_payload/2
    end
  end
end
