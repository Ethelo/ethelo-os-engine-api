defmodule GraphQL.EtheloApi.AdminSchema.Participant do
  @moduledoc """
  Base access to Participants
  """
  use DocsComposer, module: EtheloApi.Voting.Docs.Participant
  alias GraphQL.EtheloApi.Docs.Participant, as: ParticipantDocs

  use Absinthe.Schema.Notation
  import GraphQL.EtheloApi.ResolveHelper
  import Kronky.Payload, only: [payload_object: 2, build_payload: 2]
  alias GraphQL.EtheloApi.Resolvers.Participant, as: ParticipantResolver

  # queries

  object :participant, description: @doc_map.strings.participant do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :decision_id, non_null(:id), description: @doc_map.strings.id
    field :weighting, non_null(:float), description: @doc_map.strings.weighting

    field :bin_votes, list_of(:bin_vote),
      resolve: &ParticipantResolver.batch_load_bin_votes/3
    field :option_category_range_votes, list_of(:option_category_range_vote),
      resolve: &ParticipantResolver.batch_load_option_category_range_votes/3
    field :option_category_weights, list_of(:option_category_weight),
      resolve: &ParticipantResolver.batch_load_option_category_weights/3
    field :criteria_weights, list_of(:criteria_weight),
      resolve: &ParticipantResolver.batch_load_criteria_weights/3
  end

  object :participant_list do
    field :participants, list_of(:participant) do
      arg :id, :id, description: "Filter by Participant id"
      resolve &ParticipantResolver.list/3
    end
  end

  input_object :participant_params do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :weighting, :float, description: @doc_map.strings.weighting
  end

  # mutations
  input_object :create_participant_params, description: ParticipantDocs.create() do
    import_fields :participant_params
  end

  input_object :update_participant_params, description: ParticipantDocs.update() do
    field :id, non_null(:id), description: @doc_map.strings.id
    import_fields :participant_params
  end

  input_object :delete_participant_params, description: ParticipantDocs.delete() do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :id, non_null(:id), description: @doc_map.strings.id
  end

  payload_object(:participant_payload, :participant)

  # provide an object that can be imported into the base mutations query.
  object :participant_mutations do
    field :create_participant, type: :participant_payload, description: ParticipantDocs.create() do
      arg :input, :create_participant_params
      resolve mutation_resolver(&ParticipantResolver.create/2)
      middleware &build_payload/2
    end

    field :update_participant, type: :participant_payload, description: ParticipantDocs.update() do
      arg :input, :update_participant_params
      resolve mutation_resolver(&ParticipantResolver.update/2)
      middleware &build_payload/2
    end

    field :delete_participant, type: :participant_payload, description: ParticipantDocs.delete() do
      arg :input, :delete_participant_params
      resolve mutation_resolver(&ParticipantResolver.delete/2)
      middleware &build_payload/2
    end
  end
end
