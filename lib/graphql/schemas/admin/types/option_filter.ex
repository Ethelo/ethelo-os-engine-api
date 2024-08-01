defmodule GraphQL.EtheloApi.AdminSchema.OptionFilter do
  @moduledoc """
  Base access to OptionFilters
  """
  use DocsComposer, module: EtheloApi.Structure.Docs.OptionFilter
  alias GraphQL.EtheloApi.Docs.OptionFilter, as: OptionFilterDocs

  use Absinthe.Schema.Notation
  import GraphQL.EtheloApi.ResolveHelper
  import Kronky.Payload, only: [payload_object: 2, build_payload: 2]
  alias GraphQL.EtheloApi.Resolvers.OptionFilter, as: OptionFilterResolver
  alias GraphQL.EtheloApi.Resolvers.OptionCategory, as: OptionCategoryResolver
  alias GraphQL.EtheloApi.Resolvers.OptionDetail, as: OptionDetailResolver

  enum :detail_filter_match_modes, description: @doc_map.strings.match_mode do
    value :equals, as: "equals", description: @doc_map.strings.match_mode_equals
  end

  enum :category_filter_match_modes, description: @doc_map.strings.match_mode do
    value :in_category, as: "in_category", description: @doc_map.strings.match_mode_in_category
    value :not_in_category, as: "not_in_category", description: @doc_map.strings.match_mode_not_in_category
  end

  enum :option_filter_match_modes, description: @doc_map.strings.match_mode do
    value :all_options, as: "all_options", description: @doc_map.strings.match_mode_all_options
    value :in_category, as: "in_category", description: @doc_map.strings.match_mode_in_category
    value :not_in_category, as: "not_in_category", description: @doc_map.strings.match_mode_not_in_category
    value :equals, as: "equals", description: @doc_map.strings.match_mode_equals
    end

  # queries
  object :option_filter do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :title, non_null(:string), description: @doc_map.strings.title
    field :slug, non_null(:string), description: @doc_map.strings.slug
    field :match_value, :string, description: @doc_map.strings.match_value
    field :match_mode, :option_filter_match_modes, description: @doc_map.strings.match_mode
    field :options, list_of(:option),
      description: @doc_map.strings.options,
      resolve: &OptionFilterResolver.batch_load_options/3
    field :option_detail_id, :id
    field :option_detail, :option_detail,
      description: @doc_map.strings.option_detail,
      resolve: &OptionDetailResolver.batch_load_belongs_to/3
    field :option_category_id, :id
    field :option_category, :option_category,
      description: @doc_map.strings.option_category,
      resolve: &OptionCategoryResolver.batch_load_belongs_to/3
    field :inserted_at, non_null(:datetime), description: @doc_map.strings.inserted_at
    field :updated_at, non_null(:datetime), description: @doc_map.strings.updated_at
  end

  object :option_filter_suggestion do
    field :title, non_null(:string), description: @doc_map.strings.title
    field :slug, :string, description: @doc_map.strings.slug
    field :match_value, :string, description: @doc_map.strings.match_value
    field :match_mode, :option_filter_match_modes, description: @doc_map.strings.match_mode
    field :option_detail_id, :id
    field :option_category_id, :id
  end

  object :option_filter_list do
    field :option_filters, list_of(:option_filter) do
      arg :id, :id, description: "Filter by OptionFilter id"
      arg :slug, :string, description: "Filter by OptionFilter slug"
      arg :option_detail_id, :id, description: @doc_map.strings.option_detail_id
      arg :option_category_id, :id, description: @doc_map.strings.option_category_id
      resolve &OptionFilterResolver.list/3
    end
  end

  # mutations
  input_object :create_option_detail_filter_params, description: OptionFilterDocs.create_option_detail_filter() do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :title, non_null(:string), description: @doc_map.strings.title
    field :option_detail_id, non_null(:id), description: @doc_map.strings.option_detail_id
    field :match_mode, non_null(:detail_filter_match_modes), description: @doc_map.strings.match_mode
    field :match_value, :string, description: @doc_map.strings.match_value
    field :slug, :string, description: @doc_map.strings.slug
  end

  input_object :update_option_detail_filter_params, description: OptionFilterDocs.update_option_detail_filter() do
   field :id, non_null(:id), description: @doc_map.strings.id
   field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :title, :string, description: @doc_map.strings.title
    field :option_detail_id, :id, description: @doc_map.strings.option_detail_id
    field :match_mode, :detail_filter_match_modes, description: @doc_map.strings.match_mode
    field :match_value, :string, description: @doc_map.strings.match_value
    field :slug, :string, description: @doc_map.strings.slug
  end

  payload_object(:option_detail_filter_payload, :option_filter)

  input_object :create_option_category_filter_params, description: OptionFilterDocs.create_option_category_filter() do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :title, non_null(:string), description: @doc_map.strings.title
    field :option_category_id, non_null(:id), description: @doc_map.strings.option_category_id
    field :match_mode, non_null(:category_filter_match_modes), description: @doc_map.strings.match_mode
    field :slug, :string, description: @doc_map.strings.slug
  end

  input_object :update_option_category_filter_params, description: OptionFilterDocs.update_option_category_filter() do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :title, :string, description: @doc_map.strings.title
    field :option_category_id, :id, description: @doc_map.strings.option_category_id
    field :match_mode, :category_filter_match_modes, description: @doc_map.strings.match_mode
    field :slug, :string, description: @doc_map.strings.slug
  end

  payload_object(:option_category_filter_payload, :option_filter)

  input_object :delete_option_filter_params, description: OptionFilterDocs.delete() do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :id, non_null(:id), description: @doc_map.strings.id
  end

  # provide an object that can be imported into the base mutations query.
  object :option_filter_mutations do

    field :create_option_detail_filter, type: :option_detail_filter_payload, description: OptionFilterDocs.create_option_detail_filter() do
      arg :input, :create_option_detail_filter_params
      resolve mutation_resolver(&OptionFilterResolver.create/2)
      middleware &build_payload/2
    end

    field :update_option_detail_filter, type: :option_detail_filter_payload, description: OptionFilterDocs.update_option_detail_filter() do
      arg :input, :update_option_detail_filter_params
      resolve mutation_resolver(&OptionFilterResolver.update/2)
      middleware &build_payload/2
    end

   field :create_option_category_filter, type: :option_category_filter_payload, description: OptionFilterDocs.create_option_category_filter() do
      arg :input, :create_option_category_filter_params
      resolve mutation_resolver(&OptionFilterResolver.create/2)
      middleware &build_payload/2
    end

    field :update_option_category_filter, type: :option_category_filter_payload, description: OptionFilterDocs.update_option_category_filter() do
      arg :input, :update_option_category_filter_params
      resolve mutation_resolver(&OptionFilterResolver.update/2)
      middleware &build_payload/2
    end

    field :delete_option_filter, type: :option_detail_filter_payload, description: OptionFilterDocs.delete() do
      arg :input, :delete_option_params
      resolve mutation_resolver(&OptionFilterResolver.delete/2)
      middleware &build_payload/2
    end
  end
end
