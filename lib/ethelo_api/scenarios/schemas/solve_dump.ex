defmodule EtheloApi.Scenarios.SolveDump do
  @moduledoc """
  Dump of the submitted files used in an engine call,
  along with the engine output and error messages

  This is a debug tool

  There is no realtime database validation because these are only created in by the ScenarioImport process, which
  enforces the uniqueness, presence and correct decision
  """
  use DocsComposer, module: EtheloApi.Scenarios.Docs.SolveDump

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias EtheloApi.Structure.Decision
  alias EtheloApi.Scenarios.SolveDump
  alias EtheloApi.Scenarios.ScenarioSet
  alias EtheloApi.Voting.Participant

  schema "solve_dumps" do
    belongs_to :decision, Decision, on_replace: :delete
    belongs_to :scenario_set, ScenarioSet, on_replace: :delete
    belongs_to :participant, Participant, on_replace: :delete

    field :decision_json, :string
    field :influents_json, :string
    field :weights_json, :string
    field :config_json, :string
    field :response_json, :string
    field :error, :string
    timestamps(type: :utc_datetime)
  end

  @doc """
  Prepares and Validates attributes for creating a ScenarioDisplay record
  """

  def upsert_changeset(%{} = attrs) do
    %SolveDump{}
    |> cast(attrs, [
      :decision_json,
      :influents_json,
      :weights_json,
      :config_json,
      :response_json,
      :error
    ])
    |> cast(attrs, [:scenario_set_id, :participant_id, :decision_id])
    # db
    |> validate_required([:decision_id, :scenario_set_id])
    |> unique_constraint(:scenario_set_id, name: :unique_scenario_set_solve_dump)
    |> foreign_key_constraint(:solve_dumps_decision_id_fkey)
    |> foreign_key_constraint(:solve_dumps_participant_id_fkey)
    |> foreign_key_constraint(:solve_dumps_scenario_set_id_fkey)
  end
end
