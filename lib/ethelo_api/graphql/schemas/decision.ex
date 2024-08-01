defmodule EtheloApi.Graphql.Schemas.Decision do
  @moduledoc """
  Base access to Decisions
  """

  use Absinthe.Schema.Notation
  use DocsComposer, module: EtheloApi.Structure.Docs.Decision

  alias EtheloApi.Graphql.Docs.Decision, as: DecisionDocs
  alias EtheloApi.Graphql.Resolvers.Decision, as: DecisionResolver

  import AbsintheErrorPayload.Payload
  import EtheloApi.Graphql.Middleware

  # queries

  object :solve_files do
    field :decision_json, non_null(:string)
    field :influents_json, non_null(:string)
    field :weights_json, non_null(:string)
    field :config_json, non_null(:string)
    field :hash, non_null(:string)
  end

  object :votes_json do
    field :bin_votes, non_null(:string)
    field :criteria_weights, non_null(:string)
    field :option_category_weights, non_null(:string)
    field :option_category_range_votes, non_null(:string)
  end

  @desc @doc_map.strings.decision
  object :decision_summary do
    @desc @doc_map.strings.copyable
    field :copyable, :boolean

    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.inserted_at
    field :inserted_at, non_null(:datetime)

    @desc @doc_map.strings.internal
    field :internal, :boolean

    @desc @doc_map.strings.keywords
    field :keywords, list_of(:string)

    @desc @doc_map.strings.language
    field :language, :string

    @desc @doc_map.strings.max_users
    field :max_users, :integer

    @desc @doc_map.strings.slug
    field :info, :string

    @desc @doc_map.strings.slug
    field :slug, non_null(:string)

    @desc @doc_map.strings.title
    field :title, non_null(:string)

    @desc @doc_map.strings.updated_at
    field :updated_at, non_null(:datetime)

    @desc "Export decision structure in json format"
    field :export, non_null(:string), do: resolve(&DecisionResolver.export/3)

    field :solve_files, :solve_files do
      arg(:scenario_config_id, non_null(:id))
      arg(:participant_id, :id)
      arg(:use_cache, :boolean)
      resolve(&DecisionResolver.solve_files/3)
    end

    field(:cache_present, non_null(:boolean), resolve: &DecisionResolver.decision_cache_exists/3)

    field :config_cache_present, non_null(:boolean) do
      arg(
        :scenario_config_id,
        non_null(:id),
        description: "The cached ScenarioConfig id to check for"
      )

      resolve(&DecisionResolver.config_cache_exists/3)
    end
  end

  object :decision_list do
    field :decisions, list_of(:decision_summary) do
      @desc "Filter by id"
      arg(:id, :id)

      @desc "Filter by slug"
      arg(:keywords, list_of(:string))

      arg(:slug, :string)
      @desc "Filter by keywords"

      resolve(&DecisionResolver.list/2)
    end
  end

  # mutations

  payload_object(:decision_payload, :decision_summary)

  @desc DecisionDocs.create()
  input_object :create_decision_params do
    @desc @doc_map.strings.copyable
    field :copyable, :boolean

    @desc @doc_map.strings.info
    field :info, :string

    @desc @doc_map.strings.internal
    field :internal, :boolean

    @desc @doc_map.strings.keywords
    field :keywords, list_of(:string)

    @desc @doc_map.strings.language
    field :language, :string

    @desc @doc_map.strings.max_users
    field :max_users, :integer

    @desc @doc_map.strings.slug
    field :slug, :string

    @desc @doc_map.strings.title
    field :title, non_null(:string)
  end

  input_object :import_decision_params, description: DecisionDocs.import() do
    @desc "Json file with Decision structure"
    field :json_data, non_null(:string)

    @desc @doc_map.strings.info
    field :info, :string

    @desc @doc_map.strings.keywords
    field :keywords, list_of(:string)

    @desc @doc_map.strings.language
    field :language, :string

    @desc @doc_map.strings.slug
    field :slug, non_null(:string)

    @desc @doc_map.strings.title
    field :title, non_null(:string)
  end

  input_object :copy_decision_params do
    @desc @doc_map.strings.id
    field :decision_id, non_null(:id)

    @desc @doc_map.strings.info
    field :info, :string

    @desc @doc_map.strings.keywords
    field :keywords, list_of(:string)

    @desc @doc_map.strings.language
    field :language, :string

    @desc @doc_map.strings.slug
    field :slug, non_null(:string)

    @desc @doc_map.strings.title
    field :title, non_null(:string)
  end

  @desc DecisionDocs.update()
  input_object :update_decision_params do
    @desc @doc_map.strings.copyable
    field :copyable, :boolean

    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.info
    field :info, :string

    @desc @doc_map.strings.internal
    field :internal, :boolean

    @desc @doc_map.strings.keywords
    field :keywords, list_of(:string)

    @desc @doc_map.strings.language
    field :language, :string

    @desc @doc_map.strings.max_users
    field :max_users, :integer

    @desc @doc_map.strings.slug
    field :slug, :string

    @desc @doc_map.strings.title
    field :title, :string
  end

  input_object :decision_id_params do
    @desc @doc_map.strings.id
    field :id, non_null(:id)
  end

  object :decision_mutations do
    @desc DecisionDocs.create()
    field :create_decision, type: :decision_payload do
      arg(:input, :create_decision_params)
      resolve(&DecisionResolver.create/2)
      middleware(&build_payload/2)
    end

    #  @desc DecisionDocs.copy()
    field :copy_decision, type: :decision_payload do
      arg(:input, :copy_decision_params)
      middleware(&preload_decision/2)
      resolve(&DecisionResolver.copy/2)
      middleware(&build_payload/2)
    end

    @desc DecisionDocs.create()
    field :import_decision, type: :decision_payload do
      arg(:input, :import_decision_params)
      resolve(&DecisionResolver.import/2)
      middleware(&build_payload/2)
    end

    @desc DecisionDocs.update()
    field :update_decision, type: :decision_payload do
      arg(:input, :update_decision_params)
      resolve(&DecisionResolver.update/2)
      middleware(&build_payload/2)
    end

    @desc "Update the Decision cache"
    field :cache_decision, type: :decision_payload do
      arg(:input, :decision_id_params)
      resolve(&DecisionResolver.update_cache/2)
      middleware(&build_payload/2)
    end

    @desc DecisionDocs.delete()
    field :delete_decision, type: :decision_payload do
      arg(:input, :decision_id_params)
      resolve(&DecisionResolver.delete/2)
      middleware(&build_payload/2)
    end
  end
end
