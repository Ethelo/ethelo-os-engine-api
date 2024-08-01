defmodule GraphQL.EtheloApi.AdminSchema.ScenarioConfig do
  @moduledoc """
  Base access to scenario_configs
  """
  use DocsComposer, module: Engine.Scenarios.Docs.ScenarioConfig
  alias GraphQL.EtheloApi.Docs.ScenarioConfig, as: ScenarioConfigDocs

  use Absinthe.Schema.Notation
  import GraphQL.EtheloApi.ResolveHelper
  import Kronky.Payload, only: [payload_object: 2, build_payload: 2]
  alias GraphQL.EtheloApi.Resolvers.ScenarioConfig, as: ScenarioConfigResolver
  # queries

  object :scenario_config do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :title, non_null(:string), description: @doc_map.strings.title
    field :slug, non_null(:string), description: @doc_map.strings.slug
    field :bins, non_null(:integer), description: @doc_map.strings.bins
    field :normalize_satisfaction, non_null(:boolean),
      description: @doc_map.strings.normalize_satisfaction
    field :normalize_influents, non_null(:boolean),
      description: @doc_map.strings.normalize_influents
    field :override_criteria_weights, non_null(:boolean)
    field :override_option_category_weights, non_null(:boolean)
    field :skip_solver, non_null(:boolean), description: @doc_map.strings.skip_solver
    field :support_only, non_null(:boolean), description: @doc_map.strings.support_only
    field :per_option_satisfaction, non_null(:boolean), description: @doc_map.strings.per_option_satisfaction
    field :max_scenarios, non_null(:integer), description: @doc_map.strings.max_scenarios
    field :solve_interval, non_null(:integer), description: @doc_map.strings.solve_interval
    field :ttl, non_null(:integer), description: @doc_map.strings.ttl
    field :engine_timeout, non_null(:integer), description: @doc_map.strings.engine_timeout
    field :collective_identity, non_null(:float),
      description: @doc_map.strings.collective_identity,
      resolve: fn(parent, _, _) ->
        parent |> Map.get(:ci) |> Decimal.to_float() |> success()
      end
    field :tipping_point, non_null(:float), description: @doc_map.strings.tipping_point,
      resolve: fn(parent, _, _) ->
        parent |> Map.get(:tipping_point) |> Decimal.to_float() |> success()
      end
    field :enabled, non_null(:boolean), description: @doc_map.strings.enabled
    field :inserted_at, non_null(:datetime), description: @doc_map.strings.inserted_at
    field :updated_at, non_null(:datetime), description: @doc_map.strings.updated_at

    field :quadratic, non_null(:boolean), description: @doc_map.strings.quadratic
    field :quad_user_seeds, :integer, description: @doc_map.strings.quad_user_seeds
    field :quad_total_available, :integer, description: @doc_map.strings.quad_total_available
    field :quad_cutoff, :integer, description: @doc_map.strings.quad_cutoff
    field :quad_max_allocation, :integer, description: @doc_map.strings.quad_max_allocation
    field :quad_round_to, :integer, description: @doc_map.strings.quad_round_to

    field :quad_seed_percent, :float,
      description: @doc_map.strings.quad_seed_percent,
      resolve: fn(parent, _, _) ->
        parent |> Map.get(:quad_seed_percent) |> success()
      end
    field :quad_vote_percent, :float,
      description: @doc_map.strings.quad_vote_percent,
      resolve: fn(parent, _, _) ->
        parent |> Map.get(:quad_vote_percent) |> success()
      end

  end

  object :scenario_config_list do
    field :scenario_configs, list_of(:scenario_config) do
      arg :id, :id, description: "Filter by ScenarioConfig id"
      arg :slug, :string, description: "Filter by ScenarioConfig slug"
      arg :enabled, :boolean, description: "Filter by ScenarioConfig enabled"
      resolve &ScenarioConfigResolver.list/3
    end
  end

  input_object :scenario_config_params do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :slug, :string, description: @doc_map.strings.slug
    field :bins, :integer, description: @doc_map.strings.bins
    field :normalize_influents, :boolean, description: @doc_map.strings.normalize_influents
    field :normalize_satisfaction, :boolean, description: @doc_map.strings.normalize_satisfaction
    field :skip_solver, :boolean, description: @doc_map.strings.skip_solver
    field :support_only, :boolean, description: @doc_map.strings.support_only
    field :quadratic, :boolean, description: @doc_map.strings.quadratic
    field :per_option_satisfaction, :boolean, description: @doc_map.strings.per_option_satisfaction
    field :max_scenarios, :integer, description: @doc_map.strings.max_scenarios
    field :collective_identity, :float, description: @doc_map.strings.collective_identity
    field :tipping_point, :float, description: @doc_map.strings.tipping_point
    field :solve_interval, :integer, description: @doc_map.strings.solve_interval
    field :ttl, :integer, description: @doc_map.strings.ttl
    field :engine_timeout, :integer, description: @doc_map.strings.engine_timeout
    field :enabled, :boolean, description: @doc_map.strings.enabled
    field :quad_user_seeds, :integer, description: @doc_map.strings.quad_user_seeds
    field :quad_total_available, :integer, description: @doc_map.strings.quad_total_available
    field :quad_cutoff, :integer, description: @doc_map.strings.quad_cutoff
    field :quad_max_allocation, :integer, description: @doc_map.strings.quad_max_allocation
    field :quad_round_to, :integer, description: @doc_map.strings.quad_round_to
    field :quad_seed_percent, :float, description: @doc_map.strings.quad_seed_percent
    field :quad_vote_percent, :float, description: @doc_map.strings.quad_vote_percent

  end

  # mutations
  input_object :create_scenario_config_params, description: ScenarioConfigDocs.create() do
    field :title, non_null(:string), description: @doc_map.strings.title
    import_fields :scenario_config_params
  end

  input_object :update_scenario_config_params, description: ScenarioConfigDocs.update() do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :title, :string, description: @doc_map.strings.title
    import_fields :scenario_config_params
    end

  input_object :update_scenario_config_cache_params, description: "Update the scenario configuration cache" do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :id, non_null(:id), description: @doc_map.strings.id
  end

  input_object :invalidate_scenario_config_cache_params, description: "Invalidate the scenario configuration cache" do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :id, non_null(:id), description: @doc_map.strings.id
  end

  input_object :delete_scenario_config_params, description: ScenarioConfigDocs.delete() do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :id, non_null(:id), description: @doc_map.strings.id
  end

  payload_object(:scenario_config_payload, :scenario_config)

  # provide an object that can be imported into the base mutations query.
  object :scenario_config_mutations do

    field :create_scenario_config, type: :scenario_config_payload, description: ScenarioConfigDocs.create() do
      arg :input, :create_scenario_config_params
      resolve mutation_resolver(&ScenarioConfigResolver.create/2)
      middleware &build_payload/2
    end

    field :update_scenario_config, type: :scenario_config_payload, description: ScenarioConfigDocs.update() do
      arg :input, :update_scenario_config_params
      resolve mutation_resolver(&ScenarioConfigResolver.update/2)
      middleware &build_payload/2
    end

    field :cache_scenario_config, type: :scenario_config_payload, description: "Update the scenario configuration cache" do
      arg :input, :update_scenario_config_cache_params
      resolve mutation_resolver(&ScenarioConfigResolver.cache/2)
      middleware &build_payload/2
    end

    field :delete_scenario_config, type: :scenario_config_payload, description: ScenarioConfigDocs.delete() do
      arg :input, :delete_scenario_config_params
      resolve mutation_resolver(&ScenarioConfigResolver.delete/2)
      middleware &build_payload/2
    end
  end

end
