defmodule EtheloApi.Graphql.Schemas.ScenarioConfig do
  @moduledoc """
  Base access to ScenarioConfigs
  """
  use Absinthe.Schema.Notation
  use DocsComposer, module: EtheloApi.Structure.Docs.ScenarioConfig

  import AbsintheErrorPayload.Payload
  import EtheloApi.Graphql.Middleware
  import EtheloApi.Helpers.ValidationHelper

  alias EtheloApi.Graphql.Docs.ScenarioConfig, as: ScenarioConfigDocs
  alias EtheloApi.Graphql.Resolvers.ScenarioConfig, as: ScenarioConfigResolver
  alias EtheloApi.Invocation

  # queries

  object :scenario_config do
    @desc @doc_map.strings.bins
    field :bins, non_null(:integer)

    field :cache_present, non_null(:boolean),
      resolve: fn parent, _, _ ->
        {:ok, Invocation.scenario_config_cache_exists(parent.id, parent.decision_id)}
      end

    @desc @doc_map.strings.collective_identity
    field :collective_identity, non_null(:float),
      resolve: fn parent, _, _ ->
        parent |> Map.get(:ci) |> Decimal.to_float() |> success()
      end

    @desc @doc_map.strings.enabled
    field :enabled, non_null(:boolean)

    @desc @doc_map.strings.engine_timeout
    field :engine_timeout, non_null(:integer)

    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.inserted_at
    field :inserted_at, non_null(:datetime)

    @desc @doc_map.strings.max_scenarios
    field :max_scenarios, non_null(:integer)

    @desc @doc_map.strings.normalize_influents
    field :normalize_influents, non_null(:boolean)

    @desc @doc_map.strings.normalize_satisfaction
    field :normalize_satisfaction, non_null(:boolean)

    @desc @doc_map.strings.per_option_satisfaction
    field :per_option_satisfaction, non_null(:boolean)

    @desc @doc_map.strings.quad_cutoff
    field :quad_cutoff, :integer

    @desc @doc_map.strings.quad_max_allocation
    field :quad_max_allocation, :integer

    @desc @doc_map.strings.quad_round_to
    field :quad_round_to, :integer

    @desc @doc_map.strings.quad_seed_percent
    field :quad_seed_percent, :float,
      resolve: fn parent, _, _ ->
        parent |> Map.get(:quad_seed_percent) |> success()
      end

    @desc @doc_map.strings.quad_total_available
    field :quad_total_available, :integer

    @desc @doc_map.strings.quad_user_seeds
    field :quad_user_seeds, :integer

    @desc @doc_map.strings.quad_vote_percent
    field :quad_vote_percent, :float,
      resolve: fn parent, _, _ ->
        parent |> Map.get(:quad_vote_percent) |> success()
      end

    @desc @doc_map.strings.quadratic
    field :quadratic, non_null(:boolean)

    @desc @doc_map.strings.skip_solver
    field :skip_solver, non_null(:boolean)

    @desc @doc_map.strings.slug
    field :slug, :string

    @desc @doc_map.strings.solve_interval
    field :solve_interval, non_null(:integer)

    @desc @doc_map.strings.support_only
    field :support_only, :boolean

    @desc @doc_map.strings.tipping_point
    field :tipping_point, non_null(:float),
      resolve: fn parent, _, _ ->
        parent |> Map.get(:tipping_point) |> Decimal.to_float() |> success()
      end

    @desc @doc_map.strings.title
    field :title, :string

    @desc @doc_map.strings.ttl
    field :ttl, non_null(:integer)

    @desc @doc_map.strings.updated_at
    field :updated_at, non_null(:datetime)
  end

  object :scenario_config_list do
    field :scenario_configs, list_of(:scenario_config) do
      @desc "Filter by ScenarioConfig enabled"
      arg(:enabled, :boolean)

      @desc "Filter by ScenarioConfig id"
      arg(:id, :id)

      @desc "Filter by ScenarioConfig slug"
      arg(:slug, :string)

      resolve(&ScenarioConfigResolver.list/3)
    end
  end

  # mutations

  payload_object(:scenario_config_payload, :scenario_config)

  input_object :scenario_config_params do
    @desc @doc_map.strings.bins
    field :bins, :integer

    @desc @doc_map.strings.collective_identity
    field :collective_identity, :float

    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc @doc_map.strings.enabled
    field :enabled, :boolean

    @desc @doc_map.strings.engine_timeout
    field :engine_timeout, :integer

    @desc @doc_map.strings.max_scenarios
    field :max_scenarios, :integer

    @desc @doc_map.strings.normalize_influents
    field :normalize_influents, :boolean

    @desc @doc_map.strings.normalize_satisfaction
    field :normalize_satisfaction, :boolean

    @desc @doc_map.strings.per_option_satisfaction
    field :per_option_satisfaction, :boolean

    @desc @doc_map.strings.quad_cutoff
    field :quad_cutoff, :integer

    @desc @doc_map.strings.quad_max_allocation
    field :quad_max_allocation, :integer

    @desc @doc_map.strings.quad_round_to
    field :quad_round_to, :integer

    @desc @doc_map.strings.quad_seed_percent
    field :quad_seed_percent, :float

    @desc @doc_map.strings.quad_total_available
    field :quad_total_available, :integer

    @desc @doc_map.strings.quad_user_seeds
    field :quad_user_seeds, :integer

    @desc @doc_map.strings.quad_vote_percent
    field :quad_vote_percent, :float

    @desc @doc_map.strings.quadratic
    field :quadratic, :boolean

    @desc @doc_map.strings.skip_solver
    field :skip_solver, :boolean

    @desc @doc_map.strings.slug
    field :slug, :string

    @desc @doc_map.strings.solve_interval
    field :solve_interval, :integer

    @desc @doc_map.strings.support_only
    field :support_only, :boolean

    @desc @doc_map.strings.tipping_point
    field :tipping_point, :float

    @desc @doc_map.strings.ttl
    field :ttl, :integer
  end

  @desc ScenarioConfigDocs.create()
  input_object :create_scenario_config_params do
    @desc @doc_map.strings.title
    field :title, non_null(:string)

    import_fields(:scenario_config_params)
  end

  @desc ScenarioConfigDocs.update()
  input_object :update_scenario_config_params do
    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.title
    field :title, :string

    import_fields(:scenario_config_params)
  end

  @desc "match a ScenarioConfig use DecisionId and Id "
  input_object :scenario_config_id_params do
    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc @doc_map.strings.id
    field :id, non_null(:id)
  end

  object :scenario_config_mutations do
    @desc ScenarioConfigDocs.create()
    field :create_scenario_config, type: :scenario_config_payload do
      arg(:input, :create_scenario_config_params)

      middleware(&preload_decision/2)
      resolve(&ScenarioConfigResolver.create/2)
      middleware(&build_payload/2)
    end

    @desc ScenarioConfigDocs.update()
    field :update_scenario_config, type: :scenario_config_payload do
      arg(:input, :update_scenario_config_params)
      middleware(&preload_decision/2)
      resolve(&ScenarioConfigResolver.update/2)
      middleware(&build_payload/2)
    end

    @desc "Update the ScenarioConfig cache"
    field :cache_scenario_config, type: :scenario_config_payload do
      arg(:input, :scenario_config_id_params)
      middleware(&preload_decision/2)
      resolve(&ScenarioConfigResolver.update_cache/2)
      middleware(&build_payload/2)
    end

    @desc ScenarioConfigDocs.delete()
    field :delete_scenario_config, type: :scenario_config_payload do
      arg(:input, :scenario_config_id_params)
      middleware(&preload_decision/2)
      resolve(&ScenarioConfigResolver.delete/2)
      middleware(&build_payload/2)
    end
  end
end
