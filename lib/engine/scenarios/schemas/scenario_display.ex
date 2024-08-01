defmodule Engine.Scenarios.ScenarioDisplay do

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  use Timex.Ecto.Timestamps

  alias Engine.Scenarios.Scenario
  alias Engine.Scenarios.ScenarioDisplay
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Constraint
  alias EtheloApi.Structure.Calculation

  schema "scenario_displays" do
    belongs_to :scenario, Scenario
    belongs_to :constraint, Constraint
    belongs_to :calculation, Calculation
    belongs_to :decision, Decision

    field :name, :string
    field :value, :float
    field :is_constraint, :boolean

    timestamps()
  end

  def add_validations(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_required([:name, :value, :is_constraint, :decision_id])
  end

  def base_changeset(%ScenarioDisplay{} = scenario_display, attrs) do
    scenario_display
    |> cast(attrs, [:constraint_id, :calculation_id, :name, :value, :is_constraint, :decision_id])
  end

  def create_changeset(%ScenarioDisplay{} = scenario_display, attrs, %Scenario{} = scenario) do
    scenario_display
    |> base_changeset(attrs)
    |> Ecto.Changeset.put_assoc(:scenario, scenario, required: true)
    |> add_validations
  end

  def update_changeset(%ScenarioDisplay{} = scenario_display, attrs) do
    scenario_display
    |> base_changeset(attrs)
    |> add_validations
  end
end
