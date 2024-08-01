defmodule GraphQL.EtheloApi.AdminSchema.OptionCategoryBinVote do
  @moduledoc """
  Base access to OptionCategoryBinVotes
  """
  use DocsComposer, module: EtheloApi.Voting.Docs.OptionCategoryBinVote
  alias GraphQL.EtheloApi.Docs.OptionCategoryBinVote, as: OptionCategoryBinVoteDocs

  use Absinthe.Schema.Notation
  import GraphQL.EtheloApi.ResolveHelper
  import Kronky.Payload, only: [payload_object: 2, build_payload: 2]
  alias GraphQL.EtheloApi.Resolvers.OptionCategoryBinVote, as: OptionCategoryBinVoteResolver

  # queries

  object :option_category_bin_vote, description: @doc_map.strings.option_category_bin_vote do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :participant_id, non_null(:id), description: @doc_map.strings.participant_id
    field :option_category_id, non_null(:id), description: @doc_map.strings.option_category_id
    field :criteria_id, non_null(:id), description: @doc_map.strings.criteria_id
    field :bin, non_null(:integer), description: @doc_map.strings.bin
    field :inserted_at, non_null(:datetime), description: @doc_map.strings.inserted_at
    field :updated_at, non_null(:datetime), description: @doc_map.strings.updated_at
  end

  object :option_category_bin_vote_list do
    field :option_category_bin_votes, list_of(:option_category_bin_vote) do
      arg :id, :id, description: "Filter by OptionCategoryBinVote id"
      arg :participant_id, :id, description: "Filter by Participant id"
      arg :option_category_id, :id, description: "Filter by OptionCategory id"
      arg :criteria_id, :id, description: "Filter by Criteria id"
    resolve &OptionCategoryBinVoteResolver.list/3
    end
  end

  input_object :option_category_bin_vote_params do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :participant_id, non_null(:id), description: @doc_map.strings.participant_id
    field :option_category_id, non_null(:id), description: @doc_map.strings.option_category_id
    field :criteria_id, non_null(:id), description: @doc_map.strings.criteria_id
    field :bin, non_null(:integer), description: @doc_map.strings.bin
  end

  # mutations
  input_object :upsert_option_category_bin_vote_params, description: OptionCategoryBinVoteDocs.upsert() do
    import_fields :option_category_bin_vote_params
    field :delete, :boolean, description: "Remove the matching entry if it exists"
  end

  input_object :delete_option_category_bin_vote_params, description: OptionCategoryBinVoteDocs.delete() do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :id, non_null(:id), description: @doc_map.strings.id
  end

  payload_object(:option_category_bin_vote_payload, :option_category_bin_vote)

  # provide an object that can be imported into the base mutations query.
  object :option_category_bin_vote_mutations do
    field :upsert_option_category_bin_vote, type: :option_category_bin_vote_payload, description: OptionCategoryBinVoteDocs.upsert() do
      arg :input, :upsert_option_category_bin_vote_params
      resolve mutation_resolver(&OptionCategoryBinVoteResolver.upsert/2)
      middleware &build_payload/2
    end

    field :delete_option_category_bin_vote, type: :option_category_bin_vote_payload, description: OptionCategoryBinVoteDocs.delete() do
      arg :input, :delete_option_category_bin_vote_params
      resolve mutation_resolver(&OptionCategoryBinVoteResolver.delete/2)
      middleware &build_payload/2
    end
  end
end
