defmodule EtheloApi.Graphql.Schemas.Variable do
  @moduledoc """
  Base access to Variables
  """

  use Absinthe.Schema.Notation
  use DocsComposer, module: EtheloApi.Structure.Docs.Variable

  alias EtheloApi.Graphql.Docs.Variable, as: VariableDocs
  alias EtheloApi.Graphql.Resolvers.Variable, as: VariableResolver

  import AbsintheErrorPayload.Payload
  import EtheloApi.Graphql.Middleware
  import Absinthe.Resolution.Helpers, only: [dataloader: 2]

  @desc @doc_map.strings.method
  enum :variable_methods do
    @desc @doc_map.strings.method_sum_selected
    value(:sum_selected)

    @desc @doc_map.strings.method_mean_selected
    value(:mean_selected)

    @desc @doc_map.strings.method_sum_all
    value(:sum_all)

    @desc @doc_map.strings.method_mean_all
    value(:mean_all)

    @desc @doc_map.strings.method_count_selected
    value(:count_selected)

    @desc @doc_map.strings.method_count_all
    value(:count_all)
  end

  @desc @doc_map.strings.method
  enum :detail_variable_methods do
    @desc @doc_map.strings.method_sum_selected
    value(:sum_selected)

    @desc @doc_map.strings.method_mean_selected
    value(:mean_selected)

    @desc @doc_map.strings.method_sum_all
    value(:sum_all)

    @desc @doc_map.strings.method_mean_all
    value(:mean_all)
  end

  @desc @doc_map.strings.method
  enum :filter_variable_methods do
    @desc @doc_map.strings.method_count_selected
    value(:count_selected)

    @desc @doc_map.strings.method_count_all
    value(:count_all)
  end

  # queries
  object :variable do
    @desc @doc_map.strings.calculations
    field :calculations, list_of(:calculation), resolve: dataloader(:repo, :calculations)

    @desc @doc_map.strings.calculation_ids
    field :calculation_ids,
          list_of(:id),
          resolve:
            dataloader(:variables, fn variable, args, _resolution ->
              args = Map.put(args, :decision_id, variable.decision_id)
              {:calculation_ids_by_variable, args}
            end)

    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.inserted_at
    field :inserted_at, non_null(:datetime)

    @desc @doc_map.strings.method
    field :method, non_null(:variable_methods)

    @desc @doc_map.strings.option_detail
    field :option_detail, :option_detail, resolve: dataloader(:repo, :option_detail)

    @desc @doc_map.strings.option_detail_id
    field :option_detail_id, :id

    @desc @doc_map.strings.option_filter
    field :option_filter, :option_filter, resolve: dataloader(:repo, :option_filter)

    @desc @doc_map.strings.option_filter_id
    field :option_filter_id, :id

    @desc @doc_map.strings.slug
    field :slug, non_null(:string)

    @desc @doc_map.strings.title
    field :title, non_null(:string)

    @desc @doc_map.strings.updated_at
    field :updated_at, non_null(:datetime)
  end

  object :variable_suggestion do
    @desc @doc_map.strings.title
    field :title, non_null(:string)

    @desc @doc_map.strings.slug
    field :slug, :string

    @desc @doc_map.strings.method
    field :method, non_null(:variable_methods)

    field :option_detail_id, :id

    field :option_filter_id, :id

    field :calculations_id, :id
  end

  object :variable_list do
    field :variables, list_of(:variable) do
      @desc "Filter by Variable id"
      arg(:id, :id)

      @desc "Filter by Variable slug"
      arg(:slug, :string)

      @desc @doc_map.strings.option_detail_id
      arg(:option_detail_id, :id)

      @desc @doc_map.strings.option_filter_id
      arg(:option_filter_id, :id)

      resolve(&VariableResolver.list/3)
    end
  end

  object :variable_suggestion_list do
    field :variable_suggestions, list_of(:variable_suggestion),
      resolve: &VariableResolver.suggested/3
  end

  # mutations

  payload_object(:variable_payload, :variable)

  @desc VariableDocs.create_detail_variable()
  input_object :create_detail_variable_params do
    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc @doc_map.strings.title
    field :title, non_null(:string)

    @desc @doc_map.strings.slug
    field :slug, :string

    @desc @doc_map.strings.option_detail_id
    field :option_detail_id, non_null(:id)

    @desc @doc_map.strings.method
    field :method, non_null(:detail_variable_methods)
  end

  @desc VariableDocs.update_detail_variable()
  input_object :update_detail_variable_params do
    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.slug
    field :slug, :string

    @desc @doc_map.strings.title
    field :title, :string

    @desc @doc_map.strings.option_detail_id
    field :option_detail_id, :id

    @desc @doc_map.strings.method
    field :method, :detail_variable_methods
  end

  @desc VariableDocs.create_filter_variable()
  input_object :create_filter_variable_params do
    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc @doc_map.strings.title
    field :title, non_null(:string)

    @desc @doc_map.strings.slug
    field :slug, :string

    @desc @doc_map.strings.option_filter_id
    field :option_filter_id, non_null(:id)

    @desc @doc_map.strings.method
    field :method, non_null(:filter_variable_methods)
  end

  @desc VariableDocs.update_filter_variable()
  input_object :update_filter_variable_params do
    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.slug
    field :slug, :string

    @desc @doc_map.strings.title
    field :title, :string

    @desc @doc_map.strings.option_filter_id
    field :option_filter_id, :id

    @desc @doc_map.strings.method
    field :method, :filter_variable_methods
  end

  @desc VariableDocs.delete()
  input_object :delete_variable_params do
    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc @doc_map.strings.id
    field :id, non_null(:id)
  end

  object :variable_mutations do
    @desc VariableDocs.create_detail_variable()
    field :create_detail_variable, type: :variable_payload do
      arg(:input, :create_detail_variable_params)
      middleware(&preload_decision/2)
      resolve(&VariableResolver.create/2)
      middleware(&build_payload/2)
    end

    @desc VariableDocs.update_detail_variable()
    field :update_detail_variable, type: :variable_payload do
      arg(:input, :update_detail_variable_params)
      middleware(&preload_decision/2)
      resolve(&VariableResolver.update/2)
      middleware(&build_payload/2)
    end

    @desc VariableDocs.create_filter_variable()
    field :create_filter_variable, type: :variable_payload do
      arg(:input, :create_filter_variable_params)
      middleware(&preload_decision/2)
      resolve(&VariableResolver.create/2)
      middleware(&build_payload/2)
    end

    @desc VariableDocs.update_filter_variable()
    field :update_filter_variable, type: :variable_payload do
      arg(:input, :update_filter_variable_params)
      middleware(&preload_decision/2)
      resolve(&VariableResolver.update/2)
      middleware(&build_payload/2)
    end

    @desc VariableDocs.delete()
    field :delete_variable, type: :variable_payload do
      arg(:input, :delete_variable_params)
      middleware(&preload_decision/2)
      resolve(&VariableResolver.delete/2)
      middleware(&build_payload/2)
    end
  end
end
