use Mix.Config

# Configure your database
config :ethelo_api, EtheloApi.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("POSTGRES_USERNAME"),
  password: System.get_env("POSTGRES_PASSWORD"),
  hostname: System.get_env("POSTGRES_HOST"),
  database: System.get_env("PROD_DB") ,
  pool_size: 20,
  timeout: 180_000,
  connect_timeout: 180_000
# Do not print debug messages in production

config :logger, level: :info

# path to Ethelo-Engine compiled driver
config :ethelo_api, :engine_driver, ""
