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
  use Timex.Ecto.Timestamps
  import Ecto.Changeset
  import Ecto.Query, warn: false

  import EtheloApi.Helpers.ValidationHelper
  alias EtheloApi.Helpers.SlugHelper
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

    field :title, :string
    field :slug, :string

    field :lhs, :float
    field :rhs, :float
    field :operator, ConstraintOperatorEnum
    field :enabled, :boolean, default: true
    field :relaxable, :boolean, default: false

    timestamps()
  end

  @doc """
  Adds validations shared between update and create actions
  - required fields: title, operator, rhs, option_filter_id
  - valid title
  - maybe update slug
  - validate OptionFilter
  - validate Variable or Calculation is associated
  - validate lhs if operator is between
  """
  def add_validations(%Ecto.Changeset{} = changeset, decision) do
    changeset
    |> validate_required([:title, :operator, :rhs])
    |> validate_format(:title, unicode_word_check_regex(), message: "must include at least one word")
    |> validate_option_filter(decision)
    |> validate_calculation_or_variable(decision)
    |> validate_inclusion(:operator, ConstraintOperatorEnum.__valid_values__())
    |> maybe_validate_lhs()
    |> SlugHelper.maybe_update_slug(&slug_not_found_in_decision/2)
    |> unique_constraint(:slug, name: :unique_calculation_slug_index)
    |> check_constraint(:calculation_id, name: :calculation_or_variable_required, message: "can't be blank if there is no Variable specified")
    |> check_constraint(:variable_id, name: :calculation_or_variable_required, message: "can't be blank if there is no Calculation specified")
  end

  defp base_changeset(%Constraint{} = constraint, attrs) do
    constraint
    |> cast(attrs, [:title, :slug, :relaxable, :operator, :lhs, :rhs, :option_filter_id, :calculation_id, :variable_id, :enabled])
  end

  defp maybe_validate_lhs(changeset) do
    case fetch_field(changeset, :operator) do
      {_, :between} -> validate_required(changeset, [:lhs])
      {_, "between"} -> validate_required(changeset, [:lhs])
      _ -> changeset
    end
  end

  defp validate_option_filter(changeset, decision) do
    {changeset, _, _} = validate_assoc_in_decision(changeset, decision, :option_filter_id, OptionFilter)
    changeset
  end

  def validate_calculation_or_variable(changeset, decision) do
    calculation_assoc = validate_assoc_in_decision(changeset, decision, :calculation_id, Calculation)
    variable_assoc = validate_assoc_in_decision(changeset, decision, :variable_id, Variable)
    validate_calculation_or_variable(changeset, calculation_assoc, variable_assoc)
  end

  def validate_calculation_or_variable(changeset, {_, _, nil}, {_, _, nil}) do
    changeset
    |> validate_required([:calculation_id], message: "can't be blank if there is no Variable specified")
    |> validate_required([:variable_id], message: "can't be blank if there is no Calculation specified")
  end

  def validate_calculation_or_variable(_, {calculation_changeset, _, _}, {_, _, nil})  do
    calculation_changeset
  end

  def validate_calculation_or_variable(_, {_, _, nil}, {variable_changeset, _, _})  do
    variable_changeset
  end

  def validate_calculation_or_variable(changeset, _, _) do
    changeset
    |> validate_empty(:calculation_id, "must be blank if there is an Variable specified")
    |> validate_empty(:variable_id, "must be blank if there is an Calculation specified")
  end

  @doc """
  Validates creation of an Constraint on a Decision.
  """
  def create_changeset(%Constraint{} = constraint, attrs, %Decision{} = decision) do
    constraint
    |> base_changeset(attrs)
    |> put_assoc(:decision, decision, required: true)
    |> add_validations(decision)
  end

  @doc """
  Validates update of an Constraint.

  Does not allow changing of Decision.
  """
  def update_changeset(%Constraint{} = constraint, attrs) do
    constraint = constraint |> Repo.preload([:decision, :option_filter, :variable, :calculation])

    constraint
    |> base_changeset(attrs)
    |> add_validations(constraint.decision)
  end

  @doc """
  Wraps a query that checks for the existence of a suggested slug.

  Used as a checker with `EtheloApi.Structure.Helper.maybe_update_slug/2`
  """
  def slug_not_found_in_decision(value, changeset) do
    Constraint |> SlugHelper.slug_not_found_in_decision(value, changeset)
  end

end
