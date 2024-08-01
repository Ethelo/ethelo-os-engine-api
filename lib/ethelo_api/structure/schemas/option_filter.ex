defmodule EtheloApi.Structure.OptionFilter do
  use DocsComposer, module: EtheloApi.Structure.Docs.OptionFilter

  @moduledoc """
  #{@doc_map.strings.option_filter}

  ## Fields
  #{schema_fields(@doc_map.fields)}

  ## Examples
  #{schema_examples(Map.drop(@doc_map.examples, ["Updated 1"]))}
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, warn: false
  import EtheloApi.Helpers.ValidationHelper

  alias EtheloApi.Repo
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.OptionDetail
  alias EtheloApi.Structure.OptionFilter
  alias EtheloApi.Structure.OptionCategory

  schema "option_filters" do
    belongs_to :decision, Decision, on_replace: :raise
    belongs_to :option_detail, OptionDetail, on_replace: :delete
    belongs_to :option_category, OptionCategory, on_replace: :delete

    field :match_mode, :string
    field :match_value, :string
    field :slug, :string
    field :title, :string

    timestamps(type: :utc_datetime)
  end

  @all_options_mode "all_options"
  def all_options_mode() do
    @all_options_mode
  end

  def all_options_values() do
    %{match_mode: all_options_mode(), match_value: "", slug: "all_options", title: "All Options"}
  end

  # we might add additional types in future, such as inclusion/exclusion in list, or dates
  @category_match_modes ~w(in_category not_in_category)
  @detail_match_modes ~w(equals)

  @all_match_modes [@all_options_mode] ++ @category_match_modes ++ @detail_match_modes

  @doc """
  Prepares attributes shared between create, update and import actions
  """
  def base_changeset(%OptionFilter{} = option_filter, %{} = attrs) do
    option_filter
    |> cast(
      attrs,
      [
        :match_mode,
        :match_value,
        :slug,
        :title
      ],
      empty_values: []
    )
  end

  @doc """
  Prepares and Validates associations for an OptionFilter
  """
  def cast_associations(changeset, attrs) do
    changeset
    |> cast(attrs, [:option_detail_id, :option_category_id])
  end

  @doc """
  Prepares and Validates attributes for creating an OptionFilter
  """
  def create_changeset(attrs, %Decision{} = decision) do
    attrs = stringify_match_config(attrs)
    attrs = Map.put(attrs, :match_value, Map.get(attrs, :match_value, ""))

    %OptionFilter{}
    |> base_changeset(attrs)
    |> cast_associations(attrs)
    |> put_assoc(:decision, decision, required: true)
    |> base_validations()
    |> db_validations(decision.id)
  end

  @doc """
  Prepares and Validates attributes for updating an OptionFilter

  Does not allow changing of Decision.
  """
  def update_changeset(%OptionFilter{} = option_filter, attrs) do
    option_filter = option_filter |> Repo.preload([:decision, :option_detail])

    if option_filter.match_mode == all_options_mode() do
      protected_record_changeset(OptionFilter, :id, "cannot be changed")
    else
      attrs = stringify_match_config(attrs)

      option_filter
      |> base_changeset(attrs)
      |> cast_associations(attrs)
      |> base_validations()
      |> db_validations(option_filter.decision_id)
    end
  end

  @doc """
  Validations for first stage of bulk import, cannot contain any database lookups or association data
  """
  def import_changeset(attrs, decision_id, duplicate_slugs) do
    %OptionFilter{}
    |> base_changeset(attrs)
    |> base_validations()
    |> validate_inclusion(:match_mode, @all_match_modes)
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
  default changeset for the all_options filter
  """
  def all_options_changeset(%Decision{} = decision) do
    attrs = all_options_values()
    create_changeset(attrs, decision)
  end

  @doc """
  Adds validations shared between create, update and import actions.

  Should not include any validation that touches the database
  unique_constraint and other post-query checks can be used.
  """
  def base_validations(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_required([:title, :match_mode])
    |> validate_has_word(:title)
    |> db_contraint_validations()
  end

  defp db_contraint_validations(changeset) do
    changeset
    |> unique_constraint(:slug, name: :unique_option_filter_slug_index)
    |> unique_constraint(:match_mode, name: :unique_option_filter_category_config_index)
    |> unique_constraint(:match_value, name: :unique_option_filter_detail_config_index)
    |> unique_constraint(:match_mode, name: :unique_all_options)
    |> check_constraint(:match_mode,
      name: :reference_or_all_match,
      message:
        "must specify an OptionDetail, an OptionCategory or an \"#{all_options_mode()}\" match"
    )
    |> foreign_key_constraint(:decision_id)
    |> foreign_key_constraint(:option_detail_id)
    |> foreign_key_constraint(:option_category_id)
  end

  @doc """
  Validations that require database queries. Cannot be used by import system
  """
  def db_validations(%Ecto.Changeset{} = changeset, decision_id) do
    changeset
    |> validate_source_and_match_mode()
    |> validate_unique_slug(OptionFilter)
    |> validate_optional_assoc_in_decision(decision_id, :option_detail_id, OptionDetail)
    |> validate_optional_assoc_in_decision(decision_id, :option_category_id, OptionCategory)
  end

  def validate_source_and_match_mode(changeset) do
    match_mode = get_change_with_empty(changeset, :match_mode)

    cond do
      match_mode == @all_options_mode ->
        changeset
        |> validate_empty(
          [:option_detail_id, :option_category_id, :match_value],
          "must be blank for an \"#{all_options_mode()}\" match"
        )

      match_mode in @detail_match_modes ->
        changeset
        |> validate_required([:option_detail_id, :match_value])
        |> validate_empty(:option_category_id, "must be blank for an OptionDetail match")

      match_mode in @category_match_modes ->
        changeset
        |> validate_required([:option_category_id])
        |> validate_empty(
          [:match_value, :option_detail_id],
          "must be blank for an OptionCategory match"
        )

      true ->
        changeset
        |> validate_inclusion(:match_mode, @all_match_modes)
        |> validate_either(
          :option_detail_id,
          :option_category_id,
          "must specify either an OptionDetail or an OptionCategory"
        )
    end
  end

  # force match attributes to be strings, as nil is not a valid value but an empty string is
  defp stringify_match_config(attrs) do
    attrs |> stringify_value(:match_mode) |> stringify_value(:match_value)
  end

  def export_fields() do
    [
      :id,
      :match_mode,
      :match_value,
      :option_category_id,
      :option_detail_id,
      :slug,
      :title
    ]
  end
end
