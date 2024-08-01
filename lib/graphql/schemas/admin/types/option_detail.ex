defmodule GraphQL.EtheloApi.AdminSchema.OptionDetail do
  @moduledoc """
  Base access to OptionDetails
  """
  use DocsComposer, module: EtheloApi.Structure.Docs.OptionDetail
  alias GraphQL.EtheloApi.Docs.OptionDetail, as: OptionDetailDocs


  use Absinthe.Schema.Notation
  import GraphQL.EtheloApi.ResolveHelper
  import Kronky.Payload, only: [payload_object: 2, build_payload: 2]
  alias GraphQL.EtheloApi.Resolvers.OptionDetail, as: OptionDetailResolver

  # hard coding options so we can apply descriptions properly.
  # We could convert to a macro as per
  # https://gist.github.com/bruce/e5307411f757c6ac585005d7f8f37e68
  # at some future date
  enum :detail_format, description: @doc_map.strings.format_start do
    value :string, description: @doc_map.strings.format_string
    value :float, description: @doc_map.strings.format_float
    value :integer, description: @doc_map.strings.format_integer
    value :boolean, description: @doc_map.strings.format_boolean
    value :datetime, description: @doc_map.strings.format_datetime
  end

  # queries

  object :option_detail do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :title, non_null(:string), description: @doc_map.strings.title
    field :slug, non_null(:string), description: @doc_map.strings.slug
    field :format, non_null(:detail_format), description: @doc_map.strings.format
    field :input_hint, :string, description: @doc_map.strings.input_hint
    field :display_hint, :string, description: @doc_map.strings.display_hint
    field :public, :boolean, description: @doc_map.strings.public
    field :sort, :integer, description: @doc_map.strings.sort
    field :inserted_at, non_null(:datetime), description: @doc_map.strings.inserted_at
    field :updated_at, non_null(:datetime), description: @doc_map.strings.updated_at
    field :option_values, list_of(:option_detail_value) do
      resolve &OptionDetailResolver.batch_option_values/3
    end
  end

  object :option_detail_list do
    field :option_details, list_of(:option_detail) do
      arg :id, :id, description: "Filter by OptionDetail id"
      arg :slug, :string, description: "Filter by OptionDetail slug"
      resolve &OptionDetailResolver.list/3
    end
  end

  input_object :option_detail_params do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :public, :boolean, description: @doc_map.strings.public
    field :display_hint, :string, description: @doc_map.strings.display_hint
    field :input_hint, :string, description: @doc_map.strings.input_hint
    field :slug, :string, description: @doc_map.strings.slug
    field :sort, :integer, description: @doc_map.strings.sort
  end

  # mutations
  input_object :create_option_detail_params, description: OptionDetailDocs.create() do
    field :title, non_null(:string), description: @doc_map.strings.title
    field :format, non_null(:detail_format), description: @doc_map.strings.format
    import_fields :option_detail_params
  end
  input_object :update_option_detail_params, description: OptionDetailDocs.update() do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :format, :detail_format, description: @doc_map.strings.format
    field :title, :string, description: @doc_map.strings.title
    import_fields :option_detail_params
  end

  input_object :delete_option_detail_params, description: OptionDetailDocs.delete() do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :id, non_null(:id), description: @doc_map.strings.id
  end

  payload_object(:option_detail_payload, :option_detail)

  # provide an object that can be imported into the base mutations query.
  object :option_detail_mutations do
    field :create_option_detail, type: :option_detail_payload, description: OptionDetailDocs.create() do
      arg :input, :create_option_detail_params
      resolve mutation_resolver(&OptionDetailResolver.create/2)
      middleware &build_payload/2
    end

    field :update_option_detail, type: :option_detail_payload, description: OptionDetailDocs.update() do
      arg :input, :update_option_detail_params
      resolve mutation_resolver(&OptionDetailResolver.update/2)
      middleware &build_payload/2
    end

    field :delete_option_detail, type: :option_detail_payload, description: OptionDetailDocs.delete() do
      arg :input, :delete_option_detail_params
      resolve mutation_resolver(&OptionDetailResolver.delete/2)
      middleware &build_payload/2
    end
  end
end
