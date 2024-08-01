use Mix.Config


# Configure your database
config :ethelo, EtheloApi.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("POSTGRES_USERNAME"),
  password: System.get_env("POSTGRES_PASSWORD"),
  hostname: System.get_env("POSTGRES_HOST"),
  database: System.get_env("DEV_DB"),
  pool_size: 10,
  timeout: 180_000,
  connect_timeout: 180_000

  config :engine_driver, :pools,
      default: [size: 8, max_overflow: 16]

  config :engine_driver, :redis_host, System.get_env("APP_REDIS_HOST") || "localhost"

  # path to Ethelo-Engine compiled driver
  config :engine_driver, :driver, ""
