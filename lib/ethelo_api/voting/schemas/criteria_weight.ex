defmodule EtheloApi.Voting.CriteriaWeight do
  use DocsComposer, module: EtheloApi.Voting.Docs.CriteriaWeight

  @moduledoc """
  #{@doc_map.strings.criteria_weight}

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
  alias EtheloApi.Voting.CriteriaWeight

  schema "criteria_weights" do
    belongs_to :decision, Decision, on_replace: :raise
    belongs_to :criteria, Criteria, on_replace: :delete
    belongs_to :participant, Participant, on_replace: :delete

    field :weighting, :integer

    timestamps(type: :utc_datetime)
  end

  defp base_changeset(%CriteriaWeight{} = criteria_weight, attrs) do
    criteria_weight
    |> cast(attrs, [:participant_id, :criteria_id, :weighting])
  end

  @doc """
  Validates creation of a CriteriaWeight on a Decision.
  """
  def create_changeset(attrs, %Decision{} = decision) do
    %CriteriaWeight{}
    |> base_changeset(attrs)
    |> put_assoc(:decision, decision, required: true)
    |> add_validations(decision)
  end

  @doc """
  Validates update of a CriteriaWeight.

  Does not allow changing of Decision.
  """
  def update_changeset(%CriteriaWeight{} = criteria_weight, attrs) do
    criteria_weight = criteria_weight |> Repo.preload([:decision, :criteria, :participant])

    criteria_weight
    |> base_changeset(attrs)
    |> add_validations(criteria_weight.decision_id)
  end

  @doc """
  Adds validations shared between update and create actions
  """
  def add_validations(%Ecto.Changeset{} = changeset, decision_id) do
    changeset
    |> validate_required([:participant_id, :criteria_id, :weighting])
    |> validate_number(:weighting, greater_than_or_equal_to: 1, less_than_or_equal_to: 100)
    |> validate_assoc_in_decision(decision_id, :criteria_id, Criteria)
    |> validate_assoc_in_decision(decision_id, :participant_id, Participant)
    |> unique_constraint(:weighting, name: :unique_participant_criteria_weight_index)
    |> foreign_key_constraint(:decision_id)
    |> foreign_key_constraint(:participant_id)
    |> foreign_key_constraint(:criteria_id)
  end
end
