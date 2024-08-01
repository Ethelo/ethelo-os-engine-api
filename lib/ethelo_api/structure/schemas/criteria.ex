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
  import EtheloApi.Helpers.ValidationHelper

  alias EtheloApi.Graphql.Docs.Criteria
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Criteria

  schema "criterias" do
    belongs_to :decision, Decision, on_replace: :raise

    field :apply_participant_weights, :boolean, default: true
    field :bins, :integer, default: 5
    field :deleted, :boolean, default: false
    field :info, :string
    field :slug, :string
    field :sort, :integer, default: 0
    field :support_only, :boolean, default: false
    field :title, :string
    field :weighting, :integer, default: 50

    timestamps(type: :utc_datetime)
  end

  @doc """
  Prepares attributes shared between create, update and import actions
  """
  def base_changeset(%Criteria{} = criteria, %{} = attrs) do
    criteria
    |> cast(attrs, [
      :apply_participant_weights,
      :bins,
      :deleted,
      :info,
      :slug,
      :sort,
      :support_only,
      :title,
      :weighting
    ])
  end

  @doc """
  Prepares and Validates attributes for creating a Criteria
  """
  def create_changeset(attrs, %Decision{} = decision) do
    %Criteria{}
    |> base_changeset(attrs)
    |> put_assoc(:decision, decision, required: true)
    |> base_validations
    |> db_validations(decision.id)
  end

  @doc """
  Prepares and Validates attributes for updating a Criteria

  Does not allow changing of Decision
  """
  def update_changeset(%Criteria{} = criteria, attrs) do
    criteria
    |> base_changeset(attrs)
    |> base_validations
    |> db_validations(criteria.decision_id)
  end

  @doc """
  Validations for bulk import, cannot contain any database lookups
  """
  def import_changeset(attrs, decision_id, duplicate_slugs) do
    %Criteria{}
    |> base_changeset(attrs)
    |> base_validations
    |> validate_import_slugs(duplicate_slugs)
    |> validate_import_required(decision_id)
  end

  @doc """
  Adds validations shared between create, update and import actions

  Should not include any validation that touches the database
  unique_constraint and other post-query checks can be used.
  """
  def base_validations(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_required([:title, :bins])
    |> validate_has_word(:title)
    |> validate_number(:bins, greater_than: 0, less_than: 10)
    |> validate_number(:weighting,
      greater_than_or_equal_to: 1,
      less_than_or_equal_to: 9999
    )
    |> unique_constraint(:slug, name: :unique_criteria_slug_index)
    |> foreign_key_constraint(:decision_id)
  end

  @doc """
  Validations that require database queries. Cannot be used by import system
  """
  def db_validations(%Ecto.Changeset{} = changeset, _decision_id) do
    changeset
    |> validate_unique_slug(Criteria)
  end

  def export_fields() do
    [
      :apply_participant_weights,
      :bins,
      :id,
      :info,
      :slug,
      :sort,
      :support_only,
      :title,
      :weighting
    ]
  end
end
