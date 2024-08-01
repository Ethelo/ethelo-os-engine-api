defmodule EtheloApi.Structure.OptionDetail do
  use DocsComposer, module: EtheloApi.Structure.Docs.OptionDetail

  @moduledoc """
  #{@doc_map.strings.option_detail}

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
  alias EtheloApi.Structure.OptionDetail
  alias EtheloApi.Structure.OptionDetailValue
  alias EtheloApi.Structure.OptionFilter

  schema "option_details" do
    belongs_to :decision, Decision, on_replace: :raise
    has_many :option_detail_values, OptionDetailValue, on_replace: :raise
    has_many :option_filters, OptionFilter, on_replace: :raise

    field :display_hint, :string

    field :format, Ecto.Enum,
      values: [:string, :integer, :float, :boolean, :datetime],
      default: :string

    field :input_hint, :string
    field :public, :boolean, default: false
    field :slug, :string
    field :sort, :integer, default: 0
    field :title, :string

    timestamps(type: :utc_datetime)
  end

  @doc """
  Prepares attributes shared between create, update and import actions
  """
  def base_changeset(%OptionDetail{} = option_detail, %{} = attrs) do
    attrs = attrs |> stringify_value(:display_hint) |> stringify_value(:input_hint)

    option_detail
    |> cast(attrs, [
      :display_hint,
      :format,
      :input_hint,
      :public,
      :slug,
      :sort,
      :title
    ])
  end

  @doc """
  Prepares and Validates attributes for creating an OptionDetail
  """
  def create_changeset(attrs, %Decision{} = decision) do
    %OptionDetail{}
    |> base_changeset(attrs)
    |> put_assoc(:decision, decision, required: true)
    |> base_validations()
    |> db_validations(decision.id)
  end

  @doc """
  Prepares and Validates attributes for updating an OptionDetail

  Does not allow changing of Decision
  """
  def update_changeset(%OptionDetail{} = option_detail, attrs) do
    option_detail
    |> base_changeset(attrs)
    |> base_validations()
    |> db_validations(option_detail.decision_id)
  end

  @doc """
  Validations for first stage of bulk import, cannot contain any database lookups or association data
  """
  def import_changeset(attrs, decision_id, duplicate_slugs) do
    %OptionDetail{}
    |> base_changeset(attrs)
    |> base_validations()
    |> validate_import_slugs(duplicate_slugs)
    |> validate_import_required(decision_id)
  end

  @doc """
  Adds validations shared between create, update and import actions.

  Should not include any validation that touches the database
  unique_constraint and other post-query checks can be used.
  """
  def base_validations(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_required([:title, :format])
    |> validate_has_word(:title)
    |> validate_inclusion(:format, Ecto.Enum.values(OptionDetail, :format))
    |> unique_constraint(:slug, name: :unique_option_detail_slug_index)
    |> foreign_key_constraint(:decision_id)
  end

  @doc """
  Validations that require database queries. Cannot be used by import system
  """
  def db_validations(%Ecto.Changeset{} = changeset, _decision_id) do
    changeset
    |> validate_unique_slug(OptionDetail)
  end

  def export_fields() do
    [
      :display_hint,
      :format,
      :id,
      :input_hint,
      :public,
      :slug,
      :sort,
      :title
    ]
  end
end
