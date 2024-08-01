defmodule EtheloApi.Structure.Variable do
  use DocsComposer, module: EtheloApi.Structure.Docs.Variable

  @moduledoc """
  #{@doc_map.strings.variable}

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
  alias EtheloApi.Repo
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Variable
  alias EtheloApi.Structure.OptionDetail
  alias EtheloApi.Structure.OptionFilter
  alias EtheloApi.Structure.Calculation

  schema "variables" do
    belongs_to :decision, Decision, on_replace: :raise
    belongs_to :option_filter, OptionFilter, on_replace: :raise
    belongs_to :option_detail, OptionDetail, on_replace: :raise
    many_to_many :calculations, Calculation, join_through: "calculation_variables", on_replace: :delete

    field :method, VariableMethodEnum
    field :slug, :string
    field :title, :string

    timestamps()
  end

  @filter_methods ~w(count_selected count_all)a
  @detail_methods ~w(sum_selected mean_selected sum_all mean_all)a

  @doc """
  Adds validations shared between update and create actions
  - required fields
  - valid title
  - require option detail or option filter
  - validate mode allowed for source
  - maybe update slug
  """
  def add_validations(%Ecto.Changeset{} = changeset, decision) do
    changeset
    |> validate_required([:title, :method])
    |> validate_format(:title, unicode_word_check_regex(), message: "must include at least one word")
    |> validate_source_and_method(decision)
    |> unique_constraint(:method, name: :unique_detail_variable_config_index)
    |> unique_constraint(:method, name: :unique_filter_variable_config_index)
    |> unique_constraint(:slug, name: :unique_variable_slug_index)
    |> check_constraint(:option_detail_id, name: :detail_or_filter_required, message: "can't be blank if there is no OptionFilter specified")
    |> check_constraint(:option_filter_id, name: :detail_or_filter_required, message: "can't be blank if there is no OptionDetail specified")
  end

  def add_slug_validation(changeset) do
    changeset |> SlugHelper.maybe_update_slug(&slug_not_found_in_decision/2, &slugger/1)
  end

  def validate_source_and_method(changeset, decision) do
    detail_assoc = validate_assoc_in_decision(changeset, decision, :option_detail_id, OptionDetail)
    filter_assoc = validate_assoc_in_decision(changeset, decision, :option_filter_id, OptionFilter)
    validate_source_and_method(changeset, detail_assoc, filter_assoc)
  end

  def validate_source_and_method(changeset, {_, _, nil}, {_, _, nil}) do
    changeset
    |> validate_required([:option_detail_id], message: "can't be blank if there is no OptionFilter specified")
    |> validate_required([:option_filter_id], message: "can't be blank if there is no OptionDetail specified")
  end

  def validate_source_and_method(_, {detail_changeset, option_detail, _}, {_, _, nil})  do
    detail_changeset
    |> validate_inclusion(:method, @detail_methods)
    |> validate_number_detail(option_detail)
  end

  def validate_source_and_method(_, {_, _, nil}, {filter_changeset, _, _})  do
    validate_inclusion(filter_changeset, :method, @filter_methods)
  end

  def validate_source_and_method(changeset, _, _) do
    changeset
    |> validate_empty(:option_detail_id, "must be blank if there is an OptionFilter specified")
    |> validate_empty(:option_filter_id, "must be blank if there is an OptionDetail specified")
  end

  def validate_number_detail(changeset, nil), do: changeset
  def validate_number_detail(changeset, option_detail) do
    if option_detail.format in [:integer, :float] do
      changeset
    else
      changeset |> add_error(:option_detail_id, "must be a number detail", [code: :foreign])
    end
  end

  @doc """
  Validates creation of an Variable on a Decision.
  """
  def create_changeset(%Variable{} = variable, attrs, %Decision{} = decision) do
    variable
    |> cast(attrs, [:title, :slug, :method, :option_detail_id, :option_filter_id])
    |> Ecto.Changeset.put_assoc(:decision, decision, required: true)
    |> add_validations(decision)
    |> add_slug_validation()
  end

  @doc """
  Validates update of an Variable.

  Does not allow changing of Decision
  """
  def update_changeset(%Variable{} = variable, attrs) do
    variable = preload_associations(variable)
    used_variable_changeset(variable, attrs)
    |> validate_slug_change(Enum.count(variable.calculations))
  end

  def used_variable_changeset(%Variable{} = variable, attrs) do
    variable = preload_associations(variable)
    variable
    |> cast(attrs, [:title, :slug, :method, :option_detail_id, :option_filter_id])
    |> add_validations(variable.decision)
    |> add_slug_validation()
  end

  defp preload_associations(variable) do
    variable
    |> Repo.preload([:decision, :option_detail, :option_filter])
    |> Repo.preload([:calculations], force: true)
  end

  def validate_slug_change(changeset, 0), do: add_slug_validation(changeset)
  def validate_slug_change(changeset, _) do
    changeset |> add_error(:slug, "cannot be changed, variable in use", [code: :foreign])
  end

  @doc """
  Wraps a query that checks for the existence of a suggested slug.

  Used as a checker with `EtheloApi.Structure.Helper.maybe_update_slug/2`
  """
  def slug_not_found_in_decision(value, changeset) do
    Variable |> SlugHelper.slug_not_found_in_decision(value, changeset)
  end

  def slugger(value) do
    value
    |> String.downcase()
    |> String.trim()
    |> String.replace(~r/-+([^0-9])/, "_\\1")   # keep double negatives in front of numbers, collapse others
    |> String.replace(~r/[^a-z0-9\-]+/iu, "_")
    |> String.replace(~r/__+/, "_")
    |> String.replace(~r/^([0-9])/, "v\\1")
    |> String.replace(~r/-/, "_")
    |> String.trim("_")
  end
end
