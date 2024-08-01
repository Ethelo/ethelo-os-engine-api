defmodule EtheloApi.Invocation.Queue do
  @moduledoc """
  Processes and starts Engine Jobs.
  """
  import EtheloApi.Helpers.ValidationHelper

  alias EtheloApi.Invocation.InvocationSettings
  alias EtheloApi.Invocation.ScenarioHashes
  alias EtheloApi.Invocation.SolveWorker
  alias EtheloApi.Structure.Decision

  def queue_solve(%Decision{} = decision, %{} = input) do
    case verify_solve_inputs(decision, input) do
      {:ok, config} -> insert_job(config)
      {:error, reason} -> {:error, reason}
    end

    # conflict check
  end

  def verify_solve_inputs(decision, input, verify_votes \\ true)

  def verify_solve_inputs(%Decision{} = decision, input, verify_votes) do
    options = InvocationSettings.process_options(input)

    scenario_config_id = Keyword.get(options, :scenario_config_id)

    with(
      {:ok, settings} <- InvocationSettings.build(decision.id, scenario_config_id, options),
      {:ok, _} <- InvocationSettings.verify_votes(settings, verify_votes)
    ) do
      %{decision: decision, participant: participant, scenario_config: scenario_config} = settings

      options = options |> Enum.into(%{})

      options =
        options
        |> Map.put(:unique_stamp, unique_stamp(decision, scenario_config, participant, options))
        |> Map.put(:decision_id, decision.id)
        |> Map.put(:scenario_config_id, scenario_config.id)
        |> Map.put(:participant_id, settings.participant_id)

      %{
        decision: decision,
        participant: participant,
        scenario_config: scenario_config,
        solve_options: options
      }
      |> success()
    end
  end

  def verify_solve_inputs(_, _, _) do
    {:error, validation_message("cannot be blank", :decision_id, :required)}
  end

  defp insert_job(%{solve_options: %{participant_id: nil} = solve_options}) do
    solve_options
    |> SolveWorker.new(queue: :group, priority: 2)
    |> Oban.insert()
  end

  defp insert_job(%{solve_options: solve_options}) do
    solve_options
    |> SolveWorker.new(queue: :personal, priority: 1)
    |> Oban.insert()
  end

  defp unique_stamp(_, _, _, %{force: true}), do: DateTime.utc_now() |> DateTime.to_iso8601()

  defp unique_stamp(decision, scenario_config, nil, %{use_cache: use_cache}) do
    {:ok, hash} =
      ScenarioHashes.get_group_scenario_hash(
        decision,
        scenario_config,
        use_cache
      )

    hash
  end

  defp unique_stamp(decision, scenario_config, participant, %{use_cache: use_cache}) do
    {:ok, hash} =
      ScenarioHashes.get_participant_scenario_hash(
        decision,
        scenario_config,
        use_cache,
        participant
      )

    hash
  end
end
