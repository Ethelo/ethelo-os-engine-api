defmodule EtheloApi.Graphql.Schemas.CriteriaWeight do
  @moduledoc """
  Base access to CriteriaWeights
  """

  use Absinthe.Schema.Notation
  use DocsComposer, module: EtheloApi.Voting.Docs.CriteriaWeight
  alias EtheloApi.Graphql.Docs.CriteriaWeight, as: CriteriaWeightDocs
  alias EtheloApi.Graphql.Resolvers.CriteriaWeight, as: CriteriaWeightResolver
  import AbsintheErrorPayload.Payload
  import EtheloApi.Graphql.Middleware

  # queries

  @desc @doc_map.strings.criteria_weight
  object :criteria_weight do
    @desc @doc_map.strings.criteria_id
    field :criteria_id, non_null(:id)

    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.inserted_at
    field :inserted_at, non_null(:datetime)

    @desc @doc_map.strings.participant_id
    field :participant_id, non_null(:id)

    @desc @doc_map.strings.updated_at
    field :updated_at, non_null(:datetime)

    @desc @doc_map.strings.weighting
    field :weighting, non_null(:integer)
  end

  object :criteria_weight_list do
    field :criteria_weights, list_of(:criteria_weight) do
      @desc "Filter by CategoryWeight id"
      arg(:id, :id)

      @desc "Filter by Criteria id"
      arg(:criteria_id, :id)

      @desc "Filter by Participant id"
      arg(:participant_id, :id)

      resolve(&CriteriaWeightResolver.list/3)
    end
  end

  # mutations
  payload_object(:criteria_weight_payload, :criteria_weight)

  input_object :criteria_weight_params do
    @desc @doc_map.strings.criteria_id
    field :criteria_id, non_null(:id)

    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc "Remove the record entry if it exists"
    field :delete, :boolean

    @desc @doc_map.strings.participant_id
    field :participant_id, non_null(:id)

    @desc @doc_map.strings.weighting
    field :weighting, non_null(:integer)
  end

  @desc CriteriaWeightDocs.upsert()
  input_object :upsert_criteria_weight_params do
    import_fields(:criteria_weight_params)
  end

  object :criteria_weight_mutations do
    @desc CriteriaWeightDocs.upsert()
    field :upsert_criteria_weight, type: :criteria_weight_payload do
      arg(:input, :upsert_criteria_weight_params)
      middleware(&preload_decision/2)
      resolve(&CriteriaWeightResolver.upsert/2)
      middleware(&build_payload/2)
    end
  end
end
