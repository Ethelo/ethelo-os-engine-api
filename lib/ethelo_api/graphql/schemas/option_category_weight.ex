defmodule EtheloApi.Graphql.Schemas.OptionCategoryWeight do
  @moduledoc """
  Base access to OptionCategoryWeights
  """

  use Absinthe.Schema.Notation
  use DocsComposer, module: EtheloApi.Voting.Docs.OptionCategoryWeight
  alias EtheloApi.Graphql.Docs.OptionCategoryWeight, as: OptionCategoryWeightDocs
  alias EtheloApi.Graphql.Resolvers.OptionCategoryWeight, as: OptionCategoryWeightResolver
  import AbsintheErrorPayload.Payload
  import EtheloApi.Graphql.Middleware

  # queries

  @desc @doc_map.strings.option_category_weight
  object :option_category_weight do
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

    @desc @doc_map.strings.weighting
    field :weighting, non_null(:integer)
  end

  object :option_category_weight_list do
    field :option_category_weights, list_of(:option_category_weight) do
      @desc "Filter by CategoryWeight id"
      arg(:id, :id)

      @desc "Filter by OptionCategory id"
      arg(:option_category_id, :id)

      @desc "Filter by Participant id"
      arg(:participant_id, :id)

      resolve(&OptionCategoryWeightResolver.list/3)
    end
  end

  # mutations
  payload_object(:option_category_weight_payload, :option_category_weight)

  input_object :option_category_weight_params do
    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc "Remove the matching entry if it exists"
    field :delete, :boolean

    @desc @doc_map.strings.option_category_id
    field :option_category_id, non_null(:id)

    @desc @doc_map.strings.participant_id
    field :participant_id, non_null(:id)

    @desc @doc_map.strings.weighting
    field :weighting, non_null(:integer)
  end

  @desc OptionCategoryWeightDocs.upsert()
  input_object :upsert_option_category_weight_params do
    import_fields(:option_category_weight_params)
  end

  object :option_category_weight_mutations do
    @desc OptionCategoryWeightDocs.upsert()
    field :upsert_option_category_weight, type: :option_category_weight_payload do
      arg(:input, :upsert_option_category_weight_params)
      middleware(&preload_decision/2)
      resolve(&OptionCategoryWeightResolver.upsert/2)
      middleware(&build_payload/2)
    end
  end
end
