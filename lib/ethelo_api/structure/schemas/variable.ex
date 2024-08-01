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

    many_to_many :calculations, Calculation,
      join_through: "calculation_variables",
      on_replace: :delete

    field :method, Ecto.Enum,
      values: [:count_selected, :count_all, :sum_selected, :mean_selected, :sum_all, :mean_all]

    field :slug, :string
    field :title, :string

    timestamps(type: :utc_datetime)
  end

  @filter_methods ~w(count_selected count_all)a
  @detail_methods ~w(sum_selected mean_selected sum_all mean_all)a

  @doc """
  Prepares attributes shared between create, update and import actions
  """
  def base_changeset(%Variable{} = variable, %{} = attrs) do
    variable
    |> cast(
      attrs,
      [
        :method,
        :slug,
        :title
      ]
    )
  end

  @doc """
  Prepares and Validates associations for a Variable
  """
  def cast_associations(changeset, attrs) do
    changeset
    |> cast(
      attrs,
      [
        :option_detail_id,
        :option_filter_id
      ],
      empty_values: []
    )
  end

  @doc """
  Prepares and Validates attributes for creating a Variable
  """
  def create_changeset(attrs, %Decision{} = decision) do
    %Variable{}
    |> base_changeset(attrs)
    |> cast_associations(attrs)
    |> put_assoc(:decision, decision, required: true)
    |> base_validations()
    |> db_validations(decision.id)
  end

  @doc """
  Prepares and Validates attributes for updating a Variable

  Does not allow changing of Decision.
  """
  def update_changeset(%Variable{} = variable, attrs) do
    calc_query =
      Calculation |> select([t], map(t, [:id, :slug, :expression, :public, :decision_id]))

    variable = variable |> Repo.preload([calculations: calc_query], force: true)

    used_variable_changeset(variable, attrs)
    |> validate_slug_change(Enum.count(variable.calculations))
  end

  def used_variable_changeset(%Variable{} = variable, attrs) do
    variable = variable |> Repo.preload([:decision, :option_detail, :option_filter])

    variable
    |> base_changeset(attrs)
    |> cast_associations(attrs)
    |> base_validations()
    |> db_validations(variable.decision_id)
  end

  @doc """
  Validations for first stage of bulk import, cannot contain any database lookups or association data
  """
  def import_changeset(attrs, decision_id, duplicate_slugs) do
    %Variable{}
    |> base_changeset(attrs)
    |> base_validations()
    |> validate_inclusion(:method, Ecto.Enum.values(Variable, :method))
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
  end

  @doc """
  Adds validations shared between create, update and import actions.
  Should not include any validation that touches the database
  unique_constraint and other post-query checks can be used.
  """
  def base_validations(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_required([:title, :method])
    |> validate_has_word(:title)
    |> db_contraint_validations()
  end

  defp db_contraint_validations(changeset) do
    changeset
    |> unique_constraint(:method, name: :unique_detail_variable_config_index)
    |> unique_constraint(:method, name: :unique_filter_variable_config_index)
    |> unique_constraint(:slug, name: :unique_variable_slug_index)
    |> check_constraint(:option_detail_id,
      name: :detail_or_filter_required,
      message: "can't be blank if there is no OptionFilter specified"
    )
    |> check_constraint(:option_filter_id,
      name: :detail_or_filter_required,
      message: "can't be blank if there is no OptionDetail specified"
    )
    |> foreign_key_constraint(:decision_id)
    |> foreign_key_constraint(:option_detail_id)
    |> foreign_key_constraint(:option_filter_id)
  end

  @doc """
  Validations that require database queries. Cannot be used by import system
  """
  def db_validations(%Ecto.Changeset{} = changeset, decision_id) do
    changeset
    |> validate_source_and_method()
    |> validate_variable_slug()
    |> validate_optional_assoc_in_decision(decision_id, :option_detail_id, OptionDetail)
    |> validate_optional_assoc_in_decision(decision_id, :option_filter_id, OptionFilter)
    |> validate_numeric_option_detail(decision_id)
  end

  def validate_numeric_option_detail(changeset, %{id: decision_id}),
    do: validate_numeric_option_detail(changeset, decision_id)

  def validate_numeric_option_detail(changeset, decision_id) do
    option_detail_id = get_field(changeset, :option_detail_id)

    if is_nil(option_detail_id) do
      changeset
    else
      exists =
        EtheloApi.Structure.option_detail_exists(decision_id, %{
          id: option_detail_id,
          format: [:float, :integer]
        })

      if exists do
        changeset
      else
        changeset
        |> add_error(:option_detail_id, "must be a OptionDetail with number format",
          code: :invalid
        )
      end
    end
  end

  def validate_variable_slug(changeset) do
    check_fn = fn value, changeset ->
      Variable |> SlugHelper.slug_not_found_in_decision(value, changeset)
    end

    changeset
    |> SlugHelper.maybe_update_slug(check_fn, &slugger/1)
  end

  def validate_source_and_method(changeset) do
    method = get_change_with_empty(changeset, :method)

    cond do
      method in @detail_methods ->
        changeset
        |> validate_required([:option_detail_id])
        |> validate_empty(:option_filter_id, "must be blank for an OptionDetail match")

      method in @filter_methods ->
        changeset
        |> validate_required([:option_filter_id])
        |> validate_empty(:option_detail_id, "must be blank for an OptionFilter match")

      true ->
        changeset
        |> validate_inclusion(:method, Ecto.Enum.values(Variable, :method))
        |> validate_either(
          :option_detail_id,
          :option_filter_id,
          "must specify either an OptionDetail or an OptionFilter"
        )
    end
  end

  def validate_number_detail(changeset, nil), do: changeset

  def validate_number_detail(changeset, option_detail) do
    if option_detail.format in [:integer, :float] do
      changeset
    else
      changeset |> add_error(:option_detail_id, "must be a number detail", code: :foreign)
    end
  end

  def validate_slug_change(changeset, 0), do: validate_variable_slug(changeset)

  def validate_slug_change(changeset, _) do
    changeset |> add_error(:slug, "cannot be changed, Variable in use", code: :foreign)
  end

  def slugger(value) do
    value
    |> String.downcase()
    |> String.trim()
    # keep double negatives in front of numbers, collapse others
    |> String.replace(~r/-+([^0-9])/, "_\\1")
    |> String.replace(~r/[^a-z0-9\-]+/iu, "_")
    |> String.replace(~r/__+/, "_")
    |> String.replace(~r/^([0-9])/, "v\\1")
    |> String.replace(~r/-/, "_")
    |> String.trim("_")
  end

  def export_fields() do
    [
      :id,
      :method,
      :option_detail_id,
      :option_filter_id,
      :slug,
      :title
    ]
  end
end
