defmodule EtheloApi.Repo do
  use Ecto.Repo,
    otp_app: :ethelo_api,
    adapter: Ecto.Adapters.Postgres
end
