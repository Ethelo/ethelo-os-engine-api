defmodule EtheloApi.Voting.BinVote do

  use DocsComposer, module: EtheloApi.Voting.Docs.BinVote

  @moduledoc """
  #{@doc_map.strings.bin_vote}

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
  alias EtheloApi.Repo
  alias EtheloApi.Voting.Participant
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Criteria
  alias EtheloApi.Structure.Option
  alias EtheloApi.Voting.BinVote

  schema "bin_votes" do
    belongs_to :decision, Decision, on_replace: :raise
    belongs_to :criteria, Criteria, on_replace: :delete
    belongs_to :participant, Participant, on_replace: :delete
    belongs_to :option, Option, on_replace: :delete

    field :bin, :integer

    timestamps()
  end

  @doc """
  Adds validations shared between update and create actions
  - required fields: participant_id, bin, criteria_id
  - bin between 1..100
  - validate Criteria
  - validate Participant
  """
  def add_validations(%Ecto.Changeset{} = changeset, decision) do
    changeset
    |> validate_required([:participant_id, :option_id, :criteria_id, :bin])
    |> validate_number(:bin, greater_than_or_equal_to: 1, less_than_or_equal_to: 9)
    |> validate_criteria(decision)
    |> validate_option(decision)
    |> validate_participant(decision)
    |> unique_constraint(:bin, name: :unique_participant_bin_vote_index)
  end

  defp base_changeset(%BinVote{} = bin_vote, attrs) do
    bin_vote
    |> cast(attrs, [:participant_id, :criteria_id, :option_id, :bin])
  end

  defp validate_criteria(changeset, decision) do
    {changeset, _, _} = validate_assoc_in_decision(changeset, decision, :criteria_id, Criteria)
    changeset
  end

  defp validate_participant(changeset, decision) do
    {changeset, _, _} = validate_assoc_in_decision(changeset, decision, :participant_id, Participant)
    changeset
  end

  defp validate_option(changeset, decision) do
    {changeset, _, _} = validate_assoc_in_decision(changeset, decision, :option_id, Option)
    changeset
  end

  @doc """
  Validates creation of an BinVote on a Decision.
  """
  def create_changeset(%BinVote{} = bin_vote, attrs, %Decision{} = decision) do
    bin_vote
    |> base_changeset(attrs)
    |> put_assoc(:decision, decision, required: true)
    |> add_validations(decision)
  end

  @doc """
  Validates update of an BinVote.

  Does not allow changing of Decision.
  """
  def update_changeset(%BinVote{} = bin_vote, attrs) do
    bin_vote = bin_vote |> Repo.preload([:decision, :criteria, :participant])

    bin_vote
    |> base_changeset(attrs)
    |> add_validations(bin_vote.decision)
  end
end
