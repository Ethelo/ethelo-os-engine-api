defmodule EtheloApi.Invocation.SolveWorker do
  @moduledoc """
  Worker responsible for calling engine
  """
  alias EtheloApi.Invocation

  alias EtheloApi.Invocation.InvocationSettings

  use Oban.Worker,
    queue: :group,
    # 0 is highest
    priority: 1,
    max_attempts: 3,
    unique: [
      # do not use time to determine uniqness
      period: :infinity,
      keys: [:unique_stamp],
      fields: [:worker, :queue]
      # only check pending jobs
      #    states: [:available, :scheduled, :executing]
    ]

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    options = InvocationSettings.process_options(args)
    decision_id = Map.get(args, "decision_id", nil)
    scenario_config_id = Map.get(args, "scenario_config_id", nil)

    Invocation.solve(decision_id, scenario_config_id, options)
    :ok
  end

  @impl Oban.Worker
  # absurdly long in nearly all cases
  def timeout(_), do: :timer.minutes(120)
end
