defmodule Engine.Invocation.Builder do
  require OK
  use OK.Pipe
  require Logger

  alias Engine.Scenarios
  alias Engine.Invocation
  alias EtheloApi.Structure.Decision
  alias Engine.Invocation.ConfigJson
  alias Engine.Invocation.DecisionJson
  alias Engine.Invocation.SolveSettings
  alias Engine.Invocation.ScoringData

  def build_solve_settings(decision_id, options) do
    {status1, base_settings} = SolveSettings.solve_settings(decision_id, options)

    {status2, with_scenario_set} = add_scenario_set({status1, base_settings})

    {status3, with_solve_data} = add_solve_data({status2, with_scenario_set})

    case {status1, status2, status3} do
      {_, _, :ok} -> {:ok, with_solve_data}
      {_, :ok, _} -> add_error_to_settings(with_solve_data, with_scenario_set)
      {:ok, _, _} -> add_error_to_settings(with_scenario_set, base_settings)
      {:error, _, _} -> add_error_to_settings(base_settings, %{})
    end
  end

  def add_error_to_settings(error, settings) do
    {:error, Map.put(settings, :error, error)}
  end

  def add_solve_data({:error, error}), do: {:error, error}

  def add_solve_data({:ok, %{is_new_solve: false, force: false} = settings}) do
    {:ok, settings}
  end

  def add_solve_data({:ok, settings}), do: add_voting_data_and_jsons(settings)

  def add_solve_data(%SolveSettings{} = settings), do: add_voting_data_and_jsons(settings)

  def add_scenario_set({:error, error}), do: {:error, error}

  def add_scenario_set({:ok, settings}), do: add_scenario_set(settings)

  def add_scenario_set(%{force: true} = settings) do

    case Scenarios.create_scenario_set(settings.decision_id, new_scenario_values(settings)) do
      {:ok, scenario_set} ->
        settings
        |> Map.put(:scenario_set, scenario_set)
        |> Map.put(:is_new_solve, true)
        |> OK.success()

      {:error, result} ->  {:error, result}
    end
  end

  def add_scenario_set(settings) do
    {status, result} = Scenarios.find_or_create_scenario_set(
        settings.decision_id,
        %{participant_id: settings.participant_id, hash: settings.hash},
        new_scenario_values(settings)
      )

    if status == :error do
      {:error, result}
    else
      {scenario_set, is_new_record} = result

      settings
      |> Map.put(:scenario_set, scenario_set)
      |> Map.put(:is_new_solve, is_new_record)
      |> OK.success()
    end
  end


  def new_scenario_values(%{} = settings) do
    %{
      participant_id: settings.participant_id,
      scenario_config_id: settings.scenario_config_id,
      cached_decision: settings.use_cached_decision,
      hash: settings.hash,
      status: "pending"
    }
  end

  def add_voting_data_and_jsons({:ok, settings}), do: add_voting_data_and_jsons(settings)
  def add_voting_data_and_jsons({:error, _} = error), do: error

  def add_voting_data_and_jsons(settings) do
    OK.for do
      {decision_json, preprocessed, config_json} <- structure_jsons(settings)
      settings = SolveSettings.add_voting_data(settings)
      {influents_json, weights_json} <- voting_jsons(settings)

      settings =
        Map.merge(settings, %{
          preprocessed: preprocessed,
          decision_json: decision_json,
          config_json: config_json,
          influents_json: influents_json,
          weights_json: weights_json
        })
    after
      settings
    end
  end

  def invocation_jsons(decision_id, options \\ [])

  def invocation_jsons(%Decision{} = decision, options),
    do: invocation_jsons(decision.id, options)

  def invocation_jsons(nil, _), do: raise(ArgumentError, message: "you must supply a Decision")

  def invocation_jsons(decision_id, options) do
    {status1, base_settings} = SolveSettings.solve_settings(decision_id, options)
    {status2, with_solve_data} = add_voting_data_and_jsons(base_settings)

    case {status1, status2} do
      {_, :ok} ->
        {:ok,
         %{
           decision_json: with_solve_data.decision_json,
           influents_json: with_solve_data.influents_json,
           weights_json: with_solve_data.weights_json,
           config_json: with_solve_data.config_json,
           hash: with_solve_data.hash
         }}

      {:ok, _} ->
        add_error_to_settings(with_solve_data, base_settings)

      {:error, _} ->
        add_error_to_settings(%{}, %{})
    end
  end

  def structure_jsons({:ok, settings}), do: structure_jsons(settings)
  def structure_jsons({:error, _} = error), do: error

  def structure_jsons(%{use_cached_decision: true} = settings) do
    case {Invocation.get_decision_cache_value(settings.decision_id),
          Invocation.get_decision_preprocessed_cache_value(settings.decision_id),
          Invocation.get_scenario_config_cache_value(
            settings.scenario_config.id,
            settings.decision_id
          )} do
      {nil, _, _} ->
        {:error, "missing decision cache"}

      {_, _, nil} ->
        {:error, "missing scenario config cache"}

      # if preprocessed does not exist, the decision can still solve
      {decision_json, preprocessed, config_json} ->
        {:ok, {decision_json, preprocessed, config_json}}
    end
  end

  def structure_jsons(%{} = settings) do
    decision_json_data = ScoringData.initialize_decision_json_data(settings.decision_id)

    decision_json = decision_json_data |> DecisionJson.build_json(false)

    config_json = settings.scenario_config
      |> ConfigJson.build(decision_json_data.option_categories)
      |> ConfigJson.to_json(false)

    {:ok, {decision_json, "", config_json}}
  end

  def voting_jsons({:ok, settings}), do: voting_jsons(settings)
  def voting_jsons({:error, _} = error), do: error

  def voting_jsons(%{voting_data: voting_data}) do
    influents_json =
      voting_data
      |> Engine.Invocation.InfluentsJson.build()
      |> Engine.Invocation.InfluentsJson.to_json()

    if influents_json == "[]" do
      {:error, "no votes"}
    else
      weights_json =
        voting_data
        |> Engine.Invocation.WeightsJson.build()
        |> Engine.Invocation.WeightsJson.to_json()

      {:ok, {influents_json, weights_json}}
    end
  end
end
