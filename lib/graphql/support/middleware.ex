defmodule GraphQL.EtheloApi.Middleware do
  @moduledoc """
  Useful Middlware for GraphQL queris
  """
  require Logger
  alias Kronky.Payload

  def debug_resolution(resolution, _config) do
    Logger.debug fn() -> inspect(resolution) end
  end

  def post_resolve_payload(%{meta: _} = resolution, _config) do
    resolution #meta already generated, so no work needed
  end

  def post_resolve_payload(%{value: value} = resolution, _config) do
    %{successful: successful, messages: messages} = Payload.convert_to_payload(value)
    meta = %{successful: successful, messages: messages, completed_at: Timex.now}
    result = Map.put(value, :meta, meta)
    Absinthe.Resolution.put_result(resolution, {:ok, result})
  end

end
