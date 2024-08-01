defmodule Engine.Invocation.SolveSettings do
  @moduledoc """
  Registry of data associated with an engine invocation
  """
  require Logger
  require OK

  alias Engine.Invocation
  alias Engine.Invocation.SolveSettings
  alias Engine.Invocation.ScenarioHashes
  alias EtheloApi.Voting.Participant
  alias EtheloApi.Voting
  alias Engine.Scenarios
  alias EtheloApi.Structure

  defstruct [
    :decision_id,
    :decision,
    :scenario_config,
    :scenario_config_id,
    :use_cached_decision,
    :hash,
    :force,
    :async,
    :participant,
    :participant_id,
    :scenario_set,
    :is_new_solve,
    :save_dump,
    :response_json,
    :voting_data,
    :decision_json,
    :influents_json,
    :weights_json,
    :config_json,
    :preprocessed,
    :solve_dump,
    :error
  ]

  def solve_settings(decision_id, options) do
    settings = create_with_options(decision_id, options)

    OK.try do
      decision = Structure.get_decision(decision_id)
      scenario_config <- get_scenario_config(decision_id, settings.scenario_config_id)
      participant <- get_participant(decision_id, settings.participant_id)
      participant_id = if is_nil(participant), do: nil, else: participant.id
      hash <- get_hash(decision, scenario_config, settings.use_cached_decision, participant)
    after
      settings =
        Map.merge(settings, %{
          decision: decision,
          scenario_config: scenario_config,
          hash: hash,
          participant: participant,
          participant_id: participant_id
        })

      {:ok, settings}
    rescue
      {:error, error} ->
        {:ok,
         %SolveSettings{
           error: error,
           decision_id: decision_id
         }}
    end
  end

  defp create_with_options(decision_id, options) do
    %Engine.Invocation.SolveSettings{
      decision_id: decision_id,
      use_cached_decision: Keyword.get(options, :cached, false),
      async: Keyword.get(options, :async, false),
      save_dump: Keyword.get(options, :save_dump, false),
      force: Keyword.get(options, :force, false),
      participant_id: Keyword.get(options, :participant_id, nil),
      scenario_config_id: Keyword.get(options, :scenario_config_id, nil)
    }
  end

  def add_voting_data({:ok, settings}), do: add_voting_data(settings)
  def add_voting_data({:error, _} = error), do: error

  def add_voting_data(%SolveSettings{} = settings) do
    voting_data =
      if is_nil(settings.participant_id) do
        Invocation.group_voting_data(settings.decision_id, settings.scenario_config.id)
      else
        Invocation.participant_voting_data(
          settings.decision_id,
          settings.participant.id,
          settings.scenario_config.id
        )
      end

    Map.put(settings, :voting_data, voting_data)
  end

  def get_participant(_, nil), do: {:ok, nil}

  def get_participant(decision_id, participant_id) do
    case Voting.get_participant(participant_id, decision_id) do
      nil -> {:error, "missing participant"}
      participant -> {:ok, participant}
    end
  end

  def get_hash(decision, scenario_config, use_cached_decision, nil) do
    ScenarioHashes.get_group_scenario_hash(decision, scenario_config, use_cached_decision)
  end

  def get_hash(decision, scenario_config, use_cached_decision, %Participant{} = participant) do
    ScenarioHashes.get_participant_scenario_hash(
      decision,
      scenario_config,
      use_cached_decision,
      participant
    )
  end

  def get_scenario_config(decision_id, scenario_config_id) do
    OK.for do
      scenario_config_id <-
        case scenario_config_id do
          nil -> {:error, "missing scenario config id"}
          scenario_config_id -> {:ok, scenario_config_id}
        end

      scenario_config <-
        case Scenarios.get_scenario_config(scenario_config_id, decision_id) do
          nil -> {:error, "missing scenario config"}
          scenario_config -> {:ok, scenario_config}
        end
    after
      scenario_config
    end
  end

  def dump(%SolveSettings{} = settings) do
    scenario_set = Map.get(settings, :scenario_set)
    scenario_set_id = if is_nil(scenario_set), do: nil, else: scenario_set.id
    scenario_set_status = if is_nil(scenario_set), do: nil, else: scenario_set.status

    {:ok, string_settings} =
      settings
      |> Map.take([
        :decision_id,
        :cached_scenario_set,
        :decision_id,
        :hash,
        :force,
        :participant_id,
        :use_cached_decision
      ])
      |> Map.put(:scenario_set_id, scenario_set_id)
      |> Map.put(:scenario_set_status, scenario_set_status)
      |> Poison.encode()

    string_settings
  end

  def dump(%{} = settings) do
    inspect(settings)
  end

  def log_solve_settings(message, {:ok, settings}), do: log_solve_settings(message, settings)

  def log_solve_settings(message, %SolveSettings{} = settings) do
    string_settings = dump(settings)
    slug = settings |> Map.get(:decision, %{}) |> Map.get(:slug, "-")
    type = if is_nil(settings.participant_id), do: "GR", else: "PR"
    Logger.debug("#{slug} #{type} #{message} #{string_settings}")
  end
end
