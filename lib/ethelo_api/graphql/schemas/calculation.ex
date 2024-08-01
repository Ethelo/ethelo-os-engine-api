defmodule EtheloApi.Graphql.Schemas.Calculation do
  @moduledoc """
  Base access to OptionCategories
  """
  use Absinthe.Schema.Notation
  use DocsComposer, module: EtheloApi.Structure.Docs.Calculation

  alias EtheloApi.Graphql.Docs.Calculation, as: CalculationDocs
  alias EtheloApi.Graphql.Resolvers.Calculation, as: CalculationResolver

  import AbsintheErrorPayload.Payload
  import EtheloApi.Graphql.Middleware
  import Absinthe.Resolution.Helpers, only: [dataloader: 2]
  # queries

  object :calculation do
    @desc @doc_map.strings.display_hint
    field :display_hint, :string

    @desc @doc_map.strings.expression
    field :expression, non_null(:string)

    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.inserted_at
    field :inserted_at, non_null(:datetime)

    @desc @doc_map.strings.personal_results_title
    field :personal_results_title, :string

    @desc @doc_map.strings.public
    field :public, non_null(:boolean)

    @desc @doc_map.strings.slug
    field :slug, non_null(:string)

    @desc @doc_map.strings.sort
    field :sort, :integer

    @desc @doc_map.strings.title
    field :title, non_null(:string)

    @desc @doc_map.strings.updated_at
    field :updated_at, non_null(:datetime)

    @desc @doc_map.strings.variables
    field :variables, list_of(:variable), resolve: dataloader(:repo, :variables)
  end

  object :calculation_list do
    field :calculations, list_of(:calculation) do
      @desc "Filter by Calculation id"
      arg(:id, :id)
      @desc "Filter by Calculation slug"
      arg(:slug, :string)
      resolve(&CalculationResolver.list/3)
    end
  end

  # mutations

  payload_object(:calculation_payload, :calculation)

  input_object :calculation_params do
    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)
    @desc @doc_map.strings.display_hint
    field :display_hint, :string
    @desc @doc_map.strings.public
    field :public, :boolean
    @desc @doc_map.strings.slug
    field :slug, :string
    @desc @doc_map.strings.sort
    field :sort, :integer
  end

  @desc CalculationDocs.create()
  input_object :create_calculation_params do
    @desc @doc_map.strings.expression
    field :expression, non_null(:string)

    @desc @doc_map.strings.personal_results_title
    field :personal_results_title, :string

    @desc @doc_map.strings.title
    field :title, non_null(:string)

    import_fields(:calculation_params)
  end

  @desc CalculationDocs.update()
  input_object :update_calculation_params do
    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.expression
    field :expression, :string

    @desc @doc_map.strings.personal_results_title
    field :personal_results_title, :string

    @desc @doc_map.strings.title
    field :title, :string

    import_fields(:calculation_params)
  end

  @desc CalculationDocs.delete()
  input_object :delete_calculation_params do
    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc @doc_map.strings.id
    field :id, non_null(:id)
  end

  object :calculation_mutations do
    @desc CalculationDocs.create()
    field :create_calculation, type: :calculation_payload do
      arg(:input, :create_calculation_params)
      middleware(&preload_decision/2)
      resolve(&CalculationResolver.create/2)
      middleware(&build_payload/2)
    end

    @desc CalculationDocs.update()
    field :update_calculation, type: :calculation_payload do
      arg(:input, :update_calculation_params)
      middleware(&preload_decision/2)
      resolve(&CalculationResolver.update/2)
      middleware(&build_payload/2)
    end

    @desc CalculationDocs.delete()
    field :delete_calculation, type: :calculation_payload do
      arg(:input, :delete_calculation_params)
      middleware(&preload_decision/2)
      resolve(&CalculationResolver.delete/2)
      middleware(&build_payload/2)
    end
  end
end
