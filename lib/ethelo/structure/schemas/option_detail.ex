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
  use Timex.Ecto.Timestamps

  import EtheloApi.Helpers.ValidationHelper
  alias EtheloApi.Helpers.SlugHelper
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.OptionDetail
  alias EtheloApi.Structure.OptionDetailValue
  alias EtheloApi.Structure.OptionFilter

  schema "option_details" do
    belongs_to :decision, Decision, on_replace: :raise
    has_many :option_detail_values, OptionDetailValue, on_replace: :raise
    has_many :option_filters, OptionFilter, on_replace: :raise

    field :title, :string
    field :slug, :string
    field :format, DetailFormatEnum, default: "string"
    field :display_hint, :string
    field :input_hint, :string
    field :public, :boolean, default: false
    field :sort, :integer, default: 0

    timestamps()
  end

  @doc """
  Adds validations shared between update and create actions
  - required fields (title, format)
  - valid title
  - valid format
  - maybe update slug
  """
  def add_validations(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_required([:title, :format])
    |> validate_format(:title, unicode_word_check_regex(), message: "must include at least one word")
    |> validate_inclusion(:format, DetailFormatEnum.__valid_values__())
    |> SlugHelper.maybe_update_slug(&slug_not_found_in_decision/2)
    |> unique_constraint(:slug, name: :unique_option_detail_slug_index)
  end

  def base_changeset(%OptionDetail{} = option_detail, %{} = attrs) do
    attrs = attrs |> stringify_value(:display_hint) |> stringify_value(:input_hint)
    option_detail |> cast(attrs, [:title, :slug, :public, :format, :display_hint, :input_hint, :sort])
  end

  @doc """
  Validates creation of an OptionDetail on a Decision.
  """
  def create_changeset(%OptionDetail{} = option_detail, attrs, %Decision{} = decision) do
    option_detail
    |> base_changeset(attrs)
    |> Ecto.Changeset.put_assoc(:decision, decision, required: true)
    |> add_validations
  end

  @doc """
  Validates update of an OptionDetail.

  Does not allow changing of Decision
  """
  def update_changeset(%OptionDetail{} = option_detail, attrs) do
    option_detail
    |> base_changeset(attrs)
    |> add_validations
  end

  @doc """
  Wraps a query that checks for the existence of a suggested slug.

  Used as a checker with `EtheloApi.Structure.Helper.maybe_update_slug/2`
  """
  def slug_not_found_in_decision(value, changeset) do
    OptionDetail |> SlugHelper.slug_not_found_in_decision(value, changeset)
  end
end
