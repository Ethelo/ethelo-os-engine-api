defmodule GraphQL.EtheloApi.AdminSchema.Criteria do
  @moduledoc """
  Base access to criterias
  """
  use DocsComposer, module: EtheloApi.Structure.Docs.Criteria
  alias GraphQL.EtheloApi.Docs.Criteria, as: CriteriaDocs

  use Absinthe.Schema.Notation
  import GraphQL.EtheloApi.ResolveHelper
  import Kronky.Payload, only: [payload_object: 2, build_payload: 2]
  alias GraphQL.EtheloApi.Resolvers.Criteria, as: CriteriaResolver
  # queries

  object :criteria do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :title, :string, description: @doc_map.strings.title
    field :slug, :string, description: @doc_map.strings.slug
    field :info, :string, description: @doc_map.strings.info
    field :bins, :integer, description: @doc_map.strings.bins
    field :support_only, :boolean, description: @doc_map.strings.support_only
    field :weighting, :integer, description: @doc_map.strings.weighting
    field :apply_participant_weights, :boolean, description: @doc_map.strings.apply_participant_weights
    field :deleted, non_null(:boolean), description: @doc_map.strings.deleted
    field :sort, :integer, description: @doc_map.strings.sort
    field :inserted_at, non_null(:datetime), description: @doc_map.strings.inserted_at
    field :updated_at, non_null(:datetime), description: @doc_map.strings.updated_at
  end

  object :criteria_list do
    field :criterias, list_of(:criteria) do
      arg :id, :id, description: "Filter by Criteria id"
      arg :slug, :string, description: "Filter by Criteria slug"
      arg :deleted, :boolean, description: "Filter by deleted flag"
      resolve &CriteriaResolver.list/3
    end
  end

  input_object :criteria_params do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :support_only, :boolean, description: @doc_map.strings.support_only
    field :weighting, :integer, description: @doc_map.strings.weighting
    field :apply_participant_weights, :boolean, description: @doc_map.strings.apply_participant_weights
    field :info, :string, description: @doc_map.strings.info
    field :slug, :string, description: @doc_map.strings.slug
    field :deleted, :boolean, description: @doc_map.strings.deleted
    field :sort, :integer, description: @doc_map.strings.sort
  end

  # mutations
  input_object :create_criteria_params, description: CriteriaDocs.create() do
    field :title, non_null(:string), description: @doc_map.strings.title
    field :bins, non_null(:integer), description: @doc_map.strings.bins
    import_fields :criteria_params
  end

  input_object :update_criteria_params, description: CriteriaDocs.update() do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :title, :string, description: @doc_map.strings.title
    field :bins, :integer, description: @doc_map.strings.bins
    import_fields :criteria_params
    end

  input_object :delete_criteria_params, description: CriteriaDocs.delete() do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :id, non_null(:id), description: @doc_map.strings.id
  end

  payload_object(:criteria_payload, :criteria)

  # provide an object that can be imported into the base mutations query.
  object :criteria_mutations do

    field :create_criteria, type: :criteria_payload, description: CriteriaDocs.create() do
      arg :input, :create_criteria_params
      resolve mutation_resolver(&CriteriaResolver.create/2)
      middleware &build_payload/2
    end

    field :update_criteria, type: :criteria_payload, description: CriteriaDocs.update() do
      arg :input, :update_criteria_params
      resolve mutation_resolver(&CriteriaResolver.update/2)
      middleware &build_payload/2
    end

    field :delete_criteria, type: :criteria_payload, description: CriteriaDocs.delete() do
      arg :input, :delete_criteria_params
      resolve mutation_resolver(&CriteriaResolver.delete/2)
      middleware &build_payload/2
    end
  end

end
