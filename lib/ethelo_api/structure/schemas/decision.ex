defmodule EtheloApi.Structure.Decision do
  use DocsComposer, module: EtheloApi.Structure.Docs.Decision

  @moduledoc """
  #{@doc_map.strings.decision}

  ## Fields
  #{schema_fields(@doc_map.fields)}

  ## Examples
  #{schema_examples(Map.drop(@doc_map.examples, ["Updated 1"]))}
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  import EtheloApi.Helpers.ValidationHelper

  alias EtheloApi.Helpers.SlugHelper

  alias EtheloApi.Structure.Decision

  schema "decisions" do
    has_many :calculations, EtheloApi.Structure.Calculation
    has_many :constraints, EtheloApi.Structure.Constraint
    has_many :criterias, EtheloApi.Structure.Criteria
    has_many :option_categories, EtheloApi.Structure.OptionCategory
    has_many :options, EtheloApi.Structure.Option
    has_many :option_details, EtheloApi.Structure.OptionDetail
    has_many :option_detail_values, EtheloApi.Structure.OptionDetailValue
    has_many :option_filters, EtheloApi.Structure.OptionFilter
    has_many :variables, EtheloApi.Structure.Variable
    has_many :bin_votes, EtheloApi.Voting.BinVote
    has_many :option_category_bin_votes, EtheloApi.Voting.OptionCategoryBinVote
    has_many :option_category_range_votes, EtheloApi.Voting.OptionCategoryRangeVote
    has_many :option_category_weights, EtheloApi.Voting.OptionCategoryWeight
    has_many :criteria_weights, EtheloApi.Voting.CriteriaWeight
    has_many :participants, EtheloApi.Voting.Participant
    has_many :scenario_configs, EtheloApi.Structure.ScenarioConfig

    field :copyable, :boolean, default: false
    field :influent_hash, :string, default: nil
    field :info, :string
    field :internal, :boolean, default: false
    field :keywords, {:array, :string}, default: []

    field :language, Ecto.Enum,
      values: ~w(en es fr-ca mn zh-cn ru ar vi)a,
      default: :en

    field :max_users, :integer, default: 20
    field :preview_decision_hash, :string, default: nil
    field :published_decision_hash, :string, default: nil
    field :slug, :string
    field :title, :string
    field :weighting_hash, :string, default: nil

    timestamps(type: :utc_datetime)
  end

  @doc """
  Validates creation or update of a Decision.

  Does not allow for child objects to be updated.
  """
  def base_changeset(%Decision{} = decision, attrs) do
    decision
    |> cast(attrs, [
      :copyable,
      :influent_hash,
      :info,
      :internal,
      :keywords,
      :language,
      :max_users,
      :preview_decision_hash,
      :published_decision_hash,
      :slug,
      :title,
      :weighting_hash
    ])
  end

  @doc """
  Prepares and Validates attributes for creating a Decision including setting up a default Criteria
  """
  def create_changeset(attrs) do
    %Decision{}
    |> base_changeset(attrs)
    |> base_validations()
    |> db_validations()
    |> put_assoc(:criterias, [%{bins: 5, title: "Approval", slug: "approval"}], required: true)
  end

  @doc """
   Prepares and Validates attributes for updating a Decision
  """
  def update_changeset(%Decision{} = decision, attrs) do
    decision
    |> base_changeset(attrs)
    |> base_validations()
    |> db_validations()
  end

  @doc """
  Validations for first stage of bulk import, cannot contain any database lookups or association data
  """
  def import_changeset(attrs) do
    %Decision{}
    |> cast(attrs, [
      :info,
      :keywords,
      :language,
      :slug,
      :title
    ])
    |> base_validations()
    |> validate_required([:slug])
  end

  def base_validations(changeset) do
    changeset
    |> validate_inclusion(:language, Ecto.Enum.values(Decision, :language))
    |> validate_required([:title])
    |> validate_has_word(:title)
    |> unique_constraint(:slug, name: :decisions_slug_index)
  end

  def db_validations(changeset) do
    changeset
    |> validate_slug
  end

  @doc """
  Generate Slug if necessary, validate presence and uniqueness
  """
  def validate_slug(%Ecto.Changeset{} = changeset) do
    unique_decision_slug = fn value, changeset ->
      Decision |> SlugHelper.slug_not_found(value, changeset)
    end

    changeset
    |> SlugHelper.maybe_update_slug(unique_decision_slug)
  end

  def export_fields() do
    [
      :info,
      :keywords,
      :language,
      :slug,
      :title
    ]
  end
end
