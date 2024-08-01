use Mix.Config


# Configure your database
config :ethelo_api, EtheloApi.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("POSTGRES_USERNAME"),
  password: System.get_env("POSTGRES_PASSWORD"),
  hostname: System.get_env("POSTGRES_HOST"),
  database: System.get_env("DEV_DB"),
  pool_size: 10,
  timeout: 180_000,
  connect_timeout: 180_000

  # path to Ethelo-Engine compiled driver
  config :ethelo_api, :engine_driver, ""
