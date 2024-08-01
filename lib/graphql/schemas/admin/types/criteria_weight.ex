defmodule GraphQL.EtheloApi.AdminSchema.CriteriaWeight do
  @moduledoc """
  Base access to CriteriaWeights
  """
  use DocsComposer, module: EtheloApi.Voting.Docs.CriteriaWeight
  alias GraphQL.EtheloApi.Docs.CriteriaWeight, as: CriteriaWeightDocs

  use Absinthe.Schema.Notation
  import GraphQL.EtheloApi.ResolveHelper
  import Kronky.Payload, only: [payload_object: 2, build_payload: 2]
  alias GraphQL.EtheloApi.Resolvers.CriteriaWeight, as: CriteriaWeightResolver

  # queries

  object :criteria_weight, description: @doc_map.strings.criteria_weight do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :decision_id, non_null(:id), description: @doc_map.strings.id
    field :criteria_id, non_null(:id), description: @doc_map.strings.id
    field :participant_id, non_null(:id), description: @doc_map.strings.id
    field :weighting, non_null(:integer), description: @doc_map.strings.weighting
    field :inserted_at, non_null(:datetime), description: @doc_map.strings.inserted_at
    field :updated_at, non_null(:datetime), description: @doc_map.strings.updated_at
  end

  object :criteria_weight_list do
    field :criteria_weights, list_of(:criteria_weight) do
      arg :id, :id, description: "Filter by CategoryWeight id"
      arg :participant_id, :id, description: "Filter by Participant id"
      arg :criteria_id, :id, description: "Filter by Criteria id"
    resolve &CriteriaWeightResolver.list/3
    end
  end

  input_object :criteria_weight_params do
    field :decision_id, non_null(:id), description: @doc_map.strings.id
    field :criteria_id, non_null(:id), description: @doc_map.strings.id
    field :participant_id, non_null(:id), description: @doc_map.strings.id
    field :weighting, non_null(:integer), description: @doc_map.strings.weighting
  end

  # mutations
  input_object :upsert_criteria_weight_params, description: CriteriaWeightDocs.create() do
    import_fields :criteria_weight_params
    field :delete, :boolean, description: "Remove the matching entry if it exists"
  end

  input_object :delete_criteria_weight_params, description: CriteriaWeightDocs.delete() do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :id, non_null(:id), description: @doc_map.strings.id
  end

  payload_object(:criteria_weight_payload, :criteria_weight)

  # provide an object that can be imported into the base mutations query.
  object :criteria_weight_mutations do
    field :upsert_criteria_weight, type: :criteria_weight_payload, description: CriteriaWeightDocs.create() do
      arg :input, :upsert_criteria_weight_params
      resolve mutation_resolver(&CriteriaWeightResolver.upsert/2)
      middleware &build_payload/2
    end

    field :delete_criteria_weight, type: :criteria_weight_payload, description: CriteriaWeightDocs.delete() do
      arg :input, :delete_criteria_weight_params
      resolve mutation_resolver(&CriteriaWeightResolver.delete/2)
      middleware &build_payload/2
    end
  end
end
