defmodule EtheloApi.Structure.OptionCategory do
  use DocsComposer, module: EtheloApi.Structure.Docs.OptionCategory

  @moduledoc """
  #{@doc_map.strings.option_category}

  ## Fields
  #{schema_fields(@doc_map.fields)}

  ## Examples
  #{schema_examples(@doc_map.examples)}
  """

  use Ecto.Schema
  use Timex.Ecto.Timestamps
  import Ecto.Changeset
  import Ecto.Query, warn: false
  import EtheloApi.Helpers.ValidationHelper
  alias EtheloApi.Helpers.SlugHelper
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.OptionCategory
  alias EtheloApi.Structure.Option
  alias EtheloApi.Structure.OptionDetail

  schema "option_categories" do
    belongs_to :decision, Decision, on_replace: :raise
    has_many :options, Option, on_delete: :nothing, on_replace: :raise
    belongs_to :primary_detail, OptionDetail, on_replace: :raise
    belongs_to :default_high_option, Option, on_replace: :raise
    belongs_to :default_low_option, Option, on_replace: :raise

    field :title, :string
    field :results_title, :string
    field :slug, :string
    field :info, :string
    field :keywords, :string
    field :weighting, :integer, default: 50
    field :deleted, :boolean, default: false
    field :xor, :boolean, default: false
    field :apply_participant_weights, :boolean, default: true
    field :scoring_mode, ScoringModeEnum, default: "none"
    field :voting_style, VotingStyleEnum, default: "one"
    field :triangle_base, :integer, default: 3
    field :sort, :integer, default: 0
    field :budget_percent, :float, default: nil
    field :flat_fee, :float, default: nil
    field :vote_on_percent, :boolean, default: true
    field :quadratic, :boolean, default: false


    timestamps()
  end

  @doc """
  Adds validations shared between update and create actions
  - required fields title
  - valid title
  - maybe update slug
  - weighting between 1 and 100
  """
  def add_validations(%Ecto.Changeset{} = changeset, decision) do
    changeset
    |> validate_required([:title, :weighting])
    |> validate_format(:title, unicode_word_check_regex(), message: "must include at least one word")
    |> validate_format(:results_title, unicode_word_check_regex(), message: "must include at least one word")
    |> validate_inclusion(:scoring_mode, ScoringModeEnum.__valid_values__())
    |> validate_inclusion(:voting_style, VotingStyleEnum.__valid_values__())
    |> maybe_validate_weighting()
    |> maybe_validate_option_detail(decision)
    |> maybe_validate_default_low_option_id(decision)
    |> maybe_validate_default_high_option_id(decision)
    |> SlugHelper.maybe_update_slug(&slug_not_found_in_decision/2)
    |> unique_constraint(:slug, name: :unique_option_category_slug_index)
  end

  def maybe_validate_weighting(changeset) do
    case get_field(changeset, :weighting) do
      nil -> changeset
      _ ->  validate_number(changeset, :weighting, greater_than_or_equal_to: 1, less_than_or_equal_to: 9999)
    end
  end

  def base_changeset(%OptionCategory{} = option_category, %{} = attrs) do
    option_category
    |> cast(attrs,
      [:title, :results_title, :slug, :weighting, :info, :keywords, :deleted, :xor,
      :budget_percent, :flat_fee, :vote_on_percent, :quadratic,
      :apply_participant_weights, :primary_detail_id, :scoring_mode, :triangle_base,
      :voting_style, :default_high_option_id, :default_low_option_id, :sort]
    )
  end

  @doc """
  Validates creation of an OptionCategory on a Decision.
  """
  def create_changeset(%OptionCategory{} = option_category, attrs, %Decision{} = decision) do
    option_category
    |> base_changeset(attrs)
    |> Ecto.Changeset.put_assoc(:decision, decision, required: true)
    |> add_validations(decision)
  end

  defp maybe_validate_option_detail(changeset, decision) do
    case get_field(changeset, :scoring_mode) do
      nil -> changeset
      "none" -> changeset
      :none -> changeset
      _ -> {changeset, _, _} = validate_assoc_in_decision(changeset, decision, :primary_detail_id, OptionDetail)
        changeset
    end
  end

  defp maybe_validate_default_low_option_id(changeset, decision) do
    case get_field(changeset, :scoring_mode) do
      nil -> changeset
      "none" -> changeset
      :none -> changeset
      _ -> {changeset, _, _} = validate_optional_assoc_in_decision(changeset, decision, :default_low_option_id, Option)
        changeset
    end
  end

  defp maybe_validate_default_high_option_id(changeset, decision) do
    case get_field(changeset, :scoring_mode) do
      nil -> changeset
      "none" -> changeset
      :none -> changeset
      _ ->
        case get_field(changeset, :voting_style) do
          "one" -> changeset
          :one -> changeset
          _ ->
            {changeset, _, _} = validate_optional_assoc_in_decision(changeset, decision, :default_high_option_id, Option)
            changeset
        end
    end
  end

  @doc """
  Validates update of an OptionCategory.

  Does not allow changing of Decision
  """
  def update_changeset(%OptionCategory{} = option_category, attrs) do
    option_category
    |> base_changeset(attrs)
    |> add_validations(option_category.decision)
  end

  @doc """
  Validations for bulk upsert, cannot contain any database lookups
  must contain decision id and timestamps
  """
  def bulk_upsert_changeset(%{} = attrs) do
    option_category = %OptionCategory{}
    option_category |> cast(attrs,
      [
      :decision_id, :inserted_at, :updated_at,
      :title, :results_title, :slug, :weighting, :info, :keywords, :deleted, :xor,
      :budget_percent, :flat_fee, :vote_on_percent, :quadratic,
      :apply_participant_weights, :scoring_mode, :triangle_base, :primary_detail_id,
      :voting_style, :default_high_option_id, :default_low_option_id, :sort] )
    |> validate_required([:title, :slug, :inserted_at, :updated_at, :decision_id])
    |> validate_format(:title, unicode_word_check_regex(), message: "must include at least one word")

  end

  def default_category_slug(), do: "uncategorized"

  @doc """
  default changeset for the uncategorized filter
  """
  def default_category_changeset(%Decision{} = decision) do
    attrs = %{title: "Uncategorized Options", slug: default_category_slug(), xor: false, apply_participant_weights: false }
    %OptionCategory{} |> create_changeset(attrs, decision)
  end

  @doc """
  Wraps a query that checks for the existence of a suggested slug.

  Used as a checker with `EtheloApi.Structure.Helper.maybe_update_slug/2`
  """
  def slug_not_found_in_decision(value, changeset) do
    OptionCategory |> SlugHelper.slug_not_found_in_decision(value, changeset)
  end
end
