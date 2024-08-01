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
  import Ecto.Changeset
  import Ecto.Query, warn: false
  import EtheloApi.Helpers.ValidationHelper
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.OptionCategory
  alias EtheloApi.Structure.Option
  alias EtheloApi.Structure.OptionDetail

  schema "option_categories" do
    belongs_to :decision, Decision, on_replace: :raise
    belongs_to :primary_detail, OptionDetail, on_replace: :raise
    belongs_to :default_high_option, Option, on_replace: :raise
    belongs_to :default_low_option, Option, on_replace: :raise

    has_many :options, Option, on_delete: :nothing, on_replace: :raise

    field :apply_participant_weights, :boolean, default: true
    field :budget_percent, :float, default: nil
    field :deleted, :boolean, default: false
    field :flat_fee, :float, default: nil
    field :info, :string
    field :keywords, :string
    field :quadratic, :boolean, default: false
    field :results_title, :string

    field :scoring_mode, Ecto.Enum,
      values: [:none, :rectangle, :triangle],
      default: :none

    field :slug, :string
    field :sort, :integer, default: 0
    field :title, :string
    field :triangle_base, :integer, default: 3
    field :vote_on_percent, :boolean, default: true

    field :voting_style, Ecto.Enum,
      values: [:one, :range],
      default: :one

    field :weighting, :integer, default: 50
    field :xor, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc """
  Prepares attributes shared between create, update and import actions
  """
  def base_changeset(%OptionCategory{} = option_category, %{} = attrs) do
    option_category
    |> cast(
      attrs,
      [
        :apply_participant_weights,
        :budget_percent,
        :deleted,
        :flat_fee,
        :info,
        :keywords,
        :quadratic,
        :results_title,
        :scoring_mode,
        :slug,
        :sort,
        :title,
        :triangle_base,
        :vote_on_percent,
        :voting_style,
        :weighting,
        :xor
      ]
    )
  end

  @doc """
  Prepares and Validates associations for an OptionCategory
  """
  def cast_associations(changeset, attrs) do
    changeset
    |> cast(attrs, [:primary_detail_id, :default_high_option_id, :default_low_option_id])
  end

  @doc """
  Prepares and Validates attributes for creating an OptionCategory
  """
  def create_changeset(attrs, %Decision{} = decision) do
    %OptionCategory{}
    |> base_changeset(attrs)
    |> cast_associations(attrs)
    |> put_assoc(:decision, decision, required: true)
    |> base_validations()
    |> db_validations(decision.id)
  end

  @doc """
  Prepares and Validates attributes for updating an OptionCategory

  Does not allow changing of Decision
  """
  def update_changeset(%OptionCategory{} = option_category, attrs) do
    option_category
    |> base_changeset(attrs)
    |> cast_associations(attrs)
    |> base_validations()
    |> db_validations(option_category.decision_id)
  end

  @doc """
  Validations for first stage of bulk import, cannot contain any database lookups or association data
  """
  def import_changeset(attrs, decision_id, duplicate_slugs) do
    %OptionCategory{}
    |> base_changeset(attrs)
    |> base_validations()
    |> validate_import_slugs(duplicate_slugs)
    |> validate_import_required(decision_id)
  end

  @doc """
  Validations for second stage of bulk import when association data is available.

  Used to add association information to an existing record.

  Can contain database lookups, but they are not necessary here
  """
  def import_assoc_changeset(%OptionCategory{} = option_category, attrs) do
    option_category
    |> change()
    |> assoc_changeset(attrs)
  end

  defp assoc_changeset(%Ecto.Changeset{} = changeset, attrs) do
    if has_scoring_validations?(changeset) do
      changeset
      |> cast_associations(attrs)
      |> validate_required([:primary_detail_id])
    else
      changeset
    end
  end

  def default_category_slug(), do: "uncategorized"

  @doc """
  default changeset for the uncategorized filter
  """
  def default_category_changeset(%Decision{} = decision) do
    attrs = %{
      title: "Uncategorized Options",
      slug: default_category_slug(),
      xor: false,
      apply_participant_weights: false
    }

    create_changeset(attrs, decision)
  end

  @doc """
  Adds validations shared between create, update and import actions.

  Should not include any validation that touches the database
  unique_constraint and other post-query checks can be used.
  """
  def base_validations(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_required([:title, :weighting])
    |> validate_has_word(:title)
    |> validate_has_word(:results_title)
    |> validate_inclusion(:scoring_mode, Ecto.Enum.values(OptionCategory, :scoring_mode))
    |> validate_inclusion(:voting_style, Ecto.Enum.values(OptionCategory, :voting_style))
    |> validate_weighting()
    |> db_contraint_validations()
  end

  defp db_contraint_validations(changeset) do
    changeset
    |> unique_constraint(:slug, name: :unique_option_category_slug_index)
    |> foreign_key_constraint(:decision_id)
    |> foreign_key_constraint(:default_low_option_id)
    |> foreign_key_constraint(:default_high_option_id)
    |> foreign_key_constraint(:primary_detail_id)
  end

  def has_scoring_validations?(changeset) do
    scoring_mode = changeset |> get_field(:scoring_mode)

    scoring_mode in [nil, "none", :none] == false
  end

  @doc """
  Validations that require database queries. Cannot be used by import system
  """
  def db_validations(%Ecto.Changeset{} = changeset, decision_id) do
    changeset =
      changeset
      |> validate_unique_slug(OptionCategory)

    if has_scoring_validations?(changeset) do
      changeset
      |> validate_assoc_in_decision(decision_id, :primary_detail_id, OptionDetail)
      |> validate_optional_assoc_in_decision(decision_id, :default_high_option_id, Option)
      |> validate_optional_assoc_in_decision(decision_id, :default_low_option_id, Option)
    else
      changeset
    end
  end

  def validate_weighting(changeset) do
    case get_field(changeset, :weighting) do
      nil ->
        changeset

      _ ->
        validate_number(changeset, :weighting,
          greater_than_or_equal_to: 1,
          less_than_or_equal_to: 9999
        )
    end
  end

  def export_fields() do
    [
      :apply_participant_weights,
      :budget_percent,
      :default_high_option_id,
      :default_low_option_id,
      :flat_fee,
      :id,
      :info,
      :keywords,
      :primary_detail_id,
      :quadratic,
      :results_title,
      :scoring_mode,
      :slug,
      :sort,
      :title,
      :triangle_base,
      :vote_on_percent,
      :voting_style,
      :weighting,
      :xor
    ]
  end
end
