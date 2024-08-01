defmodule GraphQL.EtheloApi.AdminSchema.OptionDetailValue do
  @moduledoc """
  Base access to OptionDetailValues
  """
  use DocsComposer, module: EtheloApi.Structure.Docs.OptionDetailValue
  alias GraphQL.EtheloApi.Docs.OptionDetailValue, as: OptionDetailValueDocs

  use Absinthe.Schema.Notation
  import GraphQL.EtheloApi.ResolveHelper
  import Kronky.Payload, only: [payload_object: 2, build_payload: 2]
  alias GraphQL.EtheloApi.Resolvers.OptionDetailValue, as: OptionDetailValueResolver
  alias GraphQL.EtheloApi.Resolvers.Option, as: OptionResolver
  alias GraphQL.EtheloApi.Resolvers.OptionDetail, as: OptionDetailResolver

  object :option_detail_value, description: @doc_map.strings.option_detail_value do
    field :option_detail, :option_detail,
      description: @doc_map.strings.option_detail,
      resolve: &OptionDetailResolver.batch_load_belongs_to/3
    field :option, :option,
      description: @doc_map.strings.option,
      resolve: &OptionResolver.batch_load_belongs_to/3
    field :value, :string, description: @doc_map.strings.value
  end

  # mutations
  input_object :update_option_detail_value_params, description: OptionDetailValueDocs.create_option_detail_value() do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :option_id, non_null(:id), description: @doc_map.strings.option_id
    field :option_detail_id, non_null(:id), description: @doc_map.strings.option_detail_id
    field :value, non_null(:string), description: @doc_map.strings.value
    import_fields :option_detail_value_params
  end

  input_object :delete_option_detail_value_params, description: OptionDetailValueDocs.delete_option_detail_value() do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :option_id, non_null(:id), description: @doc_map.strings.option_id
    field :option_detail_id, non_null(:id), description: @doc_map.strings.option_detail_id
  end

  payload_object(:option_detail_value_payload, :option_detail_value)

  # provide an object that can be imported into the base mutations query.
  object :option_detail_value_mutations do
    field :update_option_detail_value, type: :option_detail_value_payload, description: OptionDetailValueDocs.update_option_detail_value() do
      arg :input, :update_option_detail_value_params
      resolve mutation_resolver(&OptionDetailValueResolver.update/2)
      middleware &build_payload/2
    end

    field :delete_option_detail_value, type: :option_detail_value_payload, description: OptionDetailValueDocs.delete_option_detail_value() do
      arg :input, :delete_option_detail_value_params
      resolve mutation_resolver(&OptionDetailValueResolver.delete/2)
      middleware &build_payload/2
    end
  end
end
