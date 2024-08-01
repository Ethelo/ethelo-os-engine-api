defmodule EtheloApi.Graphql.Resolvers.ScenarioConfig do
  @moduledoc """
  Resolvers for graphql.
  """

  import EtheloApi.Helpers.ValidationHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision

  @doc """
  lists all ScenarioConfigs

  See `EtheloApi.Structure.list_scenario_configs/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """

  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    decision |> Structure.list_scenario_configs(modifiers) |> success()
  end

  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  Creates a new ScenarioConfig

  See `EtheloApi.Structure.create_scenario_config/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def create(%{input: %{decision: decision} = attrs}, _resolution) do
    attrs = attrs |> rename_collective_identity()
    Structure.create_scenario_config(attrs, decision)
  end

  @doc """
  Updates a ScenarioConfig.

  See `EtheloApi.Structure.update_scenario_config/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def update(%{input: %{decision: decision, id: id} = attrs}, _resolution) do
    case EtheloApi.Structure.get_scenario_config(id, decision) do
      nil ->
        {:ok, not_found_error()}

      scenario_config ->
        attrs = attrs |> rename_collective_identity()
        Structure.update_scenario_config(scenario_config, attrs)
    end
  end

  @doc """
  updates the ScenarioConfig cache.
  """
  def update_cache(%{input: %{decision: decision, id: id}}, _resolution) do
    case EtheloApi.Structure.get_scenario_config(id, decision) do
      nil ->
        {:error, not_found_error(:id)}

      scenario_config ->
        EtheloApi.Invocation.update_scenario_config_cache(scenario_config, decision)
        {:ok, scenario_config}
    end
  end

  @doc """
  Deletes a ScenarioConfig.

  See `EtheloApi.Structure.delete_scenario_config/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(%{input: %{decision: decision, id: id}}, _resolution) do
    Structure.delete_scenario_config(id, decision)
  end

  defp rename_collective_identity(%{collective_identity: ci} = attrs) do
    Map.put(attrs, :ci, ci)
  end

  defp rename_collective_identity(%{} = attrs), do: attrs
end
