defmodule EtheloApi.Graphql.Schemas.Participant do
  @moduledoc """
  Base access to Participants
  """

  use Absinthe.Schema.Notation
  use DocsComposer, module: EtheloApi.Voting.Docs.Participant

  alias EtheloApi.Graphql.Docs.Participant, as: ParticipantDocs
  alias EtheloApi.Graphql.Resolvers.Participant, as: ParticipantResolver

  import AbsintheErrorPayload.Payload
  import Absinthe.Resolution.Helpers, only: [dataloader: 2]
  import EtheloApi.Graphql.Middleware
  import EtheloApi.Helpers.ValidationHelper

  # queries

  object :participant do
    field :bin_votes, list_of(:bin_vote), resolve: dataloader(:repo, :bin_votes)

    field :criteria_weights, list_of(:criteria_weight),
      resolve: dataloader(:repo, :criteria_weights)

    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.inserted_at
    field :inserted_at, non_null(:datetime)

    @desc @doc_map.strings.updated_at
    field :updated_at, non_null(:datetime)

    field :option_category_range_votes, list_of(:option_category_range_vote),
      resolve: dataloader(:repo, :option_category_range_votes)

    field :option_category_weights, list_of(:option_category_weight),
      resolve: dataloader(:repo, :option_category_weights)

    @desc @doc_map.strings.weighting
    field :weighting, non_null(:float),
      resolve: fn parent, _, _ ->
        parent |> Map.get(:weighting) |> Decimal.to_float() |> success()
      end
  end

  object :participant_list do
    field :participants, list_of(:participant) do
      @desc "Filter by Participant id"
      arg(:id, :id)
      resolve(&ParticipantResolver.list/3)
    end
  end

  # mutations
  payload_object(:participant_payload, :participant)
  @desc ParticipantDocs.create()
  input_object :participant_params do
    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)
  end

  @desc ParticipantDocs.create()
  input_object :create_params do
    @desc @doc_map.strings.weighting
    field :weighting, :float
    import_fields(:participant_params)
  end

  @desc ParticipantDocs.update()
  input_object :update_params do
    @desc @doc_map.strings.id
    field :id, non_null(:id)
    @desc @doc_map.strings.weighting
    field :weighting, non_null(:float)
    import_fields(:participant_params)
  end

  @desc ParticipantDocs.delete()
  input_object :delete_participant_params do
    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)
    @desc @doc_map.strings.id
    field :id, non_null(:id)
  end

  object :participant_mutations do
    @desc ParticipantDocs.create()
    field :create_participant, type: :participant_payload do
      arg(:input, :create_params)
      middleware(&preload_decision/2)
      resolve(&ParticipantResolver.create/2)
      middleware(&build_payload/2)
    end

    @desc ParticipantDocs.update()
    field :update_participant, type: :participant_payload do
      arg(:input, :update_params)
      middleware(&preload_decision/2)
      resolve(&ParticipantResolver.update/2)
      middleware(&build_payload/2)
    end

    @desc ParticipantDocs.delete()
    field :delete_participant, type: :participant_payload do
      arg(:input, :delete_participant_params)
      middleware(&preload_decision/2)
      resolve(&ParticipantResolver.delete/2)
      middleware(&build_payload/2)
    end
  end
end
