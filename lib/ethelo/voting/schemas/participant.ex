defmodule EtheloApi.Voting.Participant do

    use DocsComposer, module: EtheloApi.Voting.Docs.Participant

    @moduledoc """
    #{@doc_map.strings.participant}

    ## Fields
    #{schema_fields(@doc_map.fields)}

    ## Examples
    #{schema_examples(@doc_map.examples)}
    """
  use Ecto.Schema
  use Timex.Ecto.Timestamps
  import Ecto.Changeset
  import Ecto.Query, warn: false
  import EtheloApi.Helpers.ValidationHelper

  alias EtheloApi.Voting.Participant
  alias EtheloApi.Structure.Decision

  schema "participants" do
    belongs_to :decision, Decision, on_replace: :raise
    has_many :bin_votes, EtheloApi.Voting.BinVote
    has_many :option_category_bin_votes, EtheloApi.Voting.OptionCategoryBinVote
    has_many :option_category_range_votes, EtheloApi.Voting.OptionCategoryRangeVote
    has_many :option_category_weights, EtheloApi.Voting.OptionCategoryWeight
    has_many :criteria_weights, EtheloApi.Voting.CriteriaWeight

    field :weighting, :decimal, default: Decimal.from_float(1.0), precision: 5, scale: 10
    field :auxiliary, :string #deprecated
    field :influent_hash, :string, default: nil

    timestamps()
  end

  @doc """
  Adds validations shared between update and create actions
  - required fields: weighting
  - weighting between 1..10000
  """
  def add_validations(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_required(:weighting)
    |> validate_number(:weighting, greater_than_or_equal_to: Decimal.from_float(0.0), less_than: Decimal.from_float(99999.99))
  end

  defp base_changeset(%Participant{} = participant, attrs) do
    attrs = attrs |> stringify_value(:weighting) #ensure floats/decimals are parsed

    participant
    |> cast(attrs, [:weighting, :auxiliary, :influent_hash ])
  end

  @doc """
  Validates creation of a Participant on a Decision.
  """
  def create_changeset(%Participant{} = participant, attrs, %Decision{} = decision) do
    participant
    |> base_changeset(attrs)
    |> put_assoc(:decision, decision, required: true)
    |> add_validations()
  end

  @doc """
  Validates update of a Participant.

  Does not allow changing of Decision.
  """
  def update_changeset(%Participant{} = participant, attrs) do
    participant
    |> base_changeset(attrs)
    |> add_validations()
  end
end
