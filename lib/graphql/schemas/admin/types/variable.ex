defmodule GraphQL.EtheloApi.AdminSchema.Variable do
  @moduledoc """
  Base access to Variables
  """
  use DocsComposer, module: EtheloApi.Structure.Docs.Variable
  alias GraphQL.EtheloApi.Docs.Variable, as: VariableDocs

  use Absinthe.Schema.Notation
  import GraphQL.EtheloApi.ResolveHelper
  import Kronky.Payload, only: [payload_object: 2, build_payload: 2]
  alias GraphQL.EtheloApi.Resolvers.Variable, as: VariableResolver
  alias GraphQL.EtheloApi.Resolvers.OptionDetail, as: OptionDetailResolver
  alias GraphQL.EtheloApi.Resolvers.OptionFilter, as: OptionFilterResolver

  enum :variable_methods, description: @doc_map.strings.method do
    value :sum_selected, description: @doc_map.strings.method_sum_selected
    value :mean_selected, description: @doc_map.strings.method_mean_selected
    value :sum_all, description: @doc_map.strings.method_sum_all
    value :mean_all, description: @doc_map.strings.method_mean_all
    value :count_selected, description: @doc_map.strings.method_count_selected
    value :count_all, description: @doc_map.strings.method_count_all
  end

  enum :detail_variable_methods, description: @doc_map.strings.method do
    value :sum_selected, description: @doc_map.strings.method_sum_selected
    value :mean_selected, description: @doc_map.strings.method_mean_selected
    value :sum_all, description: @doc_map.strings.method_sum_all
    value :mean_all, description: @doc_map.strings.method_mean_all
  end

  enum :filter_variable_methods, description: @doc_map.strings.method do
    value :count_selected, description: @doc_map.strings.method_count_selected
    value :count_all, description: @doc_map.strings.method_count_all
  end

  # queries
  object :variable do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :title, non_null(:string), description: @doc_map.strings.title
    field :slug, non_null(:string), description: @doc_map.strings.slug
    field :method, non_null(:variable_methods), description: @doc_map.strings.method
    field :option_detail_id, :id
    field :option_detail, :option_detail,
      description: @doc_map.strings.option_detail,
      resolve: &OptionDetailResolver.batch_load_belongs_to/3
    field :option_filter_id, :id
    field :option_filter, :option_filter,
      description: @doc_map.strings.option_filter,
      resolve: &OptionFilterResolver.batch_load_belongs_to/3
    field :calculations_id, :id
    field :calculations, list_of(:calculation),
      description: @doc_map.strings.calculations,
      resolve: &VariableResolver.batch_load_calculations/3
    field :inserted_at, non_null(:datetime), description: @doc_map.strings.inserted_at
    field :updated_at, non_null(:datetime), description: @doc_map.strings.updated_at
  end

  object :variable_suggestion do
    field :title, non_null(:string), description: @doc_map.strings.title
    field :slug, :string, description: @doc_map.strings.slug
    field :method, non_null(:variable_methods), description: @doc_map.strings.method
    field :option_detail_id, :id
    field :option_filter_id, :id
    field :calculations_id, :id
  end

  object :variable_list do
    field :variables, list_of(:variable) do
      arg :id, :id, description: "Filter by Variable id"
      arg :slug, :string, description: "Filter by Variable slug"
      arg :option_detail_id, :id, description: @doc_map.strings.option_detail_id
      arg :option_filter_id, :id, description: @doc_map.strings.option_filter_id
      resolve &VariableResolver.list/3
    end
  end

  object :variable_suggestion_list do
    field :variable_suggestions, list_of(:variable_suggestion),resolve: &VariableResolver.suggested/3
  end

  # mutations
  input_object :create_detail_variable_params, description: VariableDocs.create_detail_variable() do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :title, non_null(:string), description: @doc_map.strings.title
    field :option_detail_id, non_null(:id), description: @doc_map.strings.option_detail_id
    field :method, non_null(:detail_variable_methods), description: @doc_map.strings.method
    field :slug, :string, description: @doc_map.strings.slug
  end

  input_object :update_detail_variable_params, description: VariableDocs.update_detail_variable() do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :title, :string, description: @doc_map.strings.title
    field :option_detail_id, :id, description: @doc_map.strings.option_detail_id
    field :method, :detail_variable_methods, description: @doc_map.strings.method
    field :slug, :string, description: @doc_map.strings.slug
  end

  payload_object(:detail_variable_payload, :variable)

  input_object :create_filter_variable_params, description: VariableDocs.create_filter_variable() do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :title, non_null(:string), description: @doc_map.strings.title
    field :option_filter_id, non_null(:id), description: @doc_map.strings.option_filter_id
    field :method, non_null(:filter_variable_methods), description: @doc_map.strings.method
    field :slug, :string, description: @doc_map.strings.slug
    import_fields :filter_variable_params
  end

  input_object :update_filter_variable_params, description: VariableDocs.update_filter_variable() do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :title, :string, description: @doc_map.strings.title
    field :option_filter_id, :id, description: @doc_map.strings.option_filter_id
    field :method, :filter_variable_methods, description: @doc_map.strings.method
    field :slug, :string, description: @doc_map.strings.slug
  end

  payload_object(:filter_variable_payload, :variable)

  input_object :delete_variable_params, description: VariableDocs.delete() do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :id, non_null(:id), description: @doc_map.strings.id
  end

  # provide an object that can be imported into the base mutations query.
  object :variable_mutations do

    field :create_detail_variable, type: :detail_variable_payload, description: VariableDocs.create_detail_variable() do
      arg :input, :create_detail_variable_params
      resolve mutation_resolver(&VariableResolver.create/2)
      middleware &build_payload/2
    end

    field :update_detail_variable, type: :detail_variable_payload, description: VariableDocs.update_detail_variable() do
      arg :input, :update_detail_variable_params
      resolve mutation_resolver(&VariableResolver.update/2)
      middleware &build_payload/2
    end

   field :create_filter_variable, type: :filter_variable_payload, description: VariableDocs.create_filter_variable() do
      arg :input, :create_filter_variable_params
      resolve mutation_resolver(&VariableResolver.create/2)
      middleware &build_payload/2
    end

    field :update_filter_variable, type: :filter_variable_payload, description: VariableDocs.update_filter_variable() do
      arg :input, :update_filter_variable_params
      resolve mutation_resolver(&VariableResolver.update/2)
      middleware &build_payload/2
    end

    field :delete_variable, type: :detail_variable_payload, description: VariableDocs.delete() do
      arg :input, :delete_option_params
      resolve mutation_resolver(&VariableResolver.delete/2)
      middleware &build_payload/2
    end
  end
end
