defmodule Engine.Invocation.Queries.Cache do
  @moduledoc """
  Contains methods that will be delegated to inside structure.
  Used purely to reduce the size of structure.ex
  """

  import Ecto.Query, warn: false
  alias EtheloApi.Repo

  alias Engine.Invocation
  alias Engine.Invocation.Cache
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias Engine.Scenarios
  alias Engine.Scenarios.ScenarioConfig

  def hash_from_string(string) do
    :crypto.hash(:md5, [string]) |> Base.encode16()
  end
  def update_preprocessed_cache(decision_json, decision_id) when is_binary(decision_json) do
    {status, preprocessed_file} = Invocation.engine_preprocessed(decision_json)
    if status == :ok do
      update_cache_value(Invocation.preprocessed_key(), preprocessed_file, decision_id)
    else
      delete_cache_value(Invocation.preprocessed_key(), decision_id)
    end
  end
  def update_preprocessed_cache(_, _), do: {:error, "invalid decision json"}

  def update_decision_cache(decision_id) when is_integer(decision_id) do
    Structure.get_decision(decision_id) |> update_decision_cache
  end

  def update_decision_cache(%Decision{} = decision) do
    decision_json = generate_decision_json(decision)
    update_cache_value(Invocation.decision_key(), decision_json, decision.id)

    hash = hash_from_string(decision_json)
    Structure.update_decision(decision.id, %{
      published_decision_hash: hash,
      preview_decision_hash: hash
    })

    update_preprocessed_cache(decision_json, decision.id)
    {:ok, Structure.get_decision(decision.id)}
  end

  def generate_decision_json(%Decision{} = decision) do
    EtheloApi.Structure.ensure_filters_and_vars(decision)
    Invocation.build_decision_json(decision.id, false)
  end

  def update_scenario_config_cache(%ScenarioConfig{} = scenario_config, %Decision{} = decision) do
    scenario_config_json = Invocation.build_config_json(scenario_config, decision)

    update_cache_value(
      Invocation.scenario_config_key(scenario_config.id),
      scenario_config_json,
      decision.id
    )

    Scenarios.update_scenario_config(scenario_config, %{
      published_engine_hash: hash_from_string(scenario_config_json)
    })

    {:ok, scenario_config}
  end

  def update_scenario_config_cache(scenario_config_id, decision) do
    scenario_config = Scenarios.get_scenario_config(scenario_config_id, decision)
    update_scenario_config_cache(scenario_config, decision)
  end

  def get_cache_value(key, %Decision{} = decision), do: get_cache_value(key, decision.id)

  def get_cache_value(key, decision_id) do
    case Cache |> Repo.get_by(decision_id: decision_id, key: key) do
      nil -> nil
      cache -> cache.value
    end
  end

  def update_cache_value(key, value, %Decision{} = decision) do
    %Cache{}
    |> Cache.create_changeset(%{key: key, value: value}, decision)
    |> Repo.insert(on_conflict: :replace_all, conflict_target: [:decision_id, :key])

    :ok
  end

  def update_cache_value(key, value, decision_id) when is_integer(decision_id) do
    update_cache_value(key, value, Structure.get_decision(decision_id))
  end

  def delete_cache_value(key, %Decision{} = decision), do: delete_cache_value(key, decision.id)

  def delete_cache_value(key, decision_id) do
    case Cache |> Repo.get_by(decision_id: decision_id, key: key) do
      nil ->
        :ok

      cache ->
        Repo.delete(cache)
        :ok
    end
  end
end
