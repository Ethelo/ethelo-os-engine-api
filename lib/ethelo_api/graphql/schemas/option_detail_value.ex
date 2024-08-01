defmodule EtheloApi.Graphql.Schemas.OptionDetailValue do
  @moduledoc """
  Base access to OptionDetailValues
  """
  use Absinthe.Schema.Notation

  use DocsComposer, module: EtheloApi.Structure.Docs.OptionDetailValue
  alias EtheloApi.Graphql.Docs.OptionDetailValue, as: OptionDetailValueDocs
  alias EtheloApi.Graphql.Resolvers.OptionDetailValue, as: OptionDetailValueResolver

  import AbsintheErrorPayload.Payload
  import EtheloApi.Graphql.Middleware
  import Absinthe.Resolution.Helpers, only: [dataloader: 2]

  # queries

  @desc @doc_map.strings.option_detail_value
  object :option_detail_value do
    @desc @doc_map.strings.option_id
    field :option_id, non_null(:id)

    @desc @doc_map.strings.option_detail_id
    field :option_detail_id, non_null(:id)

    @desc @doc_map.strings.option_detail
    field :option_detail, :option_detail, resolve: dataloader(:repo, :option_detail)

    @desc @doc_map.strings.option
    field :option, :option, resolve: dataloader(:repo, :option)

    @desc @doc_map.strings.value
    field :value, :string
  end

  # mutations

  payload_object(:option_detail_value_payload, :option_detail_value)

  @desc OptionDetailValueDocs.upsert()
  input_object :upsert_option_detail_value_params do
    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc @doc_map.strings.option_id
    field :option_id, non_null(:id)
    @desc @doc_map.strings.option_detail_id
    field :option_detail_id, non_null(:id)
    @desc @doc_map.strings.value
    field :value, non_null(:string)
  end

  @desc OptionDetailValueDocs.delete()
  input_object :delete_option_detail_value_params do
    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)
    @desc @doc_map.strings.option_id
    field :option_id, non_null(:id)

    @desc @doc_map.strings.option_detail_id
    field :option_detail_id, non_null(:id)
  end

  object :option_detail_value_mutations do
    @desc OptionDetailValueDocs.upsert()
    field :upsert_option_detail_value, type: :option_detail_value_payload do
      arg(:input, :upsert_option_detail_value_params)
      middleware(&preload_decision/2)
      resolve(&OptionDetailValueResolver.upsert/2)
      middleware(&build_payload/2)
    end

    @desc OptionDetailValueDocs.delete()
    field :delete_option_detail_value, type: :option_detail_value_payload do
      arg(:input, :delete_option_detail_value_params)
      middleware(&preload_decision/2)
      resolve(&OptionDetailValueResolver.delete/2)
      middleware(&build_payload/2)
    end
  end
end
