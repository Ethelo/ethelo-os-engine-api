defmodule EtheloApi.Graphql.Schemas.Criteria do
  @moduledoc """
  Base access to Criterias
  """
  use Absinthe.Schema.Notation
  use DocsComposer, module: EtheloApi.Structure.Docs.Criteria
  alias EtheloApi.Graphql.Docs.Criteria, as: CriteriaDocs
  alias EtheloApi.Graphql.Resolvers.Criteria, as: CriteriaResolver

  import AbsintheErrorPayload.Payload
  import EtheloApi.Graphql.Middleware

  # queries
  object :criteria do
    @desc @doc_map.strings.apply_participant_weights
    field :apply_participant_weights, :boolean

    @desc @doc_map.strings.bins
    field :bins, :integer

    @desc @doc_map.strings.deleted
    field :deleted, non_null(:boolean)

    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.info
    field :info, :string

    @desc @doc_map.strings.inserted_at
    field :inserted_at, non_null(:datetime)

    @desc @doc_map.strings.slug
    field :slug, :string

    @desc @doc_map.strings.sort
    field :sort, :integer

    @desc @doc_map.strings.support_only
    field :support_only, :boolean

    @desc @doc_map.strings.title
    field :title, :string

    @desc @doc_map.strings.updated_at
    field :updated_at, non_null(:datetime)

    @desc @doc_map.strings.weighting
    field :weighting, :integer
  end

  object :criteria_list do
    field :criterias, list_of(:criteria) do
      @desc "Filter by Criteria id"
      arg(:id, :id)

      @desc "Filter by deleted flag"
      arg(:deleted, :boolean)

      @desc "Filter by Criteria slug"
      arg(:slug, :string)

      resolve(&CriteriaResolver.list/3)
    end
  end

  # mutations
  payload_object(:criteria_payload, :criteria)

  @desc CriteriaDocs.create()
  input_object :criteria_params do
    @desc @doc_map.strings.apply_participant_weights
    field :apply_participant_weights, :boolean

    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc @doc_map.strings.deleted
    field :deleted, :boolean

    @desc @doc_map.strings.info
    field :info, :string

    @desc @doc_map.strings.slug
    field :slug, :string

    @desc @doc_map.strings.sort
    field :sort, :integer

    @desc @doc_map.strings.support_only
    field :support_only, :boolean

    @desc @doc_map.strings.weighting
    field :weighting, :integer
  end

  @desc CriteriaDocs.create()
  input_object :create_criteria_params do
    @desc @doc_map.strings.bins
    field :bins, non_null(:integer)

    @desc @doc_map.strings.title
    field :title, non_null(:string)

    import_fields(:criteria_params)
  end

  @desc CriteriaDocs.update()
  input_object :update_criteria_params do
    @desc @doc_map.strings.bins
    field :bins, :integer

    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.title
    field :title, :string

    import_fields(:criteria_params)
  end

  @desc CriteriaDocs.delete()
  input_object :delete_criteria_params do
    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc @doc_map.strings.id
    field :id, non_null(:id)
  end

  object :criteria_mutations do
    @desc CriteriaDocs.create()
    field :create_criteria, type: :criteria_payload do
      arg(:input, :create_criteria_params)
      middleware(&preload_decision/2)
      resolve(&CriteriaResolver.create/2)
      middleware(&build_payload/2)
    end

    @desc CriteriaDocs.update()
    field :update_criteria, type: :criteria_payload do
      arg(:input, :update_criteria_params)
      middleware(&preload_decision/2)
      resolve(&CriteriaResolver.update/2)
      middleware(&build_payload/2)
    end

    @desc CriteriaDocs.delete()
    field :delete_criteria, type: :criteria_payload do
      arg(:input, :delete_criteria_params)
      middleware(&preload_decision/2)
      resolve(&CriteriaResolver.delete/2)
      middleware(&build_payload/2)
    end
  end
end
