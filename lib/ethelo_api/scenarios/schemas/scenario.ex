defmodule EtheloApi.Scenarios.Scenario do
  use DocsComposer, module: EtheloApi.Scenarios.Docs.Scenario

  @moduledoc """
  An individual Scenario and associated ScenarioStats.
  A Scenario is defined as a combination of Options

  There is no realtime database validation because these are only created in by the ScenarioImport process, which
  enforces the uniqueness, presence and correct decision
  """
  # TODO proper module doc
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias EtheloApi.Structure.Option
  alias EtheloApi.Scenarios.ScenarioSet
  alias EtheloApi.Scenarios.Scenario
  alias EtheloApi.Scenarios.ScenarioDisplay
  alias EtheloApi.Structure.Decision

  schema "scenarios" do
    belongs_to :scenario_set, ScenarioSet
    belongs_to :decision, Decision
    has_many :scenario_displays, ScenarioDisplay
    many_to_many :options, Option, join_through: "scenarios_options", on_replace: :delete

    field :collective_identity, :float, default: 0.5
    field :global, :boolean
    field :minimize, :boolean

    # can be pending/success/error
    # TODO: make this a proper enum
    field :status, :string

    field :tipping_point, :float

    timestamps(type: :utc_datetime)
  end

  @doc """
  Prepares and Validates attributes for creating a Scenario
  """
  def create_changeset(attrs) do
    %Scenario{}
    |> cast(
      attrs,
      [:collective_identity, :global, :minimize, :status, :tipping_point]
    )
    |> validate_required([:status, :collective_identity, :tipping_point, :minimize, :global])
    # db
    |> cast(attrs, [:scenario_set_id, :decision_id])
    |> validate_required([:decision_id, :scenario_set_id])
    |> foreign_key_constraint(:scenarios_decision_id_fkey)
    |> foreign_key_constraint(:scenarios_scenario_set_id_fkey)
  end
end
