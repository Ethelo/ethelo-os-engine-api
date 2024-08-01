defmodule EtheloApi.Scenarios.ScenarioSet do
  use DocsComposer, module: EtheloApi.Scenarios.Docs.ScenarioSet

  @moduledoc """
  The result of calling solve on the engine:
  a series of indivdual scenarios including
  a 'global' Scenario that stores statics for all elements


  """
  # TODO proper module doc
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  import EtheloApi.Helpers.ValidationHelper

  alias EtheloApi.Structure.Decision
  alias EtheloApi.Scenarios.Scenario
  alias EtheloApi.Scenarios.ScenarioSet
  alias EtheloApi.Scenarios.SolveDump
  alias EtheloApi.Structure.ScenarioConfig
  alias EtheloApi.Voting.Participant

  schema "scenario_sets" do
    belongs_to :decision, Decision, on_replace: :raise
    belongs_to :scenario_config, ScenarioConfig, on_replace: :delete
    belongs_to :participant, Participant, on_replace: :delete

    has_many :scenarios, Scenario
    has_one :solve_dump, SolveDump

    field :cached_decision, :boolean

    field :engine_end, :utc_datetime

    field :engine_start, :utc_datetime

    field :error, :string

    field :hash, :string

    field :json_stats, :string

    field :parsed_stats, {:array, :map}, virtual: true

    field :status, :string
    timestamps(type: :utc_datetime)
  end

  @doc """
  Prepares attributes shared between create and update actions
  """
  def base_changeset(%ScenarioSet{} = scenario_set, %{} = attrs) do
    scenario_set
    |> cast(attrs, [
      :cached_decision,
      :engine_end,
      :engine_start,
      :error,
      :hash,
      :json_stats,
      :parsed_stats,
      :status,
      :updated_at
    ])
  end

  @doc """
  Prepares and Validates associations for an a ScenarioSet
  """
  def cast_associations(changeset, attrs) do
    changeset
    |> cast(attrs, [:participant_id, :scenario_config_id])
  end

  @doc """
  Prepares and Validates attributes for creating a ScenarioSet
  """
  def create_changeset(attrs, %Decision{} = decision) do
    %ScenarioSet{}
    |> base_changeset(attrs)
    |> cast_associations(attrs)
    |> put_assoc(:decision, decision, required: true)
    |> base_validations()
    |> db_validations(decision.id)
  end

  @doc """
  Prepares and Validates attributes for updating a ScenarioSet

  Does not allow changing of Decision
  """
  def update_changeset(%ScenarioSet{} = scenario_set, attrs) do
    scenario_set
    |> base_changeset(attrs)
    |> cast_associations(attrs)
    |> base_validations()
    |> db_validations(scenario_set.decision_id)
  end

  @doc """
  Prepares and Validates attributes for updating non association fields on a ScenarioSet
  """
  def no_assoc_changeset(%ScenarioSet{} = scenario_set, attrs) do
    scenario_set
    |> base_changeset(attrs)
    |> base_validations()
  end

  @doc """
  Adds validations shared between update and create actions
  """
  def base_validations(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_required([:status])
    |> foreign_key_constraint(:participant_id)
    |> foreign_key_constraint(:scenario_config_id)
  end

  def db_validations(%Ecto.Changeset{} = changeset, decision_id) do
    changeset
    |> validate_optional_assoc_in_decision(decision_id, :participant_id, Participant)
    |> validate_optional_assoc_in_decision(decision_id, :scenario_config_id, ScenarioConfig)
  end
end
