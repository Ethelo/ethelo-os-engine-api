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
  use Timex.Ecto.Timestamps
  import EtheloApi.Helpers.ValidationHelper

  alias EtheloApi.Helpers.SlugHelper
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Option
  alias EtheloApi.Structure.OptionCategory
  alias EtheloApi.Structure.OptionDetailValue
  alias EtheloApi.Structure.Queries.OptionCategory, as: OptionCategoryQueries
  alias Engine.Scenarios.Scenario

  schema "options" do
    belongs_to :decision, Decision, on_replace: :raise
    belongs_to :option_category, OptionCategory, on_replace: :delete
    has_many :option_detail_values, OptionDetailValue, on_replace: :delete
    many_to_many :scenarios, Scenario, join_through: "scenarios_options", on_replace: :delete

    field :title, :string
    field :results_title, :string
    field :slug, :string
    field :info, :string
    field :determinative, :boolean, default: false
    field :enabled, :boolean, default: true
    field :deleted, :boolean, default: false
    field :sort, :integer, default: 0

    timestamps()
  end

  @doc """
  Adds validations shared between update and create actions
  - required fields (title)
  - valid title
  - maybe update slug
  """
  def add_validations(%Ecto.Changeset{} = changeset, decision) do
    changeset
    |> validate_required([:title])
    |> validate_format(:title, unicode_word_check_regex(), message: "must include at least one word")
    |> SlugHelper.maybe_update_slug(&slug_not_found_in_decision/2)
    |> validate_option_category(decision)
    |> unique_constraint(:slug, name: :unique_option_slug_index)
  end

  @doc """
  Validations for bulk upsert, cannot contain any database lookups
  """
  def bulk_upsert_changeset(%{} = attrs) do
    option = %Option{}
    option |> cast(attrs, [:title, :results_title, :slug, :enabled, :decision_id,
    :info, :determinative, :option_category_id, :deleted, :sort, :inserted_at, :updated_at])
    |> validate_required([:title, :option_category_id, :slug, :inserted_at, :updated_at, :decision_id])
    |> validate_format(:title, unicode_word_check_regex(), message: "must include at least one word")
  end

  defp validate_option_category(changeset, decision) do
    id_value = get_field(changeset, :option_category_id)
    if id_value in [nil, ""] do
      default_category = OptionCategoryQueries.ensure_default_option_category(decision)
      put_change(changeset, :option_category_id, default_category.id)
    else
      {changeset, _, _} = validate_assoc_in_decision(changeset, decision, :option_category_id, OptionCategory)
      changeset
    end
  end

  def base_changeset(%Option{} = option, %{} = attrs) do
    attrs = attrs |> stringify_value(:variable_display_hint)
    option |> cast(attrs, [:title, :results_title, :slug, :enabled,
    :info, :determinative, :option_category_id, :deleted, :sort])
  end

  @doc """
  Validates creation of an Option on a Decision.
  """
  def create_changeset(%Option{} = option, attrs, %Decision{} = decision) do
    option
    |> base_changeset(attrs)
    |> put_assoc(:decision, decision, required: true)
    |> add_validations(decision)
  end

  @doc """
  Validates update of an option.

  Does not allow changing of Decision
  """
  def update_changeset(%Option{} = option, attrs) do
    option = option |> Repo.preload([:decision, :option_category, :option_detail_values])

    option
    |> base_changeset(attrs)
    |> add_validations(option.decision)
    |> maybe_update_option_detail_values(option, attrs)
  end

  def maybe_update_option_detail_values(changeset, option, %{} = attrs) do
    maybe_update_option_detail_values(changeset, option, Map.get(attrs, :option_detail_values, nil))
  end

  def maybe_update_option_detail_values(changeset, _option, nil), do: changeset
  def maybe_update_option_detail_values(changeset, _option, []) do
    changeset |> put_assoc(:option_detail_values, [])
  end

  def maybe_update_option_detail_values(changeset, option, option_detail_values) when is_list(option_detail_values) do
    option_detail_values = ensure_correct_detail_value_structs(option_detail_values, option)
    changeset |> put_assoc(:option_detail_values, option_detail_values)
  end

  def ensure_correct_detail_value_structs(option_detail_values, option) do
    option_detail_values
    |> Enum.map(&(Map.put(&1, :option_id, option.id)))
    |> Enum.map(fn(option_detail_value) ->
      OptionDetailValue.create_changeset(%OptionDetailValue{}, option_detail_value, option.decision)
    end)
  end

  @doc """
  Wraps a query that checks for the existence of a suggested slug.

  Used as a checker with `EtheloApi.Structure.Helper.maybe_update_slug/2`
  """
  def slug_not_found_in_decision(value, changeset) do
    Option |> SlugHelper.slug_not_found_in_decision(value, changeset)
  end
end
