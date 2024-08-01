defmodule EtheloApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    maybe_install_ecto_dev_logger()

    Oban.Telemetry.attach_default_logger()

    children = [

      # Start the Ecto repository
      EtheloApi.Repo,

      # Jobs
      {Oban, Application.fetch_env!(:ethelo_api, Oban)},

      # Engine calls, 1 supervisor per core
      {PartitionSupervisor, child_spec: Task.Supervisor, name: EtheloApi.EngineTaskSupervisors}
    ]

    Logger.add_handlers(:ethelo_api)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EtheloApi.Supervisor]
    Supervisor.start_link(children, opts)
  end


  if Code.ensure_loaded?(Ecto.DevLogger) do
    defp maybe_install_ecto_dev_logger, do: Ecto.DevLogger.install(EtheloApi.Repo)
  else
    defp maybe_install_ecto_dev_logger, do: :ok
  end
end
