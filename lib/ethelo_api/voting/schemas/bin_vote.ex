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

    timestamps(type: :utc_datetime)
  end

  defp base_changeset(%BinVote{} = bin_vote, attrs) do
    bin_vote
    |> cast(attrs, [:participant_id, :criteria_id, :option_id, :bin])
  end

  @doc """
  Validates creation of an BinVote on a Decision.
  """
  def create_changeset(attrs, %Decision{} = decision) do
    %BinVote{}
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
    |> add_validations(bin_vote.decision_id)
  end

  @doc """
  Adds validations shared between update and create actions
  """
  def add_validations(%Ecto.Changeset{} = changeset, decision_id) do
    changeset
    |> validate_required([:participant_id, :option_id, :criteria_id, :bin])
    |> validate_number(:bin, greater_than_or_equal_to: 1, less_than_or_equal_to: 9)
    |> validate_assoc_in_decision(decision_id, :criteria_id, Criteria)
    |> validate_assoc_in_decision(decision_id, :participant_id, Participant)
    |> validate_assoc_in_decision(decision_id, :option_id, Option)
    |> unique_constraint(:bin, name: :unique_participant_bin_vote_index)
    |> foreign_key_constraint(:decision_id)
    |> foreign_key_constraint(:participant_id)
    |> foreign_key_constraint(:criteria_id)
    |> foreign_key_constraint(:option_id)
  end
end
