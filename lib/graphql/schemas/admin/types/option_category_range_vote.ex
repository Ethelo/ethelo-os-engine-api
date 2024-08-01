defmodule GraphQL.EtheloApi.AdminSchema.OptionCategoryRangeVote do
  @moduledoc """
  Base access to OptionCategoryRangeVotes
  """
  use DocsComposer, module: EtheloApi.Voting.Docs.OptionCategoryRangeVote
  alias GraphQL.EtheloApi.Docs.OptionCategoryRangeVote, as: OptionCategoryRangeVoteDocs

  use Absinthe.Schema.Notation
  import GraphQL.EtheloApi.ResolveHelper
  import Kronky.Payload, only: [payload_object: 2, build_payload: 2]
  alias GraphQL.EtheloApi.Resolvers.OptionCategoryRangeVote, as: OptionCategoryRangeVoteResolver

  # queries
  object :option_category_range_vote, description: @doc_map.strings.option_category_range_vote do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :participant_id, non_null(:id), description: @doc_map.strings.participant_id
    field :option_category_id, non_null(:id), description: @doc_map.strings.option_category_id
    field :low_option_id, non_null(:id), description: @doc_map.strings.low_option_id
    field :high_option_id, :id, description: @doc_map.strings.high_option_id
    field :inserted_at, non_null(:datetime), description: @doc_map.strings.inserted_at
    field :updated_at, non_null(:datetime), description: @doc_map.strings.updated_at
  end

  object :option_category_range_vote_list do
    field :option_category_range_votes, list_of(:option_category_range_vote) do
      arg :participant_id, :id, description: "Filter by Participant id"
      arg :option_category_id, :id, description: "Filter by OptionCategory id"
      arg :high_option_id, :id, description: "Filter by high Option id"
      arg :low_option_id, :id, description: "Filter by low Option id"
    resolve &OptionCategoryRangeVoteResolver.list/3
    end
  end

  input_object :option_category_range_vote_params do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :participant_id, non_null(:id), description: @doc_map.strings.participant_id
    field :option_category_id, non_null(:id), description: @doc_map.strings.option_category_id
    field :low_option_id, non_null(:id), description: @doc_map.strings.low_option_id
    field :high_option_id, :id, description: @doc_map.strings.high_option_id
  end

  # mutations
  input_object :upsert_option_category_range_vote_params, description: OptionCategoryRangeVoteDocs.upsert() do
    import_fields :option_category_range_vote_params
    field :delete, :boolean, description: "Remove the matching entry if it exists"
  end

  input_object :delete_option_category_range_vote_params, description: OptionCategoryRangeVoteDocs.delete() do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :id, non_null(:id), description: @doc_map.strings.id
  end

  payload_object(:option_category_range_vote_payload, :option_category_range_vote)

  # provide an object that can be imported into the base mutations query.
  object :option_category_range_vote_mutations do
    field :upsert_option_category_range_vote, type: :option_category_range_vote_payload, description: OptionCategoryRangeVoteDocs.upsert() do
      arg :input, :upsert_option_category_range_vote_params
      resolve mutation_resolver(&OptionCategoryRangeVoteResolver.upsert/2)
      middleware &build_payload/2
    end

    field :delete_option_category_range_vote, type: :option_category_range_vote_payload, description: OptionCategoryRangeVoteDocs.delete() do
      arg :input, :delete_option_category_range_vote_params
      resolve mutation_resolver(&OptionCategoryRangeVoteResolver.delete/2)
      middleware &build_payload/2
    end
  end
end
