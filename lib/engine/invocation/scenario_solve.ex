defmodule Engine.Invocation.ScenarioSolve do
  require OK
  require Logger

  alias Engine.Scenarios
  alias EtheloApi.Structure.Decision
  alias Engine.Invocation
  alias Engine.Invocation.SolveSettings

  @doc """
  Helper method for quickly trigging a solve in console
  """
  def solve_group_decision(decision_id, options \\ [])

  def solve_group_decision(%Decision{} = decision, options),
    do: solve_group_decision(decision.id, options)

  def solve_group_decision(nil, _),
    do: raise(ArgumentError, message: "you must supply a Decision")

  def solve_group_decision(decision_id, options) do
    scenario_config =
      Scenarios.list_scenario_configs(decision_id, %{slug: "group"}) |> List.first()

    options =
      Map.put(options, :scenario_config_id, Map.get(scenario_config, :id, nil)) |> Map.to_list()

    solve_decision(decision_id, options)
  end

  @doc """
  Helper method for quickly trigging a solve in console
  """
  def solve_participant_decision(decision_id, participant_id, options \\ [])

  def solve_participant_decision(%Decision{} = decision, participant_id, options),
    do: solve_participant_decision(decision.id, participant_id, options)

  def solve_participant_decision(nil, _participant_id, _),
    do: raise(ArgumentError, message: "you must supply a Decision")

  def solve_participant_decision(decision_id, participant_id, options) do
    scenario_config =
      Scenarios.list_scenario_configs(decision_id, %{slug: "participant"}) |> List.first()

    options =
      options
      |> Map.put(:scenario_config_id, Map.get(scenario_config, :id, nil))
      |> Map.put(:participant_id, participant_id)
      |> Map.to_list()

    solve_decision(decision_id, options)
  end

  def solve_decision(decision_id, options \\ [])
  def solve_decision(%Decision{} = decision, options), do: solve_decision(decision.id, options)
  def solve_decision(nil, _), do: raise(ArgumentError, message: "you must supply a Decision")

  def solve_decision({:ok, %SolveSettings{} = settings}, _), do: solve_decision(settings)

  def solve_decision({:error, %SolveSettings{error: error} = settings}, _) do
    save_error_to_scenario_set(error, settings)
  end

  def solve_decision({:error, error}, _) do
    save_error_to_scenario_set(error, nil)
  end


  def solve_decision(
        %{is_new_solve: false, force: false, scenario_set: scenario_set} = settings,
        _
      ) do
    Scenarios.touch_scenario_set(scenario_set, settings.decision_id)
    SolveSettings.log_solve_settings("####Using existing matching scenario set", settings)
    {:ok, scenario_set}
  end

  def solve_decision(%SolveSettings{} = settings, _) do
    OK.try do
      result = call_engine(settings)
    after
      result
    rescue
      :engine_terminated ->
        "engine terminated unexpectedly" |> save_error_to_scenario_set(settings)

      error when is_binary(error) ->
        Logger.debug("## SOLVE ERROR #{error} #{inspect(settings)}")
        error |> save_error_to_scenario_set(settings)

      error when is_atom(error) ->
        Logger.debug("## SOLVE ERROR #{error} #{inspect(settings)}")
        Atom.to_string(error) |> save_error_to_scenario_set(settings)

      {_type, "pre_empted"} ->
        Logger.debug("## PRE-EMPTED")
        # don't save the error, the scenario set is being solved again in another process
        {:error, "pre-empted"}

      {type, error} when is_atom(type) and is_binary(error) ->
        Logger.debug("## SOLVE ERROR #{error} #{inspect(settings)}")
        "#{type}: #{error}" |> save_error_to_scenario_set(settings)

      _ ->
        Logger.debug("## SOLVE ERROR unknown error #{inspect(settings)}")
        save_error_to_scenario_set("unknown error", settings)
    end
  end

  def solve_decision(decision_id, options) do
    Scenarios.delete_expired_scenario_sets(decision_id)
    settings = Invocation.build_solve_settings(decision_id, options)
    solve_decision(settings)
  end

  def log_solve_dump(settings, error \\ "")
  def log_solve_dump(%{save_dump: false} = settings, _), do: settings

  def log_solve_dump(settings, error) do
    attrs = %{
      scenario_set: settings.scenario_set,
      scenario_set_id: settings.scenario_set.id,
      decision_json: settings.decision_json,
      influents_json: settings.influents_json,
      weights_json: settings.weights_json,
      config_json: settings.config_json,
      response_json: settings.response_json,
      error: error,
      decision: settings.decision,
      decision_id: settings.decision.id,
      participant: settings.participant
    }

    {:ok, solve_dump} = Scenarios.upsert_solve_dump(settings.decision, attrs)
    settings = Map.put(settings, :solve_dump, solve_dump)
    settings
  end

  def call_engine(%SolveSettings{} = settings) do
    OK.for do
      SolveSettings.log_solve_settings("## # # # # CALLING ENGINE", settings)
      settings = log_solve_dump(settings)
      Scenarios.set_scenario_set_engine_start(settings.scenario_set, settings.decision)

      preemption_key =
        case settings.participant_id do
          nil -> nil
          _ -> "d#{settings.scenario_set.decision_id}_p#{settings.scenario_set.participant_id}"
        end

      response_json <-
        Invocation.engine_solve(
          {settings.decision_json, settings.influents_json, settings.weights_json,
           settings.config_json, settings.preprocessed},
          preemption_key: preemption_key
        )

      Scenarios.set_scenario_set_engine_end(settings.scenario_set, settings.decision)
      settings = Map.put(settings, :response_json, response_json)
      settings = log_solve_dump(settings)

      # reload in case it's stale
      # TODO return error here
      updated_scenario_set =
        Scenarios.get_scenario_set(settings.scenario_set.id, settings.scenario_set.decision_id)

      case updated_scenario_set do
        nil -> Logger.debug("## SOLVE ERROR scenario set no longer present #{inspect(settings)}")
        _ -> nil
      end

      SolveSettings.log_solve_settings("## # # # # Importing from engine", settings)

      imported_scenario_set <-
        Scenarios.import_scenario_set(
          updated_scenario_set,
          settings.voting_data,
          response_json,
          Map.take(settings, [:scenario_config_id, :participant_id, :use_cached_decision, :hash])
        )

      Map.put(settings, :scenario_set, imported_scenario_set)
      SolveSettings.log_solve_settings("Engine Solved without Error", settings)
    after
      imported_scenario_set |> OK.success()
    end
  end

  def save_error_to_scenario_set(message, {:ok, settings}),
    do: save_error_to_scenario_set(message, settings)

  def save_error_to_scenario_set(message, {:error, settings}),
    do: save_error_to_scenario_set(message, settings)

  def save_error_to_scenario_set(message, %{scenario_set: scenario_set} = settings) do
    SolveSettings.log_solve_settings("####Error Solving or Importing: #{message}", settings)

    if is_nil(scenario_set) do
      {:error, message}
    else
      log_solve_dump(settings, message)
      Scenarios.set_scenario_set_error(settings.scenario_set, settings.decision_id, message)
    end
  end

  def save_error_to_scenario_set(message, _) do
    {:error, message}
  end
end
