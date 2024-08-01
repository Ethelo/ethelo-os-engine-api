defmodule Engine.Scenarios.SolveDump do
  use DocsComposer, module: Engine.Scenarios.Docs.SolveDump

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  import EtheloApi.Helpers.ValidationHelper
  use Timex.Ecto.Timestamps

  alias EtheloApi.Structure.Decision
  alias Engine.Scenarios.SolveDump
  alias Engine.Scenarios.ScenarioSet
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
    timestamps()
  end

  def create_changeset(%SolveDump{} = solve_dump, attrs, %Decision{} = decision) do
    solve_dump
    |> cast(attrs, [:decision_id, :scenario_set_id, :decision_json,
    :influents_json, :weights_json, :config_json, :response_json, :error])
    |> Ecto.Changeset.put_assoc(:decision, decision, required: true)
    |> add_validations(decision)
  end

  def add_validations(%Ecto.Changeset{} = changeset, decision) do
    changeset
    |> validate_required([:decision_id, :scenario_set_id])
    |> validate_scenario_set(decision)
    |> maybe_validate_participant_id(decision)
    |> unique_constraint(:scenario_set_id, name: :unique_scenario_set_solve_dump)
  end

  defp validate_scenario_set(changeset, decision) do
    {changeset, _, _} = validate_assoc_in_decision(changeset, decision, :scenario_set_id, ScenarioSet)
    changeset
  end

  defp maybe_validate_participant_id(changeset, decision) do
    {changeset, _, _} = validate_optional_assoc_in_decision(changeset, decision, :participant_id, Participant)
    changeset
  end

end
