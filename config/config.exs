# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ethelo_api,
  ecto_repos: [Ethelo.Repo],
  generators: [timestamp_type: :utc_datetime]

config :ethelo_api, Oban,
  engine: Oban.Engines.Basic,
  repo: Ethelo.Repo,
  # # run jobs for 3 hours, tune this later - might not be needed with work timeout configured
  # shutdown_grace_period: 10_000 * 60 * 60 * 3,
  # add cleanup
  queues: [group: 10, personal: 50],
  plugins: [
    # 7 days, tune this later
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
