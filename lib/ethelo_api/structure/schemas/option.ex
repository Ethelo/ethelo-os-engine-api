defmodule EtheloApi.Structure.Option do
  use DocsComposer, module: EtheloApi.Structure.Docs.Option

  @moduledoc """
  #{@doc_map.strings.option}

  ## Fields
  #{schema_fields(@doc_map.fields)}

  ## Examples
  #{schema_examples(Map.drop(@doc_map.examples, ["Updated 1"]))}
  """

  use Ecto.Schema
  alias EtheloApi.Repo
  import Ecto.Changeset
  import Ecto.Query, warn: false
  import EtheloApi.Helpers.ValidationHelper

  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Option
  alias EtheloApi.Structure.OptionCategory
  alias EtheloApi.Structure.OptionDetailValue
  alias EtheloApi.Structure.Queries.OptionCategory, as: OptionCategoryQueries
  alias EtheloApi.Scenarios.Scenario

  schema "options" do
    belongs_to :decision, Decision, on_replace: :raise
    belongs_to :option_category, OptionCategory, on_replace: :delete
    has_many :option_detail_values, OptionDetailValue, on_replace: :delete
    many_to_many :scenarios, Scenario, join_through: "scenarios_options", on_replace: :delete

    field :deleted, :boolean, default: false
    field :determinative, :boolean, default: false
    field :enabled, :boolean, default: true
    field :info, :string
    field :results_title, :string
    field :slug, :string
    field :sort, :integer, default: 0
    field :title, :string

    timestamps(type: :utc_datetime)
  end

  @doc """
  Prepares attributes shared between create, update and import actions
  """
  def base_changeset(%Option{} = option, %{} = attrs) do
    option
    |> cast(attrs, [
      :deleted,
      :determinative,
      :enabled,
      :info,
      :results_title,
      :slug,
      :sort,
      :title
    ])
  end

  @doc """
  Prepares and Validates associations for an Option
  """
  def cast_associations(changeset, attrs) do
    changeset
    |> cast(attrs, [:option_category_id])
  end

  @doc """
  Prepares and Validates attributes for creating an Option
  """
  def create_changeset(attrs, %Decision{} = decision) do
    %Option{}
    |> base_changeset(attrs)
    |> cast_associations(attrs)
    |> put_assoc(:decision, decision, required: true)
    |> base_validations()
    |> db_validations(decision)
  end

  @doc """
  Prepares and Validates attributes for updating an Option

  Does not allow changing of Decision
  """
  def update_changeset(%Option{} = option, attrs) do
    option = option |> Repo.preload([:decision, :option_category, :option_detail_values])

    option
    |> base_changeset(attrs)
    |> cast_associations(attrs)
    |> base_validations()
    |> db_validations(option.decision)
    |> maybe_update_option_detail_values(option, attrs)
  end

  @doc """
  Validations for first stage of bulk import, cannot contain any database lookups or association data
  """
  def import_changeset(attrs, decision_id, duplicate_slugs) do
    %Option{}
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
    |> validate_required([:option_category_id])
  end

  @doc """
  Adds validations shared between create, update and import actions.

  Should not include any validation that touches the database
  unique_constraint and other post-query checks can be used.
  """
  def base_validations(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_required([:title])
    |> validate_has_word(:title)
    |> unique_constraint(:slug, name: :unique_option_slug_index)
    |> foreign_key_constraint(:decision_id)
    |> foreign_key_constraint(:option_category_id)
  end

  @doc """
  Validations that require database queries. Cannot be used by import system
  """
  def db_validations(%Ecto.Changeset{} = changeset, %Decision{} = decision) do
    changeset
    |> validate_unique_slug(Option)
    |> validate_option_category(decision)
  end

  @doc """
  Apply default OptionCategory if one is not required, validate category exists
  """
  def validate_option_category(changeset, decision) do
    if field_empty?(changeset, :option_category_id) do
      default_category = OptionCategoryQueries.ensure_default_option_category(decision)
      put_change(changeset, :option_category_id, default_category.id)
    else
      validate_assoc_in_decision(changeset, decision.id, :option_category_id, OptionCategory)
    end
  end

  @doc """
  If OptionDetailValues are supplied as part of an update, prepare them for insertion
  requires record be created so id is available
  """
  def maybe_update_option_detail_values(changeset, option, %{} = attrs) do
    maybe_update_option_detail_values(
      changeset,
      option,
      Map.get(attrs, :option_detail_values, nil)
    )
  end

  def maybe_update_option_detail_values(changeset, _option, nil), do: changeset

  def maybe_update_option_detail_values(changeset, _option, []) do
    changeset |> put_assoc(:option_detail_values, [])
  end

  def maybe_update_option_detail_values(changeset, option, option_detail_values)
      when is_list(option_detail_values) do
    option_detail_values = ensure_correct_detail_value_structs(option_detail_values, option)
    changeset |> put_assoc(:option_detail_values, option_detail_values)
  end

  defp ensure_correct_detail_value_structs(option_detail_values, option) do
    option_detail_values
    |> Enum.map(&Map.put(&1, :option_id, option.id))
    |> Enum.map(fn option_detail_value ->
      OptionDetailValue.upsert_changeset(
        option_detail_value,
        option.decision
      )
    end)
  end

  def export_fields() do
    [
      :deleted,
      :determinative,
      :enabled,
      :id,
      :info,
      :option_category_id,
      :results_title,
      :slug,
      :sort,
      :title
    ]
  end
end
