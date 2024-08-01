defmodule GraphQL.EtheloApi.AdminSchema.Decision do
  @moduledoc """
  Base access to decisions
  """
  use DocsComposer, module: EtheloApi.Structure.Docs.Decision
  alias GraphQL.EtheloApi.Docs.Decision, as: DecisionDocs

  use Absinthe.Schema.Notation
  import GraphQL.EtheloApi.ResolveHelper
  import Kronky.Payload, only: [payload_object: 2, build_payload: 2]
  alias GraphQL.EtheloApi.Resolvers.Decision, as: DecisionResolver

  # queries
  object :histogram_element do
    field :datetime, non_null(:datetime)
    field :count, non_null(:integer)
  end

  object :decision_json do
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

  object :decision_summary, description: @doc_map.strings.decision do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :title, non_null(:string), description: @doc_map.strings.title
    field :slug, non_null(:string), description: @doc_map.strings.slug
    field :info, :string, description: @doc_map.strings.slug
    field :copyable, :boolean, description: @doc_map.strings.copyable
    field :internal, :boolean, description: @doc_map.strings.internal
    field :language, :string, description: @doc_map.strings.language
    field :keywords, list_of(:string), description: @doc_map.strings.keywords
    field :max_users, :integer, description: @doc_map.strings.max_users
    field :export, non_null(:string) do
      arg :pretty, :boolean
      resolve &DecisionResolver.export/3
    end
    field :json_dump, :decision_json do
      arg :scenario_config_id, non_null(:id)
      arg :participant_id, :id
      arg :cached, :boolean
      resolve &DecisionResolver.dump_json/3
    end

    field(:cache_present, non_null(:boolean), resolve: &DecisionResolver.decision_cache_exists/3)

    field :config_cache_present, non_null(:boolean) do
      arg(
        :scenario_config_id,
        non_null(:id),
        description: "The cached scenario config id to check for"
      )

      resolve(&DecisionResolver.config_cache_exists/3)
    end

    field :votes_histogram, list_of(:histogram_element) do
      arg :type, :string, description: "The type of votes histogram to retrieve: 'year', 'month', 'week', 'day'"
      resolve &DecisionResolver.votes_histogram/3
    end
    field :inserted_at, non_null(:datetime), description: @doc_map.strings.inserted_at
    field :updated_at, non_null(:datetime), description: @doc_map.strings.updated_at
  end

  object :decision_list do
    field :decisions, list_of(:decision_summary) do
      arg :id, :id, description: "Filter by id"
      arg :slug, :string, description: "Filter by slug"
      arg :keywords, list_of(:string), description: "Filter by keywords"
      resolve &DecisionResolver.list/2
    end
  end

  # mutations
  input_object :create_decision_params, description: DecisionDocs.create() do
    field :title, non_null(:string), description: @doc_map.strings.title
    field :info, :string, description: @doc_map.strings.info
    field :slug, :string, description: @doc_map.strings.slug
    field :copyable, :boolean, description: @doc_map.strings.copyable
    field :internal, :boolean, description: @doc_map.strings.internal
    field :language, :string, description: @doc_map.strings.language
    field :keywords, list_of(:string), description: @doc_map.strings.keywords
    field :max_users, :integer, description: @doc_map.strings.max_users
  end

  input_object :import_decision_params, description: DecisionDocs.import() do
    field :export, non_null(:string), description: "The json export to import as a new decision"
    field :title, :string, description: @doc_map.strings.title
    field :info, :string, description: @doc_map.strings.info
    field :slug, :string, description: @doc_map.strings.slug
  end

  input_object :update_decision_params, description: DecisionDocs.update() do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :title, :string, description: @doc_map.strings.title
    field :info, :string, description: @doc_map.strings.info
    field :slug, :string, description: @doc_map.strings.slug
    field :copyable, :boolean, description: @doc_map.strings.copyable
    field :internal, :boolean, description: @doc_map.strings.internal
    field :language, :string, description: @doc_map.strings.language
    field :keywords, list_of(:string), description: @doc_map.strings.keywords
    field :max_users, :integer, description: @doc_map.strings.max_users
  end

  input_object :update_decision_cache_params, description: "Update the decision cache" do
    field :id, non_null(:id), description: @doc_map.strings.id
  end

  input_object :invalidate_decision_cache_params, description: "Invalidate the decision cache" do
    field :id, non_null(:id), description: @doc_map.strings.id
  end

  input_object :copy_decision_params, description: DecisionDocs.copy() do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :title, :string, description: @doc_map.strings.title
    field :info, :string, description: @doc_map.strings.info
    field :slug, :string, description: @doc_map.strings.slug
    field :max_users, :integer, description: @doc_map.strings.max_users
    field :language, :string, description: @doc_map.strings.language
    field :keywords, list_of(:string), description: @doc_map.strings.keywords
  end

  input_object :delete_decision_params, description: DecisionDocs.delete() do
    field :id, non_null(:id), description: @doc_map.strings.id
  end

  payload_object(:decision_payload, :decision_summary)
  payload_object(:boolean_payload, :boolean)

  # provide an object that can be imported into the base mutations query.
  object :decision_mutations do

    field :create_decision, type: :decision_payload, description: DecisionDocs.create() do
      arg :input, :create_decision_params
      resolve &DecisionResolver.create/2
      middleware &build_payload/2
    end

    field :import_decision, type: :decision_payload, description: DecisionDocs.create() do
      arg :input, :import_decision_params
      resolve &DecisionResolver.import/2
      middleware &build_payload/2
    end

    field :update_decision, type: :decision_payload, description: DecisionDocs.update() do
      arg :input, :update_decision_params
      resolve mutation_resolver(&DecisionResolver.update/2)
      middleware &build_payload/2
    end

    field :cache_decision,
      type: :decision_payload,
      description: "Update the decision cache" do
      arg(:input, :update_decision_cache_params)
      resolve(mutation_resolver(&DecisionResolver.cache/2))
      middleware(&build_payload/2)
    end

    field :copy_decision, type: :decision_payload, description: DecisionDocs.copy() do
      arg :input, :copy_decision_params
      resolve mutation_resolver(&DecisionResolver.copy/2)
      middleware &build_payload/2
    end

    field :delete_decision, type: :decision_payload, description: DecisionDocs.delete() do
      arg :input, :delete_decision_params
      resolve mutation_resolver(&DecisionResolver.delete/2)
      middleware &build_payload/2
    end
  end

end
