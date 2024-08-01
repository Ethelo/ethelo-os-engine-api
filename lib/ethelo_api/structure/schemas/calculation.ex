defmodule EtheloApi.Structure.Calculation do
  use DocsComposer, module: EtheloApi.Structure.Docs.Calculation

  @moduledoc """
  #{@doc_map.strings.calculation}

  #{@doc_map.strings.expression_detail}

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
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Calculation
  alias EtheloApi.Structure.Variable
  alias EtheloApi.Structure.ExpressionParser

  schema "calculations" do
    belongs_to :decision, Decision, on_replace: :raise
    many_to_many :variables, Variable, join_through: "calculation_variables", on_replace: :delete

    field :display_hint, :string
    field :expression, :string
    field :personal_results_title, :string
    field :public, :boolean, default: false
    field :slug, :string
    field :sort, :integer, default: 0
    field :title, :string

    timestamps(type: :utc_datetime)
  end

  @doc """
  Prepares attributes shared between create, update and import actions
  """
  def base_changeset(%Calculation{} = calculation, %{} = attrs) do
    attrs = attrs |> stringify_value(:display_hint)

    calculation
    |> cast(attrs, [
      :display_hint,
      :expression,
      :personal_results_title,
      :public,
      :slug,
      :sort,
      :title
    ])
  end

  @doc """
  Prepares and Validates attributes for creating a Calculation
  """
  def create_changeset(attrs, %Decision{} = decision) do
    %Calculation{}
    |> base_changeset(attrs)
    |> put_assoc(:decision, decision, required: true)
    |> base_validations()
    |> db_validations(decision.id)
  end

  @doc """
  Prepares and Validates attributes for updating a Calculation

  Does not allow changing of Decision
  """
  def update_changeset(%Calculation{} = calculation, attrs) do
    calculation
    |> Repo.preload([:decision, :variables])
    |> base_changeset(attrs)
    |> base_validations()
    |> db_validations(calculation.decision_id)
  end

  @doc """
  Validations for first stage of bulk import, cannot contain any database lookups or association data
  """
  def import_changeset(attrs, decision_id, duplicate_slugs) do
    changeset = %Calculation{} |> base_changeset(attrs)

    parsed = parse_expression(changeset)

    changeset
    |> validate_expression(parsed)
    |> base_validations()
    |> validate_import_slugs(duplicate_slugs)
    |> validate_import_required(decision_id)
  end

  @doc """
  Validations for second stage of bulk import when association data is available.

  Used to add association information to an existing record.

  Can contain database lookups (necessary for has_many relation)
  """
  def import_assoc_changeset(%Calculation{} = calculation) do
    calculation
    |> Repo.preload(:variables)
    |> change()
    |> validate_expression_and_values(calculation.decision_id)
  end

  @doc """
  Adds validations shared between create, update and import actions.

  Should not include any validation that touches the database
  unique_constraint and other post-query checks can be used.
  """
  def base_validations(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_required([:title, :expression])
    |> validate_has_word(:title)
    |> db_contraint_validations()
  end

  defp db_contraint_validations(changeset) do
    changeset
    |> unique_constraint(:slug, name: :unique_calculation_slug_index)
    |> foreign_key_constraint(:decision_id)
    |> foreign_key_constraint(:variable_id, name: :calculation_variables_variable_id_fkey)
  end

  @doc """
  Validations that require database queries. Cannot be used by import system
  """
  def db_validations(%Ecto.Changeset{} = changeset, decision_id) do
    changeset
    |> validate_unique_slug(Calculation)
    |> validate_expression_and_values(decision_id)
  end

  def validate_expression_and_values(changeset, decision_id) do
    parsed = parse_expression(changeset)

    changeset
    |> validate_expression(parsed)
    |> put_variables(parsed, decision_id)
  end

  def parse_expression(changeset) do
    expression = get_field(changeset, :expression)
    ExpressionParser.parse(expression)
  end

  def validate_expression(changeset, %{error: error} = parsed) when is_binary(error) do
    add_error(changeset, :expression, "#{parsed.error} at %{parsed}",
      code: :syntax,
      invalid: parsed.last_parsed,
      parsed: parsed.parsed
    )
  end

  def validate_expression(changeset, _), do: changeset

  def put_variables(changeset, %{error: error}, _) when is_binary(error), do: changeset

  def put_variables(changeset, %{variables: []}, _), do: changeset

  def put_variables(changeset, %{variables: variable_slugs}, decision_id) do
    matching_variables =
      Structure.list_variables(decision_id, %{slug: variable_slugs})

    if Enum.count(matching_variables) == Enum.count(variable_slugs) do
      changeset |> put_assoc(:variables, matching_variables)
    else
      matching_slugs = Enum.map(matching_variables, & &1.slug)
      missing = variable_slugs -- matching_slugs

      add_error(changeset, :expression, "Variable not found: %{missing}",
        code: :foreign,
        missing: Enum.join(missing, ",")
      )
    end
  end

  def export_fields() do
    [
      :display_hint,
      :expression,
      :id,
      :personal_results_title,
      :public,
      :slug,
      :sort,
      :title
    ]
  end
end
