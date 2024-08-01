defmodule EtheloApi.Graphql.Schemas.OptionFilter do
  @moduledoc """
  Base access to OptionFilters
  """

  use Absinthe.Schema.Notation
  use DocsComposer, module: EtheloApi.Structure.Docs.OptionFilter

  alias EtheloApi.Graphql.Docs.OptionFilter, as: OptionFilterDocs
  alias EtheloApi.Graphql.Resolvers.OptionFilter, as: OptionFilterResolver

  import AbsintheErrorPayload.Payload
  import Absinthe.Resolution.Helpers, only: [dataloader: 2]
  import EtheloApi.Graphql.Middleware

  @desc @doc_map.strings.match_mode
  enum :detail_filter_match_modes do
    @desc @doc_map.strings.match_mode_equals
    value(:equals, as: "equals")
  end

  @desc @doc_map.strings.match_mode
  enum :category_filter_match_modes do
    @desc @doc_map.strings.match_mode_in_category
    value(:in_category, as: "in_category")

    @desc @doc_map.strings.match_mode_not_in_category
    value(:not_in_category, as: "not_in_category")
  end

  @desc @doc_map.strings.match_mode
  enum :option_filter_match_modes do
    @desc @doc_map.strings.match_mode_all_options
    value(:all_options, as: "all_options")

    @desc @doc_map.strings.match_mode_in_category
    value(:in_category, as: "in_category")

    @desc @doc_map.strings.match_mode_not_in_category
    value(:not_in_category, as: "not_in_category")

    @desc @doc_map.strings.match_mode_equals
    value(:equals, as: "equals")
  end

  # queries
  object :option_filter do
    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.title
    field :title, non_null(:string)

    @desc @doc_map.strings.slug
    field :slug, non_null(:string)

    @desc @doc_map.strings.match_value
    field :match_value, :string

    @desc @doc_map.strings.match_mode
    field :match_mode, :option_filter_match_modes

    @desc @doc_map.strings.inserted_at
    field :inserted_at, non_null(:datetime)

    @desc @doc_map.strings.updated_at
    field :updated_at, non_null(:datetime)

    @desc @doc_map.strings.option_ids
    field :option_ids,
          list_of(:id),
          resolve:
            dataloader(:option_filters, fn option_filter, args, _resolution ->
              args = Map.put(args, :decision_id, option_filter.decision_id)
              {:option_ids_by_filter, args}
            end)

    @desc @doc_map.strings.options
    field :options,
          list_of(:option),
          resolve:
            dataloader(:option_filters, fn option_filter, args, _resolution ->
              args = Map.put(args, :decision_id, option_filter.decision_id)
              {:options_by_filter, args}
            end)

    @desc @doc_map.strings.option_detail_id
    field :option_detail_id, :id

    @desc @doc_map.strings.option_detail
    field :option_detail, :option_detail, resolve: dataloader(:repo, :option_detail)

    @desc @doc_map.strings.option_category_id
    field :option_category_id, :id

    @desc @doc_map.strings.option_category
    field :option_category, :option_category, resolve: dataloader(:repo, :option_category)
  end

  object :option_filter_suggestion do
    @desc @doc_map.strings.title
    field :title, non_null(:string)

    @desc @doc_map.strings.slug
    field :slug, :string

    @desc @doc_map.strings.match_value
    field :match_value, :string

    @desc @doc_map.strings.match_mode
    field :match_mode, :option_filter_match_modes

    @desc @doc_map.strings.option_detail_id
    field :option_detail_id, :id

    @desc @doc_map.strings.option_category_id
    field :option_category_id, :id
  end

  object :option_filter_list do
    field :option_filters, list_of(:option_filter) do
      @desc "Filter by OptionFilter id"
      arg(:id, :id)

      @desc "Filter by OptionFilter slug"
      arg(:slug, :string)

      @desc @doc_map.strings.option_detail_id
      arg(:option_detail_id, :id)

      @desc @doc_map.strings.option_category_id
      arg(:option_category_id, :id)

      resolve(&OptionFilterResolver.list/3)
    end
  end

  # mutations

  payload_object(:option_filter_payload, :option_filter)

  @desc OptionFilterDocs.create_option_detail_filter()

  input_object :option_filter_params do
    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc @doc_map.strings.slug
    field :slug, :string

    @desc @doc_map.strings.match_value
    field :match_value, :string
  end

  @desc OptionFilterDocs.create_option_detail_filter()
  input_object :create_option_detail_filter_params do
    @desc @doc_map.strings.title
    field :title, non_null(:string)

    @desc @doc_map.strings.option_detail_id
    field :option_detail_id, non_null(:id)

    field :match_mode, non_null(:detail_filter_match_modes),
      description: @doc_map.strings.match_mode

    import_fields(:option_filter_params)
  end

  @desc OptionFilterDocs.update_option_detail_filter()
  input_object :update_option_detail_filter_params do
    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.title
    field :title, :string

    @desc @doc_map.strings.option_detail_id
    field :option_detail_id, :id

    @desc @doc_map.strings.match_mode
    field :match_mode, :detail_filter_match_modes

    import_fields(:option_filter_params)
  end

  @desc OptionFilterDocs.create_option_category_filter()
  input_object :create_option_category_filter_params do
    @desc @doc_map.strings.title
    field :title, non_null(:string)

    @desc @doc_map.strings.option_category_id
    field :option_category_id, non_null(:id)

    @desc @doc_map.strings.match_mode
    field :match_mode, non_null(:category_filter_match_modes)

    import_fields(:option_filter_params)
  end

  @desc OptionFilterDocs.update_option_category_filter()
  input_object :update_option_category_filter_params do
    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.title
    field :title, :string

    @desc @doc_map.strings.option_category_id
    field :option_category_id, :id

    @desc @doc_map.strings.match_mode
    field :match_mode, :category_filter_match_modes

    import_fields(:option_filter_params)
  end

  @desc OptionFilterDocs.delete()
  input_object :delete_option_filter_params do
    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc @doc_map.strings.id
    field :id, non_null(:id)
  end

  object :option_filter_mutations do
    @desc OptionFilterDocs.create_option_detail_filter()
    field :create_option_detail_filter, type: :option_filter_payload do
      arg(:input, :create_option_detail_filter_params)
      middleware(&preload_decision/2)
      resolve(&OptionFilterResolver.create/2)
      middleware(&build_payload/2)
    end

    @desc OptionFilterDocs.update_option_detail_filter()
    field :update_option_detail_filter, type: :option_filter_payload do
      arg(:input, :update_option_detail_filter_params)
      middleware(&preload_decision/2)
      resolve(&OptionFilterResolver.update/2)
      middleware(&build_payload/2)
    end

    @desc OptionFilterDocs.create_option_category_filter()
    field :create_option_category_filter, type: :option_filter_payload do
      arg(:input, :create_option_category_filter_params)
      middleware(&preload_decision/2)
      resolve(&OptionFilterResolver.create/2)
      middleware(&build_payload/2)
    end

    @desc OptionFilterDocs.update_option_category_filter()
    field :update_option_category_filter, type: :option_filter_payload do
      arg(:input, :update_option_category_filter_params)
      middleware(&preload_decision/2)
      resolve(&OptionFilterResolver.update/2)
      middleware(&build_payload/2)
    end

    @desc OptionFilterDocs.delete()
    field :delete_option_filter, type: :option_filter_payload do
      arg(:input, :delete_option_filter_params)
      middleware(&preload_decision/2)
      resolve(&OptionFilterResolver.delete/2)
      middleware(&build_payload/2)
    end
  end
end
