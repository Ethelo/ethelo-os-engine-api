defmodule GraphQL.EtheloApi.AdminSchema.OptionCategory do
  @moduledoc """
  Base access to OptionCategories
  """
  use DocsComposer, module: EtheloApi.Structure.Docs.OptionCategory
  alias GraphQL.EtheloApi.Docs.OptionCategory, as: OptionCategoryDocs

  use Absinthe.Schema.Notation
  import GraphQL.EtheloApi.ResolveHelper
  import Kronky.Payload, only: [payload_object: 2, build_payload: 2]
  alias GraphQL.EtheloApi.Resolvers.OptionCategory, as: OptionCategoryResolver
  alias GraphQL.EtheloApi.Resolvers.OptionDetail, as: OptionDetailResolver
  alias GraphQL.EtheloApi.Resolvers.Option, as: OptionResolver

  # hard coding options so we can apply descriptions properly.
  # We could convert to a macro as per
  # https://gist.github.com/bruce/e5307411f757c6ac585005d7f8f37e68
  # at some future date
  enum :scoring_mode, description: @doc_map.strings.scoring_start do
    value :none, description: @doc_map.strings.scoring_none
    value :triangle, description: @doc_map.strings.scoring_triangle
    value :rectangle, description: @doc_map.strings.scoring_rectangle
  end

  enum :voting_style, description: @doc_map.strings.voting_start do
    value :one, description: @doc_map.strings.voting_one
    value :range, description: @doc_map.strings.voting_range
  end

  # queries
  object :option_category do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :title, non_null(:string), description: @doc_map.strings.title
    field :results_title, :string, description: @doc_map.strings.results_title
    field :slug, non_null(:string), description: @doc_map.strings.slug
    field :info, :string, description: @doc_map.strings.info
    field :keywords, :string, description: @doc_map.strings.keywords
    field :deleted, non_null(:boolean), description: @doc_map.strings.deleted
    field :sort, :integer, description: @doc_map.strings.sort
    field :options, list_of(:option), description: @doc_map.strings.options, resolve: &OptionCategoryResolver.batch_load_options/3
    field :weighting, non_null(:integer), description: @doc_map.strings.weighting
    field :xor, :boolean, description: @doc_map.strings.xor
    field :apply_participant_weights, :boolean, description: @doc_map.strings.apply_participant_weights
    field :budget_percent, :float, description: @doc_map.strings.budget_percent
    field :flat_fee, :float, description: @doc_map.strings.flat_fee
    field :vote_on_percent, :boolean, description: @doc_map.strings.vote_on_percent
    field :quadratic, :boolean, description: @doc_map.strings.quadratic
    field :scoring_mode, non_null(:scoring_mode), description: @doc_map.strings.scoring_mode
    field :voting_style, non_null(:voting_style), description: @doc_map.strings.voting_style
    field :triangle_base, :integer, description: @doc_map.strings.triangle_base
    field :primary_detail_id, :id
    field :primary_detail, :option_detail,
      description: @doc_map.strings.primary_detail,
      resolve: &OptionDetailResolver.batch_load_belongs_to/3

    field :default_low_option_id, :id
    field :default_low_option, :option,
      description: @doc_map.strings.default_low_option_id,
      resolve: &OptionResolver.batch_load_belongs_to/3

    field :default_high_option_id, :id
    field :default_high_option, :option,
      description: @doc_map.strings.default_high_option_id,
      resolve: &OptionResolver.batch_load_belongs_to/3

    field :inserted_at, non_null(:datetime), description: @doc_map.strings.inserted_at
    field :updated_at, non_null(:datetime), description: @doc_map.strings.updated_at
  end

  object :option_category_list do
    field :option_categories, list_of(:option_category) do
      arg :id, :id, description: "Filter by OptionCategory id"
      arg :slug, :string, description: "Filter by OptionCategory slug"
      arg :deleted, :boolean, description: "Filter by deleted flag"
      resolve &OptionCategoryResolver.list/3
    end
  end

  input_object :option_category_params do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :results_title, :string, description: @doc_map.strings.results_title
    field :slug, :string, description: @doc_map.strings.slug
    field :info, :string, description: @doc_map.strings.info
    field :keywords, :string, description: @doc_map.strings.keywords
    field :weighting, :integer, description: @doc_map.strings.weighting
    field :budget_percent, :float, description: @doc_map.strings.budget_percent
    field :vote_on_percent, :boolean, description: @doc_map.strings.vote_on_percent
    field :quadratic, :boolean, description: @doc_map.strings.quadratic
    field :flat_fee, :float, description: @doc_map.strings.flat_fee
    field :deleted, :boolean, description: @doc_map.strings.deleted
    field :xor, :boolean, description: @doc_map.strings.xor
    field :apply_participant_weights, :boolean, description: @doc_map.strings.apply_participant_weights
    field :scoring_mode, :scoring_mode, description: @doc_map.strings.scoring_mode
    field :voting_style, :voting_style, description: @doc_map.strings.voting_style
    field :triangle_base, :integer, description: @doc_map.strings.triangle_base
    field :primary_detail_id, :id, description: @doc_map.strings.primary_detail_id
    field :default_low_option_id, :id, description: @doc_map.strings.default_low_option_id
    field :default_high_option_id, :id, description: @doc_map.strings.default_high_option_id
    field :sort, :integer, description: @doc_map.strings.sort
  end

  # mutations
  input_object :create_option_category_params, description: OptionCategoryDocs.create() do
    field :title, non_null(:string), description: @doc_map.strings.title
    import_fields :option_category_params
  end

  input_object :update_option_category_params, description: OptionCategoryDocs.update() do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :title, :string, description: @doc_map.strings.title
    import_fields :option_category_params
  end

  input_object :delete_option_category_params, description: OptionCategoryDocs.delete() do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :id, non_null(:id), description: @doc_map.strings.id
  end

  payload_object(:option_category_payload, :option_category)

  # provide an object that can be imported into the base mutations query.
  object :option_category_mutations do

    field :create_option_category, type: :option_category_payload, description: OptionCategoryDocs.create() do
      arg :input, :create_option_category_params
      resolve mutation_resolver(&OptionCategoryResolver.create/2)
      middleware &build_payload/2
    end

    field :update_option_category, type: :option_category_payload, description: OptionCategoryDocs.update() do
      arg :input, :update_option_category_params
      resolve mutation_resolver(&OptionCategoryResolver.update/2)
      middleware &build_payload/2
    end

    field :delete_option_category, type: :option_category_payload, description: OptionCategoryDocs.delete() do
      arg :input, :delete_option_category_params
      resolve mutation_resolver(&OptionCategoryResolver.delete/2)
      middleware &build_payload/2
    end
  end

end
