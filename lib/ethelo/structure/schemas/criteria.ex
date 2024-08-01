defmodule EtheloApi.Structure.Criteria do
  use DocsComposer, module: EtheloApi.Structure.Docs.Criteria

  @moduledoc """
  #{@doc_map.strings.criteria}

  #{@doc_map.strings.mini_tutorial}

  ## Fields
  #{schema_fields(@doc_map.fields)}

  ## Examples
  #{schema_examples(Map.drop(@doc_map.examples, ["Updated 1"]))}
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  use Timex.Ecto.Timestamps

  alias EtheloApi.Helpers.SlugHelper
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Criteria
  import EtheloApi.Helpers.ValidationHelper

  schema "criterias" do
    belongs_to :decision, Decision, on_replace: :raise

    field :title, :string
    field :slug, :string
    field :info, :string
    field :bins, :integer, default: 5
    field :weighting, :integer, default: 50
    field :apply_participant_weights, :boolean, default: true
    field :support_only, :boolean, default: false
    field :deleted, :boolean, default: false
    field :sort, :integer, default: 0

    timestamps()
  end

  @doc """
  Adds validations shared between update and create actions
  - required fields title and bins
  - valid title
  - maybe update slug
  - bins between 0 and 10
  - weighting between 1 and 100
  """
  def add_validations(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_required([:title, :bins])
    |> validate_format(:title, unicode_word_check_regex(), message: "must include at least one word")
    |> validate_number(:bins, greater_than: 0, less_than: 10)
    |> maybe_validate_weighting()
    |> SlugHelper.maybe_update_slug(&slug_not_found_in_decision/2)
    |> unique_constraint(:slug, name: :unique_criteria_slug_index)
  end

  def maybe_validate_weighting(changeset) do
    case get_field(changeset, :weighting) do
      nil -> changeset
      _ ->  validate_number(changeset, :weighting, greater_than_or_equal_to: 1, less_than_or_equal_to: 9999)
    end
  end

  def base_changeset(%Criteria{} = criteria, %{} = attrs) do
    criteria |> cast(attrs, [:title, :slug, :bins, :support_only, :weighting, :apply_participant_weights, :info, :deleted, :sort])
  end

  @doc """
  Validates creation of a Criteria on a Decision.
  """
  def create_changeset(%Criteria{} = criteria, attrs, %Decision{} = decision) do
    criteria
    |> base_changeset(attrs)
    |> Ecto.Changeset.put_assoc(:decision, decision, required: true)
    |> add_validations
  end

  @doc """
  Validates update of a Criteria.

  Does not allow changing of Decision
  """
  def update_changeset(%Criteria{} = criteria, attrs) do
    criteria
    |> base_changeset(attrs)
    |> add_validations
  end

  @doc """
  Wraps a query that checks for the existence of a suggested slug.

  Used as a checker with `EtheloApi.Structure.Helper.maybe_update_slug/2`
  """
  def slug_not_found_in_decision(value, changeset) do
    Criteria |> SlugHelper.slug_not_found_in_decision(value, changeset)
  end
end
