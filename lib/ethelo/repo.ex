defmodule EtheloApi.Repo do
  use Ecto.Repo, otp_app: :ethelo
  require Logger

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL"))}
  end


  # Inspired by https://github.com/elixir-ecto/ecto/blob/v2.2.11/lib/ecto/log_entry.ex
  def log_query(entry) do
    Logger.log(:debug, fn ->
      {ok, _} = entry.result
      source = inspect(entry.source)
      time_us = System.convert_time_unit(entry.query_time, :native, :microsecond)
      time_ms = div(time_us, 100) / 10
      # Strip out unnecessary quotes from the query for readability
      query = Regex.replace(~r/(\d\.)"([^"]+)"/, entry.query, "\\1\\2")
      params = inspect(entry.params, charlists: false)

      "SQL query: #{ok} source=#{source} db=#{time_ms}ms   #{query}   params=#{params}"
    end)
  end

end
