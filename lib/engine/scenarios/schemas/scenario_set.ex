defmodule Engine.Scenarios.ScenarioSet do
  use DocsComposer, module: Engine.Scenarios.Docs.ScenarioSet

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  use Timex.Ecto.Timestamps

  alias EtheloApi.Structure.Decision
  alias Engine.Scenarios.Scenario
  alias Engine.Scenarios.ScenarioSet
  alias Engine.Scenarios.SolveDump
  alias Engine.Scenarios.ScenarioConfig
  alias EtheloApi.Voting.Participant

  schema "scenario_sets" do
    has_many :scenarios, Scenario
    has_one :solve_dump, SolveDump

    belongs_to :decision, Decision, on_replace: :raise
    belongs_to :scenario_config, ScenarioConfig, on_replace: :delete
    belongs_to :participant, Participant, on_replace: :delete

    field :status, :string # can be pending/success/error  TODO: make this a proper enum
    field :json_stats, :string
    field :parsed_stats, {:array, :map}, virtual: true
    field :hash, :string
    field :error, :string
    field :cached_decision, :boolean
    field :engine_start, Timex.Ecto.DateTime
    field :engine_end, Timex.Ecto.DateTime
    timestamps()
  end

  def add_validations(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_required([:decision_id, :status])
  end

  def base_changeset(%ScenarioSet{} = scenario_set, attrs) do
    scenario_set
    |> cast(attrs, [:decision_id, :scenario_config_id, :participant_id,
      :status, :json_stats, :parsed_stats, :hash, :error, :cached_decision,
      :updated_at, :engine_start, :engine_end])
  end

  def create_changeset(%ScenarioSet{} = scenario_set, attrs) do
    scenario_set
    |> base_changeset(attrs)
    |> add_validations
  end

  def update_changeset(%ScenarioSet{} = scenario_set, attrs) do
    scenario_set
    |> base_changeset(attrs)
    |> add_validations
  end
end
