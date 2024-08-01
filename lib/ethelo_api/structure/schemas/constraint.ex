defmodule EtheloApi.Structure.Constraint do
  use DocsComposer, module: EtheloApi.Structure.Docs.Constraint

  @moduledoc """
  #{@doc_map.strings.constraint}

  #{@doc_map.strings.mini_tutorial}

  ## Fields
  #{schema_fields(@doc_map.fields)}

  ## Examples
  #{schema_examples(@doc_map.examples)}
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, warn: false
  import EtheloApi.Helpers.ValidationHelper

  alias EtheloApi.Repo
  alias EtheloApi.Structure.Calculation
  alias EtheloApi.Structure.Constraint
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.OptionFilter
  alias EtheloApi.Structure.Variable

  schema "constraints" do
    belongs_to :decision, Decision, on_replace: :raise
    belongs_to :option_filter, OptionFilter, on_replace: :delete
    belongs_to :calculation, Calculation, on_replace: :delete
    belongs_to :variable, Variable, on_replace: :delete

    field :enabled, :boolean, default: true
    field :lhs, :float

    field :operator, Ecto.Enum,
      values: [:equal_to, :less_than_or_equal_to, :greater_than_or_equal_to, :between],
      default: :equal_to

    field :relaxable, :boolean, default: false
    field :rhs, :float
    field :slug, :string
    field :title, :string

    timestamps(type: :utc_datetime)
  end

  @doc """
  Prepares attributes shared between create, update and import actions
  """
  def base_changeset(%Constraint{} = constraint, %{} = attrs) do
    constraint
    |> cast(attrs, [
      :enabled,
      :lhs,
      :operator,
      :relaxable,
      :rhs,
      :slug,
      :title
    ])
  end

  @doc """
  Prepares and Validates associations for a Constraint
  """
  def cast_associations(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :option_filter_id,
      :calculation_id,
      :variable_id
    ])
  end

  @doc """
  Prepares and Validates attributes for creating a Constraint
  """
  def create_changeset(attrs, %Decision{} = decision) do
    %Constraint{}
    |> base_changeset(attrs)
    |> cast_associations(attrs)
    |> put_assoc(:decision, decision, required: true)
    |> base_validations()
    |> db_validations(decision.id)
  end

  @doc """
  Prepares and Validates attributes for updating a Constraint

  Does not allow changing of Decision.
  """
  def update_changeset(%Constraint{} = constraint, attrs) do
    constraint = constraint |> Repo.preload([:decision, :option_filter, :variable, :calculation])

    constraint
    |> base_changeset(attrs)
    |> cast_associations(attrs)
    |> base_validations()
    |> db_validations(constraint.decision_id)
  end

  @doc """
  Validations for first stage of bulk import, cannot contain any database lookups or association data
  """
  def import_changeset(attrs, decision_id, duplicate_slugs) do
    %Constraint{}
    |> base_changeset(attrs)
    |> base_validations()
    |> validate_import_slugs(duplicate_slugs)
    |> validate_import_required(decision_id)
  end

  @doc """
  Validations for second stage of bulk import when association data is available.

  Can be used directly as it processes data through `import_changeset/3`,
  in which case duplicate slug must be passed in.
  Prefer the two-step process in order to return errors as quickly as possible,
  instead of waiting until some database inserts are complete

  For efficiency, cannot contain any database lookups.
  """
  def import_assoc_changeset(attrs, decision_id, duplicate_slugs \\ []) do
    import_changeset(attrs, decision_id, duplicate_slugs)
    |> cast_associations(attrs)
    |> validate_required([:option_filter_id])
    |> validate_either(
      :calculation_id,
      :variable_id,
      "must specify either a Variable or a Calculation"
    )
  end

  @doc """
  Adds validations shared between create, update and import actions.
  Should not include any validation that touches the database
  unique_constraint and other post-query checks can be used.
  """
  def base_validations(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_required([:title, :operator, :rhs])
    |> validate_has_word(:title)
    |> validate_inclusion(:operator, Ecto.Enum.values(Constraint, :operator))
    |> validate_lhs()
    |> db_contraint_validations()
  end

  defp db_contraint_validations(changeset) do
    changeset
    |> unique_constraint(:slug, name: :unique_constraint_slug_index)
    |> check_constraint(:calculation_id,
      name: :calculation_or_variable_required,
      message: "must specify either a Variable or a Calculation"
    )
    |> check_constraint(:variable_id,
      name: :calculation_or_variable_required,
      message: "must specify either a Variable or a Calculation"
    )
    |> foreign_key_constraint(:decision_id)
    |> foreign_key_constraint(:option_filter_id)
    |> foreign_key_constraint(:calculation_id)
    |> foreign_key_constraint(:variable_id)
  end

  @doc """
  Validations that require database queries. Cannot be used by import system
  """
  def db_validations(%Ecto.Changeset{} = changeset, decision_id) do
    changeset
    |> validate_unique_slug(Constraint)
    |> validate_either(
      :calculation_id,
      :variable_id,
      "must specify either a Variable or a Calculation"
    )
    |> validate_assoc_in_decision(decision_id, :option_filter_id, OptionFilter)
    |> validate_optional_assoc_in_decision(decision_id, :calculation_id, Calculation)
    |> validate_optional_assoc_in_decision(decision_id, :variable_id, Variable)
  end

  defp validate_lhs(changeset) do
    case get_field(changeset, :operator) do
      :between -> validate_required(changeset, [:lhs])
      "between" -> validate_required(changeset, [:lhs])
      _ -> changeset
    end
  end

  def export_fields() do
    [
      :enabled,
      :id,
      :lhs,
      :operator,
      :option_filter_id,
      :calculation_id,
      :relaxable,
      :rhs,
      :slug,
      :title,
      :variable_id
    ]
  end
end
