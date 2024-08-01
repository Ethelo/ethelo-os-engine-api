defmodule EtheloApi.Invocation.Queries.Cache do
  @moduledoc """
  Contains methods that will be delegated to inside structure.
  Used purely to reduce the size of structure.ex
  """

  import Ecto.Query, warn: false
  alias EtheloApi.Helpers.EctoHelper

  alias EtheloApi.Repo

  alias EtheloApi.Invocation
  alias EtheloApi.Invocation.Cache
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.ScenarioConfig

  def hash_from_string(string) do
    :crypto.hash(:md5, [string]) |> Base.encode16()
  end

  @spec update_preprocessed_cache(String.t(), integer()) :: :ok
  def update_preprocessed_cache(decision_json, decision_id) when is_binary(decision_json) do
    {status, preprocessed_file} = Invocation.engine_preprocessed(decision_json)

    if status == :ok do
      update_cache_value(Invocation.preprocessed_key(), preprocessed_file, decision_id)
    else
      delete_cache_value(Invocation.preprocessed_key(), decision_id)
    end

    :ok
  end

  @spec update_decision_cache(integer() | struct()) ::
          {:ok, nil} | {:error, String.t()}
  def update_decision_cache(decision_id) when is_integer(decision_id) do
    Structure.get_decision(decision_id) |> update_decision_cache
  end

  def update_decision_cache(%Decision{id: decision_id} = decision) when is_integer(decision_id) do
    decision_json = generate_decision_json(decision)
    update_cache_value(Invocation.decision_key(), decision_json, decision_id)

    hash = hash_from_string(decision_json)

    Structure.update_decision(decision_id, %{
      published_decision_hash: hash,
      preview_decision_hash: hash
    })

    update_preprocessed_cache(decision_json, decision_id)
    {:ok, nil}
  end

  def update_decision_cache(_) do
    {:error, "Decision not found"}
  end

  @spec generate_decision_json(EtheloApi.Structure.Decision.t() | integer()) :: String.t()
  def generate_decision_json(%Decision{id: decision_id} = decision) do
    EtheloApi.Structure.ensure_filters_and_vars(decision)
    Invocation.build_decision_json(decision_id, false)
  end

  def generate_decision_json(_), do: ""

  def update_scenario_config_cache(%ScenarioConfig{} = scenario_config, %Decision{} = decision) do
    scenario_config_json = Invocation.build_config_json(scenario_config, decision)

    update_cache_value(
      Invocation.scenario_config_key(scenario_config.id),
      scenario_config_json,
      decision.id
    )

    Structure.update_scenario_config(scenario_config, %{
      published_engine_hash: hash_from_string(scenario_config_json)
    })

    {:ok, scenario_config}
  end

  def update_scenario_config_cache(scenario_config_id, decision) do
    scenario_config = Structure.get_scenario_config(scenario_config_id, decision)
    update_scenario_config_cache(scenario_config, decision)
  end

  @spec get_cache_value(String.t(), integer() | struct()) :: String.t() | nil
  def get_cache_value(key, %Decision{} = decision), do: get_cache_value(key, decision.id)

  def get_cache_value(key, decision_id) do
    case Cache |> Repo.get_by(decision_id: decision_id, key: key) do
      nil -> nil
      cache -> cache.value
    end
  end

  @spec cache_value_exists(String.t(), integer() | struct()) :: String.t() | nil
  def cache_value_exists(key, %Decision{} = decision), do: cache_value_exists(key, decision.id)

  def cache_value_exists(key, decision_id) do
    EctoHelper.exists?(Cache, %{decision_id: decision_id, key: key}, [:decision_id, :key])
  end

  @spec update_cache_value(String.t(), String.t(), integer() | struct()) :: :ok
  def update_cache_value(key, value, %Decision{} = decision) do
    Cache.create_changeset(%{key: key, value: value}, decision)
    |> Repo.insert(on_conflict: :replace_all, conflict_target: [:decision_id, :key])

    :ok
  end

  def update_cache_value(key, value, decision_id) when is_integer(decision_id) do
    update_cache_value(key, value, Structure.get_decision(decision_id))
  end

  @spec delete_cache_value(String.t(), integer() | struct()) :: :ok
  def delete_cache_value(key, %Decision{id: id}), do: delete_cache_value(key, id)

  def delete_cache_value(key, decision_id) do
    case Cache |> Repo.get_by(decision_id: decision_id, key: key) do
      %Cache{} = cache ->
        Repo.delete(cache)
        :ok

      _ ->
        :ok
    end
  end
end
