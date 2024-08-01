use Mix.Config


# Configure your database
config :ethelo, EtheloApi.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("POSTGRES_USERNAME") || "postgres",
  password: System.get_env("POSTGRES_PASSWORD") || "postgres",
  hostname: System.get_env("POSTGRES_HOST") || "postgres",
  database: System.get_env("TEST_DB"),
  pool: Ecto.Adapters.SQL.Sandbox,
  timeout: 180_000,
  connect_timeout: 180_000

# Print only warnings and errors during test
config :logger, level: :warn

config :engine_driver, :pools,
    default: [size: 8, max_overflow: 16]

config :engine_driver, :redis_host, System.get_env("APP_REDIS_HOST") || "localhost"

# path to Ethelo-Engine compiled driver
config :engine_driver, :driver, ""
