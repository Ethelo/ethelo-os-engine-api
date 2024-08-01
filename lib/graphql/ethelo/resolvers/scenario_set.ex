defmodule GraphQL.EtheloApi.Resolvers.ScenarioSet do
  @moduledoc """
  Resolvers for graphql.
  """

  alias Engine.Scenarios
  alias Engine.Invocation
  alias EtheloApi.Voting
  alias Engine.Scenarios.ScenarioSet
  alias Engine.Scenarios.SolveDump
  alias EtheloApi.Structure.Decision
  alias Kronky.ValidationMessage
  import GraphQL.EtheloApi.ResolveHelper
  import GraphQL.EtheloApi.BatchHelper

  @doc """
  lists all scenario_sets in a decision

  See `Engine.ScenarioSet.list_scenario_sets/1` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    latest = Map.get(modifiers, :latest, false)
    modifiers = Map.delete(modifiers, :latest)

    if latest do
      [decision |> Scenarios.get_latest_scenario_set(modifiers)] |> success()
    else
      decision |> Scenarios.list_scenario_sets(modifiers) |> success()
    end
  end

  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  triggers an Engine Call to solve a Decision creating a scenario set as a result

  See `Engine.Invocation.solve_decision/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def solve(decision, attrs) do
    scenario_config_id = Map.get(attrs, :scenario_config_id) |> sanitize_id
    participant_id = Map.get(attrs, :participant_id) |> sanitize_id
    case verify_ids([{Scenarios.ScenarioConfig, :scenario_config_id, scenario_config_id},
                     {Voting.Participant, :participant_id, participant_id}], decision.id) do
      :ok ->
        case Invocation.dispatch_solve(decision, scenario_config_id: scenario_config_id,
                                                participant_id: participant_id,
                                                cached: Map.get(attrs, :cached, false),
                                                force: Map.get(attrs, :force, false),
                                                save_dump: Map.get(attrs, :save_dump, false),
                                                async: Map.get(attrs, :async, false)
                                                ) do
          {:error, {type, error}} when is_atom(type) -> {:error, "#{type}: #{error}"}
          {:error, error} -> {:error, error}
          {:ok, %ScenarioSet{} = scenario_set} -> {:ok, scenario_set}
          {:ok, _} -> {:ok, nil}
        end

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Purge expired scenario sets
  """
  def purge(decision, _attrs) do
    Scenarios.delete_expired_scenario_sets(decision)
    # TODO: return purged count
    0 |> success()
  end

  @doc """
  lists all scenario_sets in a decision

  See `EtheloApi.Structure.list_scenario_sets/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def match_scenario_set(args = %{decision: %Decision{} = decision}, _resolution) do
    scenario_set = args |> extract_filters() |> Scenarios.match_scenario_sets(decision)

    case scenario_set do
      nil -> {:ok, %ValidationMessage{field: :filters, code: :not_found, message: "does not exist", template: "does not exist"}}
      %ScenarioSet{} -> %{scenario_set: scenario_set} |> success()
    end
  end

  def extract_filters(%{} = args) do
    filters = %{}
    filters = if Map.has_key?(args, :scenario_set_id), do: Map.put(filters, :id, args.scenario_set_id |> sanitize_id), else: filters
    filters
  end

  @doc """
  batch loads all SolveDumps in a Decision, then matches to specified record
  """
  def batch_load_solve_dumps(parent, _, info) do
    resolver = {Scenarios, :match_solve_dumps, %{decision_id: parent.decision_id}}
    batch_has_one(parent, %SolveDump{}, :solve_dump, resolver)
  end
end
