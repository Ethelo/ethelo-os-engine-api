defmodule GraphQL.EtheloApi.AdminSchema.BinVote do
  @moduledoc """
  Base access to BinVotes
  """
  use DocsComposer, module: EtheloApi.Voting.Docs.BinVote
  alias GraphQL.EtheloApi.Docs.BinVote, as: BinVoteDocs

  use Absinthe.Schema.Notation
  import GraphQL.EtheloApi.ResolveHelper
  import Kronky.Payload, only: [payload_object: 2, build_payload: 2]
  alias GraphQL.EtheloApi.Resolvers.BinVote, as: BinVoteResolver

  # queries

  object :bin_vote, description: @doc_map.strings.bin_vote do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :decision_id, non_null(:id), description: @doc_map.strings.id
    field :participant_id, non_null(:id), description: @doc_map.strings.id
    field :option_id, non_null(:id), description: @doc_map.strings.id
    field :criteria_id, non_null(:id), description: @doc_map.strings.id
    field :bin, non_null(:integer), description: @doc_map.strings.bin
    field :inserted_at, non_null(:datetime), description: @doc_map.strings.inserted_at
    field :updated_at, non_null(:datetime), description: @doc_map.strings.updated_at
  end

  object :bin_vote_list do
    field :bin_votes, list_of(:bin_vote) do
      arg :id, :id, description: "Filter by BinVote id"
      arg :participant_id, :id, description: "Filter by Participant id"
      arg :option_id, :id, description: "Filter by Option id"
      arg :criteria_id, :id, description: "Filter by Criteria id"
    resolve &BinVoteResolver.list/3
    end
  end

  input_object :bin_vote_params do
    field :decision_id, non_null(:id), description: @doc_map.strings.id
    field :participant_id, non_null(:id), description: @doc_map.strings.id
    field :option_id, non_null(:id), description: @doc_map.strings.id
    field :criteria_id, non_null(:id), description: @doc_map.strings.id
    field :bin, non_null(:integer), description: @doc_map.strings.bin
  end

  # mutations
  input_object :upsert_bin_vote_params, description: BinVoteDocs.upsert() do
    import_fields :bin_vote_params
    field :delete, :boolean, description: "Remove the matching entry if it exists"
  end

  input_object :delete_bin_vote_params, description: BinVoteDocs.delete() do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :id, non_null(:id), description: @doc_map.strings.id
  end

  payload_object(:bin_vote_payload, :bin_vote)

  # provide an object that can be imported into the base mutations query.
  object :bin_vote_mutations do
    field :upsert_bin_vote, type: :bin_vote_payload, description: BinVoteDocs.upsert() do
      arg :input, :upsert_bin_vote_params
      resolve mutation_resolver(&BinVoteResolver.upsert/2)
      middleware &build_payload/2
    end

    field :delete_bin_vote, type: :bin_vote_payload, description: BinVoteDocs.delete() do
      arg :input, :delete_bin_vote_params
      resolve mutation_resolver(&BinVoteResolver.delete/2)
      middleware &build_payload/2
    end
  end
end
