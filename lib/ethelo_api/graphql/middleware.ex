defmodule EtheloApi.Graphql.Middleware do
  @moduledoc """
  Useful Middlware for Graphql queris
  """
  require Logger
  import EtheloApi.Helpers.ValidationHelper

  alias AbsintheErrorPayload.Payload
  alias EtheloApi.Structure

  def debug_resolution(resolution, _config) do
    Logger.debug(fn -> inspect(resolution) end)
  end

  def preload_decision(%{state: :unresolved} = resolution, _config) do
    case args_with_decision(resolution.arguments) do
      {:ok, args} ->
        %{resolution | arguments: args}

      err ->
        resolution
        |> Absinthe.Resolution.put_result(err)
    end
  end

  def preload_decision(resolution, _config), do: resolution

  def args_with_decision(%{input: %{decision_id: id} = input} = args) do
    case get_decision(id, :decision_id) do
      {:ok, decision} ->
        input = Map.put(input, :decision, decision)
        {:ok, %{args | input: input}}

      err ->
        err
    end
  end

  def args_with_decision(args), do: args

  def get_decision(id, field) do
    verify_required(Structure.get_decision(id), field)
  end

  def add_payload_meta(%{meta: _} = resolution, _config) do
    # meta already generated, so no work needed
    resolution
  end

  def add_payload_meta(%{value: value} = resolution, _config) do
    %{successful: successful, messages: messages} = Payload.convert_to_payload(value)
    meta = %{successful: successful, messages: messages, completed_at: DateTime.utc_now()}
    result = Map.put(value, :meta, meta)
    Absinthe.Resolution.put_result(resolution, {:ok, result})
  end
end
