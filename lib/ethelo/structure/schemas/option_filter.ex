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
  use Timex.Ecto.Timestamps

  import Ecto.Changeset
  import Ecto.Query, warn: false
  import EtheloApi.Helpers.ValidationHelper

  alias EtheloApi.Helpers.SlugHelper
  alias EtheloApi.Repo
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.OptionDetail
  alias EtheloApi.Structure.OptionFilter
  alias EtheloApi.Structure.OptionCategory

  schema "option_filters" do
    belongs_to :decision, Decision, on_replace: :raise
    belongs_to :option_detail, OptionDetail, on_replace: :delete
    belongs_to :option_category, OptionCategory, on_replace: :delete

    field :title, :string
    field :slug, :string
    field :match_mode, :string
    field :match_value, :string
    timestamps()
  end

  @all_options_mode "all_options"
  def all_options_mode() do
    @all_options_mode
  end

  def all_options_values() do
    %{match_mode: all_options_mode(), match_value: "", slug: "all_options", title: "All Options"}
  end

  # this is too volatile to set as a postgres enum.
  # we might add additional types in future, such as inclusion/exclusion
  @category_match_modes ~w(in_category not_in_category)
  @detail_match_modes ~w(equals)
  @date_match_modes ~w(
    date
    year month month_year day_of_month day_of_week day_of_year week_of_year
    hour_24 hour_12 minutes time_24_hour time_12_hour am_pm
  )

  @doc """
  Adds validations shared between update and create actions
  - required fields: title, match_mode, match_value, option_detail_id
  - valid title
  - maybe update slug
  - validate OptionDetail
  - match mode appropriate for option detail
  """
  def add_validations(%Ecto.Changeset{} = changeset, decision) do
    changeset
    |> validate_required([:title, :match_mode])
    |> validate_format(:title, unicode_word_check_regex(), message: "must include at least one word")
    |> maybe_validate_source_and_match_mode(decision)
    |> SlugHelper.maybe_update_slug(&slug_not_found_in_decision/2)
    |> unique_constraint(:slug, name: :unique_option_filter_slug_index)
    |> unique_constraint(:match_mode, name: :unique_option_filter_category_config_index)
    |> unique_constraint(:match_value, name: :unique_option_filter_detail_config_index)
    |> unique_constraint(:match_mode, name: :unique_all_options)
    |> check_constraint(:match_mode, name: :reference_or_all_match, message: "must specify an OptionDetail, an OptionCategory or an \"#{all_options_mode()}\" match")
  end

  defp maybe_validate_source_and_match_mode(changeset, decision) do
    case match_mode_value(changeset) do
      @all_options_mode -> validate_all_options_match(changeset)
      _ -> validate_source_and_match_mode(changeset, decision)
    end
  end

  defp validate_all_options_match(changeset) do
    changeset
    |> validate_empty(:option_detail_id, "must be blank for an \"#{all_options_mode()}\" match")
    |> validate_empty(:option_category_id, "must be blank for an \"#{all_options_mode()}\" match")
    |> validate_empty(:match_value, "must be blank for an \"#{all_options_mode()}\" match")
  end

  def validate_source_and_match_mode(changeset, decision) do
    detail_assoc = validate_assoc_in_decision(changeset, decision, :option_detail_id, OptionDetail)
    category_assoc = validate_assoc_in_decision(changeset, decision, :option_category_id, OptionCategory)
    validate_source_and_match_mode(changeset, detail_assoc, category_assoc)
  end

  # no association
  def validate_source_and_match_mode(changeset, {_, _, nil}, {_, _, nil}) do
    changeset
    |> validate_required([:option_detail_id], message: "can't be blank if there is no OptionCategory specified")
    |> validate_required([:option_category_id], message: "can't be blank if there is no OptionDetail specified")
  end

  # detail match
  def validate_source_and_match_mode(_, {detail_changeset, option_detail, _}, {_, _, nil})  do
    cond do
      option_detail == nil -> validate_inclusion(detail_changeset, :match_mode, @detail_match_modes)
      to_string(option_detail.format) == "datetime" -> validate_inclusion(detail_changeset, :match_mode, @date_match_modes)
      true -> validate_inclusion(detail_changeset, :match_mode, @detail_match_modes)
    end
  end

  # category match
  def validate_source_and_match_mode(_, {_, _, nil}, {category_changeset, _, _})  do
    category_changeset
    |> validate_inclusion(:match_mode, @category_match_modes)
    |> validate_empty(:match_value, "must be blank for an OptionCategory match")
  end

  # both associated
  def validate_source_and_match_mode(changeset, _, _) do
    changeset
    |> validate_empty(:option_detail_id, "must be blank if there is an OptionCategory specified")
    |> validate_empty(:option_category_id, "must be blank if there is an OptionDetail specified")
  end

  defp match_mode_value(changeset) do
    case fetch_field(changeset, :match_mode) do
      {_, value} -> value
      _ -> nil
    end
  end

  @doc """
  Validates creation of an OptionFilter on a Decision.
  """
  def create_changeset(%OptionFilter{} = option_filter, attrs, %Decision{} = decision) do
    attrs = stringify_match_config(attrs)
    attrs = Map.put(attrs, :match_value, Map.get(attrs, :match_value, ""))

    option_filter
    |> change()
    |> allow_empty_strings()
    |> cast(attrs, [:title, :slug, :match_mode, :match_value, :option_detail_id, :option_category_id])
    |> Ecto.Changeset.put_assoc(:decision, decision, required: true)
    |> add_validations(decision)
  end

  @doc """
  Validates update of an OptionFilter.

  Does not allow changing of Decision.
  """
  def update_changeset(%OptionFilter{} = option_filter, attrs) do
    option_filter = option_filter |> Repo.preload([:decision, :option_detail])
    attrs = stringify_match_config(attrs)

    changeset = option_filter |> change |> allow_empty_strings

    if option_filter.match_mode == all_options_mode() do
      protected_record_changeset(OptionFilter, :id, "cannot be changed")
    else
      changeset
      |> cast(attrs, [:title, :slug, :match_mode, :match_value, :option_detail_id, :option_category_id])
      |> add_validations(option_filter.decision)
    end
  end

  @doc """
  default changeset for the all_options filter
  """
  def all_options_changeset(%Decision{} = decision) do
    attrs = all_options_values()
    %OptionFilter{} |> create_changeset(attrs, decision)
  end

  # force match attributes to be strings, as nil is not a valid value but an empty string is
  defp stringify_match_config(attrs) do
    attrs |> stringify_value(:match_mode) |> stringify_value(:match_value)
  end

  @doc """
  Wraps a query that checks for the existence of a suggested slug.

  Used as a checker with `EtheloApi.Structure.Helper.maybe_update_slug/2`
  """
  def slug_not_found_in_decision(value, changeset) do
    OptionFilter |> SlugHelper.slug_not_found_in_decision(value, changeset)
  end

end
