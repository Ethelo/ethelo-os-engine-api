defmodule EtheloApi.Graphql.Schemas.OptionCategory do
  @moduledoc """
  Base access to OptionCategories
  """

  use Absinthe.Schema.Notation
  use DocsComposer, module: EtheloApi.Structure.Docs.OptionCategory

  alias EtheloApi.Graphql.Docs.OptionCategory, as: OptionCategoryDocs
  alias EtheloApi.Graphql.Resolvers.OptionCategory, as: OptionCategoryResolver

  import AbsintheErrorPayload.Payload
  import EtheloApi.Graphql.Middleware
  import Absinthe.Resolution.Helpers, only: [dataloader: 2]

  # hard coding so we can apply descriptions properly.
  # We could convert to a macro as per
  # https://gist.github.com/bruce/e5307411f757c6ac585005d7f8f37e68
  # at some future date
  @desc @doc_map.strings.scoring_start
  enum :scoring_mode do
    @desc @doc_map.strings.scoring_none
    value(:none)

    @desc @doc_map.strings.scoring_rectangle
    value(:rectangle)

    @desc @doc_map.strings.scoring_triangle
    value(:triangle)
  end

  @desc @doc_map.strings.voting_start
  enum :voting_style do
    @desc @doc_map.strings.voting_one
    value(:one)
    @desc @doc_map.strings.voting_range
    value(:range)
  end

  # queries
  object :option_category do
    @desc @doc_map.strings.apply_participant_weights
    field :apply_participant_weights, :boolean

    @desc @doc_map.strings.budget_percent
    field :budget_percent, :float

    @desc @doc_map.strings.default_high_option
    field :default_high_option, :option, resolve: dataloader(:repo, :default_high_option)

    @desc @doc_map.strings.default_high_option_id
    field :default_high_option_id, :id

    @desc @doc_map.strings.default_low_option
    field :default_low_option, :option, resolve: dataloader(:repo, :default_low_option)

    @desc @doc_map.strings.default_low_option_id
    field :default_low_option_id, :id

    @desc @doc_map.strings.deleted
    field :deleted, non_null(:boolean)

    @desc @doc_map.strings.flat_fee
    field :flat_fee, :float

    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.info
    field :info, :string

    @desc @doc_map.strings.inserted_at
    field :inserted_at, non_null(:datetime)

    @desc @doc_map.strings.keywords
    field :keywords, :string

    @desc @doc_map.strings.options
    field :options, list_of(:option), resolve: dataloader(:repo, :options)

    @desc @doc_map.strings.primary_detail
    field :primary_detail, :option_detail, resolve: dataloader(:repo, :primary_detail)

    @desc @doc_map.strings.primary_detail_id
    field :primary_detail_id, :id

    @desc @doc_map.strings.quadratic
    field :quadratic, :boolean

    @desc @doc_map.strings.results_title
    field :results_title, :string

    @desc @doc_map.strings.scoring_mode
    field :scoring_mode, non_null(:scoring_mode)

    @desc @doc_map.strings.slug
    field :slug, :string

    @desc @doc_map.strings.sort
    field :sort, :integer

    @desc @doc_map.strings.title
    field :title, :string

    @desc @doc_map.strings.triangle_base
    field :triangle_base, :integer

    @desc @doc_map.strings.updated_at
    field :updated_at, non_null(:datetime)

    @desc @doc_map.strings.vote_on_percent
    field :vote_on_percent, :boolean

    @desc @doc_map.strings.voting_style
    field :voting_style, non_null(:voting_style)

    @desc @doc_map.strings.weighting
    field :weighting, non_null(:integer)

    @doc_map.strings.xor
    field :xor, :boolean
  end

  object :option_category_list do
    field :option_categories, list_of(:option_category) do
      @desc "Filter by OptionCategory id"
      arg(:id, :id)

      @desc "Filter by deleted flag"
      arg(:deleted, :boolean)

      @desc "Filter by OptionCategory slug"
      arg(:slug, :string)

      resolve(&OptionCategoryResolver.list/3)
    end
  end

  # mutations
  payload_object(:option_category_payload, :option_category)

  input_object :option_category_params do
    @desc @doc_map.strings.apply_participant_weights
    field :apply_participant_weights, :boolean

    @desc @doc_map.strings.budget_percent
    field :budget_percent, :float

    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc @doc_map.strings.default_high_option_id
    field :default_high_option_id, :id

    @desc @doc_map.strings.default_low_option_id
    field :default_low_option_id, :id

    @desc @doc_map.strings.deleted
    field :deleted, :boolean

    @desc @doc_map.strings.flat_fee
    field :flat_fee, :float

    @desc @doc_map.strings.info
    field :info, :string

    @desc @doc_map.strings.keywords
    field :keywords, :string

    @desc @doc_map.strings.primary_detail_id
    field :primary_detail_id, :id

    @desc @doc_map.strings.quadratic
    field :quadratic, :boolean

    @desc @doc_map.strings.results_title
    field :results_title, :string

    @desc @doc_map.strings.scoring_mode
    field :scoring_mode, :scoring_mode

    @desc @doc_map.strings.slug
    field :slug, :string

    @desc @doc_map.strings.sort
    field :sort, :integer

    @desc @doc_map.strings.triangle_base
    field :triangle_base, :integer

    @desc @doc_map.strings.vote_on_percent
    field :vote_on_percent, :boolean

    @desc @doc_map.strings.voting_style
    field :voting_style, :voting_style

    @desc @doc_map.strings.weighting
    field :weighting, :integer

    @desc @doc_map.strings.xor
    field :xor, :boolean
  end

  @desc OptionCategoryDocs.create()
  input_object :create_option_category_params do
    @desc @doc_map.strings.title
    field :title, non_null(:string)
    import_fields(:option_category_params)
  end

  @desc OptionCategoryDocs.update()
  input_object :update_option_category_params do
    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.title
    field :title, :string

    import_fields(:option_category_params)
  end

  @desc OptionCategoryDocs.delete()
  input_object :delete_option_category_params do
    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc @doc_map.strings.id
    field :id, non_null(:id)
  end

  object :option_category_mutations do
    @desc OptionCategoryDocs.create()
    field :create_option_category, type: :option_category_payload do
      arg(:input, :create_option_category_params)
      middleware(&preload_decision/2)
      resolve(&OptionCategoryResolver.create/2)
      middleware(&build_payload/2)
    end

    @desc OptionCategoryDocs.update()
    field :update_option_category, type: :option_category_payload do
      arg(:input, :update_option_category_params)
      middleware(&preload_decision/2)
      resolve(&OptionCategoryResolver.update/2)
      middleware(&build_payload/2)
    end

    @desc OptionCategoryDocs.delete()
    field :delete_option_category, type: :option_category_payload do
      arg(:input, :delete_option_category_params)
      middleware(&preload_decision/2)
      resolve(&OptionCategoryResolver.delete/2)
      middleware(&build_payload/2)
    end
  end
end
