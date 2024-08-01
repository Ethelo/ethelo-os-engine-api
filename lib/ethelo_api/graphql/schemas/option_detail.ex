defmodule EtheloApi.Graphql.Schemas.OptionDetail do
  @moduledoc """
  Base access to OptionDetails
  """
  use Absinthe.Schema.Notation
  use DocsComposer, module: EtheloApi.Structure.Docs.OptionDetail

  alias EtheloApi.Graphql.Docs.OptionDetail, as: OptionDetailDocs
  alias EtheloApi.Graphql.Resolvers.OptionDetail, as: OptionDetailResolver

  import AbsintheErrorPayload.Payload
  import EtheloApi.Graphql.Middleware
  import Absinthe.Resolution.Helpers, only: [dataloader: 2]

  # hard coding so we can apply descriptions properly.
  # We could convert to a macro as per
  # https://gist.github.com/bruce/e5307411f757c6ac585005d7f8f37e68
  # at some future date
  @desc @doc_map.strings.format_start
  enum :detail_format do
    @desc @doc_map.strings.format_string
    value(:string)
    @desc @doc_map.strings.format_float
    value(:float)
    @desc @doc_map.strings.format_integer
    value(:integer)
    @desc @doc_map.strings.format_boolean
    value(:boolean)
    @desc @doc_map.strings.format_datetime
    value(:datetime)
  end

  # queries

  object :option_detail do
    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.title
    field :title, non_null(:string)

    @desc @doc_map.strings.slug
    field :slug, non_null(:string)

    @desc @doc_map.strings.format
    field :format, non_null(:detail_format)

    @desc @doc_map.strings.input_hint
    field :input_hint, :string

    @desc @doc_map.strings.display_hint
    field :display_hint, :string

    @desc @doc_map.strings.public
    field :public, :boolean

    @desc @doc_map.strings.sort
    field :sort, :integer

    @desc @doc_map.strings.inserted_at
    field :inserted_at, non_null(:datetime)

    @desc @doc_map.strings.updated_at
    field :updated_at, non_null(:datetime)

    field :option_values,
          list_of(:option_detail_value),
          resolve: dataloader(:repo, :option_detail_values)
  end

  object :option_detail_list do
    field :option_details, list_of(:option_detail) do
      @desc "Filter by OptionDetail id"
      arg(:id, :id)

      @desc "Filter by OptionDetail slug"
      arg(:slug, :string)

      resolve(&OptionDetailResolver.list/3)
    end
  end

  # mutations
  payload_object(:option_detail_payload, :option_detail)

  input_object :option_detail_params do
    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc @doc_map.strings.public
    field :public, :boolean
    @desc @doc_map.strings.display_hint
    field :display_hint, :string
    @desc @doc_map.strings.input_hint
    field :input_hint, :string
    @desc @doc_map.strings.slug
    field :slug, :string
    @desc @doc_map.strings.sort
    field :sort, :integer
  end

  @desc OptionDetailDocs.create()
  input_object :create_option_detail_params do
    @desc @doc_map.strings.title
    field :title, non_null(:string)
    @desc @doc_map.strings.format
    field :format, non_null(:detail_format)
    import_fields(:option_detail_params)
  end

  @desc OptionDetailDocs.update()
  input_object :update_option_detail_params do
    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.format
    field :format, :detail_format

    @desc @doc_map.strings.title
    field :title, :string

    import_fields(:option_detail_params)
  end

  @desc OptionDetailDocs.delete()
  input_object :delete_option_detail_params do
    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)
    @desc @doc_map.strings.id
    field :id, non_null(:id)
  end

  object :option_detail_mutations do
    @desc OptionDetailDocs.create()
    field :create_option_detail, type: :option_detail_payload do
      arg(:input, :create_option_detail_params)
      middleware(&preload_decision/2)
      resolve(&OptionDetailResolver.create/2)
      middleware(&build_payload/2)
    end

    @desc OptionDetailDocs.update()
    field :update_option_detail, type: :option_detail_payload do
      arg(:input, :update_option_detail_params)
      middleware(&preload_decision/2)
      resolve(&OptionDetailResolver.update/2)
      middleware(&build_payload/2)
    end

    @desc OptionDetailDocs.delete()
    field :delete_option_detail, type: :option_detail_payload do
      arg(:input, :delete_option_detail_params)
      middleware(&preload_decision/2)
      resolve(&OptionDetailResolver.delete/2)
      middleware(&build_payload/2)
    end
  end
end
