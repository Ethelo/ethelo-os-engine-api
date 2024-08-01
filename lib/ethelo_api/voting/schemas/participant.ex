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

    # precision: 5, scale: 10
    field :weighting, :decimal, default: Decimal.from_float(1.0)
    field :influent_hash, :string, default: nil

    timestamps(type: :utc_datetime)
  end

  @doc """
  Adds validations shared between update and create actions
  """
  def add_validations(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_required(:weighting)
    |> validate_number(:weighting,
      greater_than_or_equal_to: Decimal.from_float(0.0),
      less_than: Decimal.from_float(99_999.99)
    )
  end

  defp base_changeset(%Participant{} = participant, attrs) do
    # ensure floats/decimals are parsed
    attrs = attrs |> stringify_value(:weighting)

    participant |> cast(attrs, [:weighting, :influent_hash])
  end

  @doc """
  Validates creation of a Participant on a Decision.
  """
  def create_changeset(attrs, %Decision{} = decision) do
    %Participant{}
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
