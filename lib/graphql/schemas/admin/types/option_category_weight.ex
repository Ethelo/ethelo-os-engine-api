defmodule GraphQL.EtheloApi.AdminSchema.OptionCategoryWeight do
  @moduledoc """
  Base access to OptionCategoryWeights
  """
  use DocsComposer, module: EtheloApi.Voting.Docs.OptionCategoryWeight
  alias GraphQL.EtheloApi.Docs.OptionCategoryWeight, as: OptionCategoryWeightDocs

  use Absinthe.Schema.Notation
  import GraphQL.EtheloApi.ResolveHelper
  import Kronky.Payload, only: [payload_object: 2, build_payload: 2]
  alias GraphQL.EtheloApi.Resolvers.OptionCategoryWeight, as: OptionCategoryWeightResolver

  # queries

  object :option_category_weight, description: @doc_map.strings.option_category_weight do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :decision_id, non_null(:id), description: @doc_map.strings.id
    field :option_category_id, non_null(:id), description: @doc_map.strings.id
    field :participant_id, non_null(:id), description: @doc_map.strings.id
    field :weighting, non_null(:integer), description: @doc_map.strings.weighting
    field :inserted_at, non_null(:datetime), description: @doc_map.strings.inserted_at
    field :updated_at, non_null(:datetime), description: @doc_map.strings.updated_at
  end

  object :option_category_weight_list do
    field :option_category_weights, list_of(:option_category_weight) do
      arg :id, :id, description: "Filter by CategoryWeight id"
      arg :option_category_id, :id, description: "Filter by OptionCategory id"
      arg :participant_id, :id, description: "Filter by Participant id"
    resolve &OptionCategoryWeightResolver.list/3
    end
  end

  input_object :option_category_weight_params do
    field :decision_id, non_null(:id), description: @doc_map.strings.id
    field :option_category_id, non_null(:id), description: @doc_map.strings.id
    field :participant_id, non_null(:id), description: @doc_map.strings.id
    field :weighting, non_null(:integer), description: @doc_map.strings.weighting
  end

  input_object :upsert_option_category_weight_params, description: OptionCategoryWeightDocs.create() do
    import_fields :option_category_weight_params
    field :delete, :boolean, description: "Remove the matching entry if it exists"
  end

  input_object :delete_option_category_weight_params, description: OptionCategoryWeightDocs.delete() do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :id, non_null(:id), description: @doc_map.strings.id
  end

  payload_object(:option_category_weight_payload, :option_category_weight)

  # provide an object that can be imported into the base mutations query.
  object :option_category_weight_mutations do
    field :upsert_option_category_weight, type: :option_category_weight_payload, description: OptionCategoryWeightDocs.create() do
      arg :input, :upsert_option_category_weight_params
      resolve mutation_resolver(&OptionCategoryWeightResolver.upsert/2)
      middleware &build_payload/2
    end

    field :delete_option_category_weight, type: :option_category_weight_payload, description: OptionCategoryWeightDocs.delete() do
      arg :input, :delete_option_category_weight_params
      resolve mutation_resolver(&OptionCategoryWeightResolver.delete/2)
      middleware &build_payload/2
    end
  end
end
