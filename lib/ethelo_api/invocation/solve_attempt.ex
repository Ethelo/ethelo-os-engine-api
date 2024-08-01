defmodule EtheloApi.Invocation.SolveAttempt do
  @moduledoc """
  Loads and validatats the settings and data needed for
  the engine to run

  Logs activity and returns either an plain error
  or a ScenarioSet with an engine response/error
  """
  require Logger

  alias EtheloApi.Scenarios
  alias EtheloApi.Invocation
  alias EtheloApi.Invocation.InvocationSettings
  alias EtheloApi.Invocation.InvocationFiles
  alias EtheloApi.Invocation.ScenarioHashes
  alias EtheloApi.Scenarios.Queries.ScenarioImport
  alias EtheloApi.Scenarios.ScenarioSet
  alias EtheloApi.Structure.Decision

  @spec solve(struct() | integer(), struct() | integer(), keyword()) ::
          {:ok, struct()} | {:error, String.t()} | {:error, struct()}
  @doc """
  Given a Decision and required settings (at minimum a ScenarioConfig id)

  """
  def solve(decision_id, scenario_config_id, options \\ [])

  def solve(%Decision{} = decision, scenario_config_id, options),
    do: solve(decision.id, scenario_config_id, options)

  def solve(decision_id, scenario_config_id, options) do
    # clear out old ScenarioSets before we create new ones
    Scenarios.delete_expired_scenario_sets(decision_id)
    Scenarios.clean_pending_scenario_sets(decision_id)

    with(
      {:ok, %InvocationSettings{} = settings} <-
        InvocationSettings.build(decision_id, scenario_config_id, options),
      {:ok, hash} = get_hash(settings),
      {:ok, {scenario_set, is_new_solve}} <- find_or_create_scenario_set(settings, hash)
    ) do
      build_and_solve(is_new_solve, scenario_set, settings)
    end
  end

  def build_and_solve(false, %ScenarioSet{} = scenario_set, %InvocationSettings{} = settings) do
    Scenarios.touch_scenario_set(scenario_set, settings.decision_id)
    log_settings(settings, scenario_set, "Using existing ScenarioSet")
    {:ok, scenario_set}
  end

  def build_and_solve(
        _is_new_solve,
        %ScenarioSet{} = scenario_set,
        %InvocationSettings{} = settings
      ) do
    {:ok, voting_data} = voting_data(settings)

    response =
      with(
        {:ok, files} <-
          InvocationFiles.create(settings, voting_data),
        {:ok, scenario_set} <- set_engine_start(scenario_set, settings),
        {:ok, engine_response} <- call_engine(files),
        {:ok, {response_json, scenario_set}} <-
          parse_engine_response(engine_response, scenario_set, settings, files),
        {:ok, imported_scenario_set} <-
          do_import(scenario_set, settings, voting_data, response_json)
      ) do
        log_settings(settings, scenario_set, "Engine Solved without Error")
        {:ok, imported_scenario_set}
      end

    case response do
      {:error, error} ->
        handle_error(settings, scenario_set, error)

      {:ok, scenario_set} ->
        {:ok, scenario_set}
    end
  end

  def set_engine_start(
        %ScenarioSet{} = scenario_set,
        %InvocationSettings{} = settings
      ) do
    {:ok, scenario_set} = Scenarios.set_scenario_set_engine_start(scenario_set, settings.decision)
    log_settings(settings, scenario_set, " CALLING ENGINE ")

    {:ok, scenario_set}
  end

  def call_engine(%InvocationFiles{} = files) do
    engine_response =
      Invocation.engine_solve({
        files.decision_json,
        files.influents_json,
        files.weights_json,
        files.config_json,
        files.preprocessed
      })

    {:ok, engine_response}
  end

  def parse_engine_response(
        engine_response,
        %ScenarioSet{} = scenario_set,
        %InvocationSettings{} = settings,
        %InvocationFiles{} = files
      ) do
    # reload ScenarioSet, in case it's stale from a different process updating
    scenario_set = Scenarios.get_scenario_set(scenario_set.id, scenario_set.decision_id)

    response =
      case scenario_set do
        nil -> {:error, " ScenarioSet no longer present "}
        %{status: "pending"} -> engine_response
        %{status: "error"} -> engine_response
        %{status: _} -> {:error, "Using existing ScenarioSet"}
      end

    case response do
      {:ok, response_json} ->
        log_solve_dump("", scenario_set, settings, %{files | response_json: response_json})
        Scenarios.set_scenario_set_engine_end(scenario_set, settings.decision)
        log_settings(settings, scenario_set, " ENGINE COMPLETE ")
        {:ok, {response_json, scenario_set}}

      {:error, error} ->
        message = extract_error_message(error)
        log_solve_dump(message, scenario_set, settings, files)
        {:error, message}
    end
  end

  defp extract_error_message(error) do
    case error do
      :engine_terminated -> "engine terminated unexpectedly"
      error when is_binary(error) -> error
      error when is_atom(error) -> Atom.to_string(error)
      # engine might return an nested error
      {_, error} when is_binary(error) -> error
      _ -> "unknown error"
    end
  end

  def do_import(
        %ScenarioSet{} = scenario_set,
        %InvocationSettings{} = settings,
        voting_data,
        response_json
      ) do
    log_settings(settings, scenario_set, "Importing from engine")

    ScenarioImport.import(
      scenario_set,
      voting_data,
      response_json,
      settings
    )
  end

  defp handle_error(%InvocationSettings{} = settings, %ScenarioSet{} = scenario_set, message) do
    log_settings(settings, scenario_set, message)
    Scenarios.set_scenario_set_error(scenario_set, scenario_set.decision_id, message)
  end

  def voting_data(%InvocationSettings{participant_id: nil} = settings) do
    data = Invocation.group_voting_data(settings.decision_id, settings.scenario_config.id)
    {:ok, data}
  end

  def voting_data(%InvocationSettings{} = settings) do
    data =
      Invocation.participant_voting_data(
        settings.decision_id,
        settings.participant.id,
        settings.scenario_config.id
      )

    {:ok, data}
  end

  def get_hash(%{participant: nil} = settings) do
    ScenarioHashes.get_group_scenario_hash(
      settings.decision,
      settings.scenario_config,
      settings.use_cache
    )
  end

  def get_hash(%{} = settings) do
    ScenarioHashes.get_participant_scenario_hash(
      settings.decision,
      settings.scenario_config,
      settings.use_cache,
      settings.participant
    )
  end

  def find_or_create_scenario_set(%{force: true} = settings, hash),
    do: create_scenario_set(settings, hash)

  def find_or_create_scenario_set(%{scenario_config: scenario_config} = settings, hash) do
    latest_scenario_set =
      Scenarios.match_latest_scenario_set(
        settings.decision_id,
        %{participant_id: settings.participant_id, hash: hash, status: ["pending", "success"]}
      )

    cond do
      is_nil(latest_scenario_set) ->
        create_scenario_set(settings, hash)

      latest_scenario_set.engine_start > solve_rate_limit(scenario_config.solve_interval) ->
        {:error, "rate limited"}

      true ->
        {:ok, {latest_scenario_set, false}}
    end
  end

  def create_scenario_set(%InvocationSettings{} = settings, hash) do
    new_scenario_values = %{
      participant_id: settings.participant_id,
      scenario_config_id: settings.scenario_config_id,
      cached_decision: settings.use_cache,
      hash: hash,
      status: "pending"
    }

    case Scenarios.create_scenario_set(new_scenario_values, settings.decision) do
      {:ok, scenario_set} ->
        {:ok, {scenario_set, true}}

      error ->
        error
    end
  end

  def log_settings(%{} = settings, %{} = scenario_set, message) do
    string_settings =
      %{
        use_cache: settings.use_cache,
        force: settings.force,
        participant_id: settings.participant_id,
        scenario_set_id: scenario_set.id,
        status: scenario_set.status,
        decision_id: settings.decision_id
      }
      |> inspect()

    slug = settings.decision.slug
    type = if is_nil(settings.participant_id), do: "GR", else: "PR"
    Logger.debug("### #{slug} #{type} #{message} #{string_settings}")
  end

  defp log_solve_dump(_, _, %{save_dump: false}, _), do: nil
  defp log_solve_dump(_, nil, _, _), do: nil

  defp log_solve_dump(message, scenario_set, settings, files) do
    attrs = %{
      error: message,
      scenario_set: scenario_set,
      scenario_set_id: scenario_set.id,
      decision: settings.decision,
      decision_id: settings.decision.id,
      participant: settings.participant,
      participant_id: settings.participant_id,
      decision_json: files.decision_json,
      influents_json: files.influents_json,
      weights_json: files.weights_json,
      config_json: files.config_json,
      response_json: files.response_json
    }

    Scenarios.upsert_solve_dump(attrs)
  end

  def solve_rate_limit(solve_interval) do
    offset = solve_interval * -1

    NaiveDateTime.utc_now()
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.add(offset, :millisecond)
  end
end
