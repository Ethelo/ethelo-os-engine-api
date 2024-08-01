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
  alias EtheloApi.Repo
  import Ecto.Changeset
  import Ecto.Query, warn: false
  use Timex.Ecto.Timestamps

  import EtheloApi.Helpers.ValidationHelper
  alias EtheloApi.Helpers.SlugHelper
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Calculation
  alias EtheloApi.Structure.Variable
  alias EtheloApi.Constraints.ExpressionParser

  schema "calculations" do
    belongs_to :decision, Decision, on_replace: :raise
    many_to_many :variables, Variable, join_through: "calculation_variables", on_replace: :delete

    field :expression, :string
    field :slug, :string
    field :title, :string
    field :personal_results_title, :string
    field :display_hint, :string
    field :public, :boolean, default: false
    field :sort, :integer, default: 0

    timestamps()
  end

  @doc """
  Adds validations shared between update and create actions
  - required fields
  - valid title
  - maybe update slug
  """
  def add_validations(%Ecto.Changeset{} = changeset, %Decision{} = decision) do
    changeset
    |> validate_required([:title, :expression])
    |> validate_format(:title, unicode_word_check_regex(), message: "must include at least one word")
    |> SlugHelper.maybe_update_slug(&slug_not_found_in_decision/2)
    |> unique_constraint(:slug, name: :unique_calculation_slug_index)
    |> validate_expression(decision)
  end

  def base_changeset(%Calculation{} = calculation, %{} = attrs) do
    attrs = attrs |> stringify_value(:display_hint)
    calculation |> Repo.preload(:variables) |> cast(attrs, [:title, :personal_results_title, :slug, :expression, :display_hint, :public, :sort])
  end

  @doc """
  Validates creation of an Calculation on a Decision.
  """
  def create_changeset(%Calculation{} = calculation, attrs, %Decision{} = decision) do
    calculation
    |> base_changeset(attrs)
    |> put_assoc(:decision, decision, required: true)
    |> add_validations(decision)
  end

  @doc """
  Validates update of an calculation.

  Does not allow changing of Decision
  """
  def update_changeset(%Calculation{} = calculation, attrs) do
    calculation = calculation |> Repo.preload([:decision])

    calculation
    |> base_changeset(attrs)
    |> add_validations(calculation.decision)
  end

  def validate_expression(changeset, decision) do
    expression = get_field(changeset, :expression)
    parsed = ExpressionParser.parse(expression)
    validate_expression(changeset, parsed, decision)
  end

  def validate_expression(changeset, %{error: error} = parsed, _) when is_binary(error) do
    add_error(changeset, :expression, "#{parsed.error} at %{parsed}",
      [code: :syntax, invalid: parsed.last_parsed, parsed: parsed.parsed]
    )
  end

  def validate_expression(changeset, %{variables: []}, _), do: changeset
  def validate_expression(changeset, %{variables: variable_slugs}, %Decision{id: decision_id}) do
    validate_variables(changeset, variable_slugs, loaded_variables(variable_slugs, decision_id))
  end

  def validate_variables(changeset, variable_slugs, matching_variables) do
    if Enum.count(matching_variables) == Enum.count(variable_slugs) do
      changeset |> put_assoc(:variables, Map.values(matching_variables))
    else
      missing = variable_slugs -- Map.keys(matching_variables)
      add_error(changeset, :expression, "variable not found: %{missing}",
        [code: :foreign, missing: Enum.join(missing, ",")]
      )
    end
  end

  def loaded_variables(variable_slugs, decision_id) do
    Variable
    |> where([t], t.decision_id == ^decision_id)
    |> where([t], t.slug in ^variable_slugs)
    |> Repo.all
    |> case do
         nil -> %{}
         [] -> %{}
         list ->
            list
            |> Enum.map(fn (variable) -> {variable.slug, variable} end)
            |> Enum.into(%{})
      end
  end

  @doc """
  Wraps a query that checks for the existence of a suggested slug.

  Used as a checker with `EtheloApi.Structure.Helper.maybe_update_slug/2`
  """
  def slug_not_found_in_decision(value, changeset) do
    Calculation |> SlugHelper.slug_not_found_in_decision(value, changeset)
  end
end
