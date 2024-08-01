defmodule EtheloApi.Scenarios.ScenarioDisplay do
  # TODO add proper docs
  @moduledoc """
  Calculated values for a specific scenario
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias EtheloApi.Scenarios.Scenario
  alias EtheloApi.Scenarios.ScenarioDisplay
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Constraint
  alias EtheloApi.Structure.Calculation

  schema "scenario_displays" do
    belongs_to :scenario, Scenario
    belongs_to :constraint, Constraint
    belongs_to :calculation, Calculation
    belongs_to :decision, Decision

    field :is_constraint, :boolean
    field :name, :string
    field :value, :float

    timestamps(type: :utc_datetime)
  end

  @doc """
  Prepares and Validates attributes for creating a ScenarioDisplay record
  """
  def create_changeset(attrs) do
    %ScenarioDisplay{}
    |> cast(attrs, [:is_constraint, :name, :value])
    |> validate_required([:is_constraint, :name, :value])
    # db
    |> cast(attrs, [:constraint_id, :calculation_id, :decision_id, :scenario_id])
    |> validate_required([:decision_id, :scenario_id])
    |> foreign_key_constraint(:scenario_displays_calculation_id_fkey)
    |> foreign_key_constraint(:scenario_displays_constraint_id_fkey)
    |> foreign_key_constraint(:scenario_displays_decision_id_fkey)
    |> foreign_key_constraint(:scenario_displays_scenario_id_fkey)
  end
end
