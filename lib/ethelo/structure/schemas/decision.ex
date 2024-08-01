defmodule EtheloApi.Structure.Decision do
  require OK

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
  use Timex.Ecto.Timestamps

  alias EtheloApi.Structure.Decision

  schema "decisions" do
    field :title, :string
    field :slug, :string
    field :info, :string
    field :copyable, :boolean, default: false
    field :internal, :boolean, default: false
    field :max_users, :integer, default: 20
    field :language, :string, default: "en"
    field :keywords, {:array, :string}, default: []
    field :published_decision_hash, :string, default: nil
    field :preview_decision_hash, :string, default: nil
    field :influent_hash, :string, default: nil
    field :weighting_hash, :string, default: nil

    has_many :calculations, EtheloApi.Structure.Calculation
    has_many :constraints, EtheloApi.Structure.Constraint
    has_many :criterias, EtheloApi.Structure.Criteria
    has_many :option_categories, EtheloApi.Structure.OptionCategory
    has_many :option_details, EtheloApi.Structure.OptionDetail
    has_many :option_detail_values, EtheloApi.Structure.OptionDetailValue
    has_many :option_filters, EtheloApi.Structure.OptionFilter
    has_many :options, EtheloApi.Structure.Option
    has_many :scenario_configs, Engine.Scenarios.ScenarioConfig
    has_many :variables, EtheloApi.Structure.Variable
    has_many :bin_votes, EtheloApi.Voting.BinVote
    has_many :option_category_bin_votes, EtheloApi.Voting.OptionCategoryBinVote
    has_many :option_category_range_votes, EtheloApi.Voting.OptionCategoryRangeVote
    has_many :option_category_weights, EtheloApi.Voting.OptionCategoryWeight
    has_many :criteria_weights, EtheloApi.Voting.CriteriaWeight
    has_many :participants, EtheloApi.Voting.Participant
    timestamps()
  end

  @doc """
  Wraps a query that checks for the existence of a suggested slug.

  Used as a checker with `EtheloApi.Structure.Helper.maybe_update_slug/2`
  """
  def slug_not_found(value, changeset) do
    Decision |> SlugHelper.slug_not_found(value, changeset)
  end

  @doc """
  Creates a new decision, including setting up a default criteria
  """
  def create_changeset(%Decision{} = decision, attrs) do
    decision
    |> changeset(attrs)
    |> put_assoc(:criterias, [%{bins: 5, title: "Approval", slug: "approval"}], required: true)
  end

  @doc """
  Creates a new decision, including setting up a default criteria
  """
  def import_changeset(%Decision{} = decision, attrs) do
    decision |> changeset(attrs)
  end

  @doc """
  Validates creation or update of a Decision.

  Does not allow for child objects to be updated.
  """
  def changeset(%Decision{} = decision, attrs) do
    decision
    |> cast(attrs, [
      :title, :slug, :info, :copyable, :internal, :max_users, :language, :keywords,
      :published_decision_hash, :preview_decision_hash,
      :influent_hash, :weighting_hash
    ])
    |> validate_inclusion(:language, DecisionLanguageEnum.__valid_values__())
    |> validate_required([:title])
    |> validate_format(:title, unicode_word_check_regex(), message: "must include at least one word")
    |> SlugHelper.maybe_update_slug(&slug_not_found/2)
    |> unique_constraint(:slug, name: :decisions_slug_index)
  end

end
