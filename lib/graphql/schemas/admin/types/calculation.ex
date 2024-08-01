defmodule GraphQL.EtheloApi.AdminSchema.Calculation do
  @moduledoc """
  Base access to OptionCategories
  """
  use DocsComposer, module: EtheloApi.Structure.Docs.Calculation
  use Absinthe.Schema.Notation
  alias GraphQL.EtheloApi.Docs.Calculation, as: CalculationDocs

  import GraphQL.EtheloApi.ResolveHelper
  import Kronky.Payload, only: [payload_object: 2, build_payload: 2]
  alias GraphQL.EtheloApi.Resolvers.Calculation, as: CalculationResolver

  # queries

  object :calculation do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :title, non_null(:string), description: @doc_map.strings.title
    field :personal_results_title, :string, description: @doc_map.strings.personal_results_title
    field :slug, non_null(:string), description: @doc_map.strings.slug
    field :expression, non_null(:string), description: @doc_map.strings.expression
    field :display_hint, :string, description: @doc_map.strings.display_hint
    field :public, non_null(:boolean), description: @doc_map.strings.public
    field :sort, :integer, description: @doc_map.strings.sort
    field :inserted_at, non_null(:datetime), description: @doc_map.strings.inserted_at
    field :updated_at, non_null(:datetime), description: @doc_map.strings.updated_at
    field :variables, list_of(:variable), description: @doc_map.strings.variables, resolve: &CalculationResolver.batch_load_variables/3
  end

  object :calculation_list do
    field :calculations, list_of(:calculation) do
      arg :id, :id, description: "Filter by Calculation id"
      arg :slug, :string, description: "Filter by Calculation slug"
      resolve &CalculationResolver.list/3
    end
  end

  input_object :calculation_params do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :public, :boolean, description: @doc_map.strings.public
    field :display_hint, :string, description: @doc_map.strings.display_hint
    field :slug, :string, description: @doc_map.strings.slug
    field :sort, :integer, description: @doc_map.strings.sort
  end

  # mutations
  input_object :create_calculation_params, description: CalculationDocs.create() do
    field :title, non_null(:string), description: @doc_map.strings.title
    field :personal_results_title, :string, description: @doc_map.strings.personal_results_title
    field :expression, non_null(:string), description: @doc_map.strings.expression
    import_fields :calculation_params
  end

  input_object :update_calculation_params, description: CalculationDocs.update() do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :title, :string, description: @doc_map.strings.title
    field :personal_results_title, :string, description: @doc_map.strings.personal_results_title
    field :expression, :string, description: @doc_map.strings.expression
    import_fields :calculation_params
  end

  input_object :delete_calculation_params, description: CalculationDocs.delete() do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :id, non_null(:id), description: @doc_map.strings.id
  end

  payload_object(:calculation_payload, :calculation)

  # provide an object that can be imported into the base mutations query.
  object :calculation_mutations do

    field :create_calculation, type: :calculation_payload, description: CalculationDocs.create() do
      arg :input, :create_calculation_params
      resolve mutation_resolver(&CalculationResolver.create/2)
      middleware &build_payload/2
    end

    field :update_calculation, type: :calculation_payload, description: CalculationDocs.update() do
      arg :input, :update_calculation_params
      resolve mutation_resolver(&CalculationResolver.update/2)
      middleware &build_payload/2
    end

    field :delete_calculation, type: :calculation_payload, description: CalculationDocs.delete() do
      arg :input, :delete_calculation_params
      resolve mutation_resolver(&CalculationResolver.delete/2)
      middleware &build_payload/2
    end
  end

end
