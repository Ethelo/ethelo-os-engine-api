defmodule GraphQL.EtheloApi.AdminSchema.Option do
  @moduledoc """
  Base access to Options
  """
  use DocsComposer, module: EtheloApi.Structure.Docs.Option
  alias GraphQL.EtheloApi.Docs.Option, as: OptionDocs
  @option_filter_strings EtheloApi.Structure.Docs.OptionFilter.strings()


  use Absinthe.Schema.Notation
  import GraphQL.EtheloApi.ResolveHelper
  import Kronky.Payload, only: [payload_object: 2, build_payload: 2]
  alias GraphQL.EtheloApi.Resolvers.Option, as: OptionResolver
  alias GraphQL.EtheloApi.Resolvers.OptionCategory, as: OptionCategoryResolver


  # queries

  object :option, description: @doc_map.strings.option do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :title, non_null(:string), description: @doc_map.strings.title
    field :results_title, :string, description: @doc_map.strings.results_title
    field :slug, non_null(:string), description: @doc_map.strings.slug
    field :info, :string, description: @doc_map.strings.info
    field :determinative, non_null(:boolean), description: @doc_map.strings.determinative
    field :enabled, non_null(:boolean), description: @doc_map.strings.enabled
    field :deleted, non_null(:boolean), description: @doc_map.strings.deleted
    field :sort, :integer, description: @doc_map.strings.sort
    field :inserted_at, non_null(:datetime), description: @doc_map.strings.inserted_at
    field :updated_at, non_null(:datetime), description: @doc_map.strings.updated_at
    field :option_category, non_null(:option_category),
      resolve: &OptionCategoryResolver.batch_load_belongs_to/3
    field :detail_values, list_of(:option_detail_value) do
      resolve &OptionResolver.batch_detail_values/3
    end
  end

  object :option_list do
    field :options, list_of(:option) do
      arg :id, :id, description: "Filter by Option id"
      arg :slug, :string, description: "Filter by Option slug"
      arg :option_filter_id, :id, description: @option_filter_strings.option_filter
      arg :option_category_id, :id, description: @doc_map.strings.option_category_id
      arg :enabled, :boolean, description: @doc_map.strings.enabled
      arg :deleted, :boolean, description: "Filter by deleted flag"
    resolve &OptionResolver.list/3
    end
  end

  input_object :option_params do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :slug, :string, description: @doc_map.strings.slug
    field :info, :string, description: @doc_map.strings.info
    field :results_title, :string, description: @doc_map.strings.results_title
    field :determinative, :boolean, description: @doc_map.strings.determinative
    field :enabled, :boolean, description: @doc_map.strings.enabled
    field :deleted, :boolean, description: @doc_map.strings.deleted
    field :option_category_id, :id, description: @doc_map.strings.option_category_id
    field :sort, :integer, description: @doc_map.strings.sort
  end

  # input_object :inline_detail_value do
  #   field :option_detail_id, :id, description: @doc_map.strings.option_detail_id
  #   field :value, :string
  # end

  # mutations
  input_object :create_option_params, description: OptionDocs.create() do
    field :title, non_null(:string), description: @doc_map.strings.title
    import_fields :option_params
  end

  input_object :update_option_params, description: OptionDocs.update() do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :title, :string, description: @doc_map.strings.title
    import_fields :option_params
    #field :detail_values, list_of(:inline_detail_value)
  end

  input_object :delete_option_params, description: OptionDocs.delete() do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :id, non_null(:id), description: @doc_map.strings.id
  end

  payload_object(:option_payload, :option)

  # provide an object that can be imported into the base mutations query.
  object :option_mutations do
    field :create_option, type: :option_payload, description: OptionDocs.create() do
      arg :input, :create_option_params
      resolve mutation_resolver(&OptionResolver.create/2)
      middleware &build_payload/2
    end

    field :update_option, type: :option_payload, description: OptionDocs.update() do
      arg :input, :update_option_params
      resolve mutation_resolver(&OptionResolver.update/2)
      middleware &build_payload/2
    end

    field :delete_option, type: :option_payload, description: OptionDocs.delete() do
      arg :input, :delete_option_params
      resolve mutation_resolver(&OptionResolver.delete/2)
      middleware &build_payload/2
    end
  end
end
