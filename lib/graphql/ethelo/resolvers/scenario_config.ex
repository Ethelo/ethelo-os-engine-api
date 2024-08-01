defmodule GraphQL.EtheloApi.Resolvers.ScenarioConfig do
  @moduledoc """
  Resolvers for graphql.
  """
  alias EtheloApi.Structure.Decision
  alias Engine.Scenarios
  alias Engine.Scenarios.ScenarioConfig
  import GraphQL.EtheloApi.ResolveHelper

  @doc """
  lists all scenario_configs

  See `Engine.Scenarios.list_scenario_configs/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """

  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Scenarios.list_scenario_configs(modifiers) |> success()
  end

  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  creates a new ScenarioConfig

  See `EtheloApi.Structure.create_scenario_config/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def create(decision, attrs) do
    attrs = attrs |> rename_collective_identity()
    Scenarios.create_scenario_config(decision, attrs)
  end

  @doc """
  updates an existing ScenarioConfig.

  See `EtheloApi.Structure.update_scenario_config/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def update(decision, %{id: id} = attrs) do
    case Engine.Scenarios.get_scenario_config(id, decision) do
      nil ->
        not_found_error()

      scenario_config ->
        attrs = attrs |> rename_collective_identity()
        Scenarios.update_scenario_config(scenario_config, attrs)
    end
  end

  @doc """
  updates scenario_config cache.
  """
  def cache(decision, %{id: id}) do
    case verify_id(ScenarioConfig, :id, id, decision.id) do
      :ok -> Engine.Invocation.update_scenario_config_cache(id, decision)
      {:error, message} -> {:error, message}
    end
  end

  @doc """
  updates an existing ScenarioConfig.

  See `EtheloApi.Structure.delete_scenario_config/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(decision, %{id: id}) do
    case verify_id(ScenarioConfig, :id, id, decision.id) do
      :ok -> Scenarios.delete_scenario_config(id, decision)
      {:error, _message} -> {:ok, nil}
    end
  end

  defp rename_collective_identity(%{collective_identity: ci} = attrs) do
    Map.put(attrs, :ci, ci)
  end

  defp rename_collective_identity(%{} = attrs), do: attrs
end
