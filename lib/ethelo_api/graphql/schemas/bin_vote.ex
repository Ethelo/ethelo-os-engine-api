defmodule EtheloApi.Graphql.Schemas.BinVote do
  @moduledoc """
  Base access to BinVotes
  """

  use Absinthe.Schema.Notation
  use DocsComposer, module: EtheloApi.Voting.Docs.BinVote
  alias EtheloApi.Graphql.Docs.BinVote, as: BinVoteDocs
  alias EtheloApi.Graphql.Resolvers.BinVote, as: BinVoteResolver
  import AbsintheErrorPayload.Payload
  import EtheloApi.Graphql.Middleware

  # queries

  @desc @doc_map.strings.bin_vote
  object :bin_vote do
    @desc @doc_map.strings.bin
    field :bin, non_null(:integer)

    @desc @doc_map.strings.criteria_id
    field :criteria_id, non_null(:id)

    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.inserted_at
    field :inserted_at, non_null(:datetime)

    @desc @doc_map.strings.option_id
    field :option_id, non_null(:id)

    @desc @doc_map.strings.participant_id
    field :participant_id, non_null(:id)

    @desc @doc_map.strings.updated_at
    field :updated_at, non_null(:datetime)
  end

  object :bin_vote_list do
    field :bin_votes, list_of(:bin_vote) do
      @desc "Filter by BinVote id"
      arg(:id, :id)

      @desc "Filter by Criteria id"
      arg(:criteria_id, :id)

      @desc "Filter by Option id"
      arg(:option_id, :id)

      @desc "Filter by Participant id"
      arg(:participant_id, :id)

      resolve(&BinVoteResolver.list/3)
    end
  end

  object :bin_vote_activity do
    field :bin_vote_activity, list_of(:date_count) do
      @desc "The date interval to group by to retrieve: 'year', 'month', 'week', 'day'"
      arg(:interval, :string)

      resolve(&BinVoteResolver.activity/3)
    end
  end

  # mutations

  payload_object(:bin_vote_payload, :bin_vote)

  input_object :bin_vote_params do
    @desc @doc_map.strings.bin
    field :bin, non_null(:integer)

    @desc @doc_map.strings.criteria_id
    field :criteria_id, non_null(:id)

    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc "Remove the matching entry if it exists"
    field :delete, :boolean

    @desc @doc_map.strings.option_id
    field :option_id, non_null(:id)

    @desc @doc_map.strings.participant_id
    field :participant_id, non_null(:id)
  end

  @desc BinVoteDocs.upsert()
  input_object :upsert_bin_vote_params do
    import_fields(:bin_vote_params)
  end

  object :bin_vote_mutations do
    @desc BinVoteDocs.upsert()
    field :upsert_bin_vote, type: :bin_vote_payload do
      arg(:input, :upsert_bin_vote_params)
      middleware(&preload_decision/2)
      resolve(&BinVoteResolver.upsert/2)
      middleware(&build_payload/2)
    end
  end
end
