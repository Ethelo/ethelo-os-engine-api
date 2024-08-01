defmodule EtheloApi.Graphql.Schemas.OptionCategoryBinVote do
  @moduledoc """
  Base access to OptionCategoryBinVotes
  """

  use Absinthe.Schema.Notation
  use DocsComposer, module: EtheloApi.Voting.Docs.OptionCategoryBinVote
  alias EtheloApi.Graphql.Docs.OptionCategoryBinVote, as: OptionCategoryBinVoteDocs
  alias EtheloApi.Graphql.Resolvers.OptionCategoryBinVote, as: OptionCategoryBinVoteResolver
  import AbsintheErrorPayload.Payload
  import EtheloApi.Graphql.Middleware

  # queries

  @desc @doc_map.strings.option_category_bin_vote
  object :option_category_bin_vote do
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

    @desc @doc_map.strings.option_category_id
    field :option_category_id, non_null(:id)

    @desc @doc_map.strings.participant_id
    field :participant_id, non_null(:id)

    @desc @doc_map.strings.updated_at
    field :updated_at, non_null(:datetime)
  end

  object :option_category_bin_vote_list do
    field :option_category_bin_votes, list_of(:option_category_bin_vote) do
      @desc "Filter by Criteria id"
      arg(:criteria_id, :id)

      @desc "Filter by OptionCategoryBinVote id"
      arg(:id, :id)
      @desc "Filter by OptionCategory id"
      arg(:option_category_id, :id)

      @desc "Filter by Participant id"
      arg(:participant_id, :id)

      resolve(&OptionCategoryBinVoteResolver.list/3)
    end
  end

  object :option_category_bin_vote_activity do
    field :option_category_bin_vote_activity, list_of(:date_count) do
      @desc "The date interval to group by to retrieve: 'year', 'month', 'week', 'day'"
      arg(:interval, :string)

      resolve(&OptionCategoryBinVoteResolver.activity/3)
    end
  end

  # mutations
  payload_object(:option_category_bin_vote_payload, :option_category_bin_vote)

  input_object :option_category_bin_vote_params do
    @desc @doc_map.strings.bin
    field :bin, non_null(:integer)

    @desc @doc_map.strings.criteria_id
    field :criteria_id, non_null(:id)

    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc "Remove the matching entry if it exists"
    field :delete, :boolean

    @desc @doc_map.strings.option_category_id
    field :option_category_id, non_null(:id)

    @desc @doc_map.strings.participant_id
    field :participant_id, non_null(:id)
  end

  @desc OptionCategoryBinVoteDocs.upsert()
  input_object :upsert_option_category_bin_vote_params do
    import_fields(:option_category_bin_vote_params)
  end

  object :option_category_bin_vote_mutations do
    @desc OptionCategoryBinVoteDocs.upsert()
    field :upsert_option_category_bin_vote, type: :option_category_bin_vote_payload do
      arg(:input, :upsert_option_category_bin_vote_params)
      middleware(&preload_decision/2)
      resolve(&OptionCategoryBinVoteResolver.upsert/2)
      middleware(&build_payload/2)
    end
  end
end
