defmodule Engine.Scenarios.Scenario do

  use DocsComposer, module: Engine.Scenarios.Docs.Scenario

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  use Timex.Ecto.Timestamps

  alias EtheloApi.Structure.Option
  alias Engine.Scenarios.ScenarioSet
  alias Engine.Scenarios.Scenario
  alias Engine.Scenarios.ScenarioDisplay
  alias EtheloApi.Structure.Decision

  schema "scenarios" do
    belongs_to :scenario_set, ScenarioSet
    belongs_to :decision, Decision
    has_many :scenario_displays, ScenarioDisplay
    many_to_many :options, Option, join_through: "scenarios_options", on_replace: :delete

    field :status, :string # can be pending/success/error

    field :collective_identity, :float, default: Decimal.from_float(0.5)
    field :tipping_point, :float
    field :minimize, :boolean
    field :global, :boolean

    timestamps()
  end

  def add_validations(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_required([:status, :collective_identity, :tipping_point, :minimize, :global])
  end

  def base_changeset(%Scenario{} = scenario, attrs) do
    scenario
    |> cast(attrs, [:status, :collective_identity, :tipping_point, :minimize, :global, :decision_id])
  end

  def create_changeset(%Scenario{} = scenario, attrs, %ScenarioSet{} = scenario_set) do
    scenario
    |> base_changeset(attrs)
    |> Ecto.Changeset.put_assoc(:scenario_set, scenario_set, required: true)
    |> add_validations
  end

  def update_changeset(%Scenario{} = scenario, attrs) do
    scenario
    |> base_changeset(attrs)
    |> add_validations
  end
end
