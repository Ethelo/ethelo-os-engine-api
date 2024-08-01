defmodule EtheloApi.Graphql.Schemas.Option do
  @moduledoc """
  Base access to Options
  """

  use Absinthe.Schema.Notation
  use DocsComposer, module: EtheloApi.Structure.Docs.Option

  alias EtheloApi.Graphql.Docs.Option, as: OptionDocs
  alias EtheloApi.Graphql.Resolvers.Option, as: OptionResolver

  import AbsintheErrorPayload.Payload
  import EtheloApi.Graphql.Middleware
  import Absinthe.Resolution.Helpers, only: [dataloader: 2]

  @option_filter_strings EtheloApi.Structure.Docs.OptionFilter.strings()

  # queries

  @desc @doc_map.strings.option
  object :option do
    @desc @doc_map.strings.deleted
    field :deleted, non_null(:boolean)

    @desc @doc_map.strings.determinative
    field :determinative, non_null(:boolean)

    @desc @doc_map.strings.enabled
    field :enabled, non_null(:boolean)

    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.info
    field :info, :string

    @desc @doc_map.strings.inserted_at
    field :inserted_at, non_null(:datetime)

    @desc @doc_map.strings.results_title
    field :results_title, :string

    @desc @doc_map.strings.slug
    field :slug, :string

    @desc @doc_map.strings.sort
    field :sort, :integer

    @desc @doc_map.strings.title
    field :title, :string

    @desc @doc_map.strings.updated_at
    field :updated_at, non_null(:datetime)

    @desc @doc_map.strings.option_category_id
    field :option_category_id, :id

    field :detail_values, list_of(:option_detail_value),
      resolve: dataloader(:repo, :option_detail_values)

    field :option_category, non_null(:option_category),
      resolve: dataloader(:repo, :option_category)
  end

  object :option_list do
    field :options, list_of(:option) do
      @desc "Filter by Option id"
      arg(:id, :id)

      @desc "Filter by Option slug"
      arg(:slug, :string)

      @desc @option_filter_strings.option_filter
      arg(:option_filter_id, :id)

      @desc @doc_map.strings.option_category_id
      arg(:option_category_id, :id)

      @desc "Filter by enabled flag"
      arg(:enabled, :boolean)

      @desc "Filter by deleted flag"
      arg(:deleted, :boolean)
      resolve(&OptionResolver.list/3)
    end
  end

  # mutations
  payload_object(:option_payload, :option)

  input_object :option_params do
    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc @doc_map.strings.slug
    field :slug, :string
    @desc @doc_map.strings.info
    field :info, :string

    @desc @doc_map.strings.results_title
    field :results_title, :string

    @desc @doc_map.strings.determinative
    field :determinative, :boolean

    @desc @doc_map.strings.enabled
    field :enabled, :boolean

    @desc @doc_map.strings.deleted
    field :deleted, :boolean

    @desc @doc_map.strings.sort
    field :sort, :integer

    @desc @doc_map.strings.option_category_id
    field :option_category_id, :id
  end

  @desc OptionDocs.create()
  input_object :create_option_params do
    @desc @doc_map.strings.title
    field :title, non_null(:string)
    import_fields(:option_params)
  end

  @desc OptionDocs.update()
  input_object :update_option_params do
    @desc @doc_map.strings.id
    field :id, non_null(:id)
    @desc @doc_map.strings.title
    field :title, :string
    import_fields(:option_params)
  end

  @desc OptionDocs.delete()
  input_object :delete_option_params do
    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)
    @desc @doc_map.strings.id
    field :id, non_null(:id)
  end

  object :option_mutations do
    @desc OptionDocs.create()
    field :create_option, type: :option_payload do
      arg(:input, :create_option_params)
      middleware(&preload_decision/2)
      resolve(&OptionResolver.create/2)
      middleware(&build_payload/2)
    end

    @desc OptionDocs.update()
    field :update_option, type: :option_payload do
      arg(:input, :update_option_params)
      middleware(&preload_decision/2)
      resolve(&OptionResolver.update/2)
      middleware(&build_payload/2)
    end

    @desc OptionDocs.delete()
    field :delete_option, type: :option_payload do
      arg(:input, :delete_option_params)
      middleware(&preload_decision/2)
      resolve(&OptionResolver.delete/2)
      middleware(&build_payload/2)
    end
  end
end
