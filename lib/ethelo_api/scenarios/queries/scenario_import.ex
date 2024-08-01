defmodule EtheloApi.Scenarios.Queries.ScenarioImport do
  @moduledoc """
  Contains methods that will be delegated to inside scenarios.
  Used purely to reduce the size of scenarios.ex
  """
  require Logger
  use Ecto.Schema
  import Ecto.Query, warn: false
  alias EtheloApi.Repo
  alias EtheloApi.Scenarios
  alias EtheloApi.Scenarios.ScenarioSet
  alias EtheloApi.Scenarios.Scenario
  alias EtheloApi.Scenarios.ScenariosOptions
  alias EtheloApi.Scenarios.Queries.ScenarioStatsBuilder, as: StatsBuilder
  alias EtheloApi.Invocation.ScoringData
  alias EtheloApi.Invocation.InvocationSettings

  def import(scenario_set, voting_data, scenarios_json, settings)

  def import(%ScenarioSet{status: "success"} = scenario_set, _, _, %InvocationSettings{
        force: false
      }),
      do: {:ok, scenario_set}

  def import(
        %ScenarioSet{} = scenario_set,
        %ScoringData{} = voting_data,
        scenarios_json,
        _settings
      ) do
    import_data = voting_data |> ScoringData.add_scenario_import_data()

    engine_scenarios = unique_scenarios(scenarios_json)

    response =
      try do
        parsed = parse_scenarios(engine_scenarios, import_data, scenario_set)

        scenario_count =
          Scenario
          |> where(scenario_set_id: ^scenario_set.id)
          |> Repo.aggregate(:count, :id)

        if scenario_count < 1 && elem(parsed, 1) != :error do
          {:error, "no scenarios imported"}
        else
          parsed
        end
      rescue
        e ->
          {:error, "error when importing #{Exception.message(e)}"}
      end

    updated_scenario_set = update_scenario_set(response, scenario_set, import_data)

    if elem(response, 1) == :error do
      response
    else
      {:ok, updated_scenario_set}
    end
  end

  def unique_scenarios(scenarios_json) do
    scenarios_json
    |> Jason.decode()
    |> filter_unique_scenarios
  end

  def parse_scenarios(engine_scenarios, %{} = import_data, scenario_set) do
    Enum.reduce_while(engine_scenarios, {:ok, []}, fn engine_scenario, {:ok, scenario_index} ->
      {status, scenario} =
        response =
        Repo.transaction(fn ->
          import_scenario(scenario_set, engine_scenario, import_data)
        end)

      if status === :error do
        {:halt, response}
      else
        scenario_index = scenario_index || []
        scenario_index = scenario_index ++ [{engine_scenario, scenario}]
        {:cont, {:ok, scenario_index}}
      end
    end)
  end

  def update_scenario_set({:error, _}, scenario_set, _import_data) do
    {:ok, scenario_set} =
      Scenarios.set_scenario_set_error(scenario_set, scenario_set.decision_id, "Unable to save")

    scenario_set
  end

  def update_scenario_set({:ok, scenario_index}, scenario_set, import_data) do
    add_json_stats(scenario_set, scenario_index, import_data)
  end

  def add_json_stats(scenario_set, scenario_index, import_data) do
    [{engine_scenario, _} | _] = scenario_index

    stats = StatsBuilder.build_shared_stats(scenario_set, import_data, engine_scenario)

    stats =
      stats ++
        Enum.map(scenario_index, fn {engine_scenario, scenario} ->
          StatsBuilder.build_scenario_stats(scenario, import_data, engine_scenario)
        end)

    {:ok, as_json} = Jason.encode(stats, pretty: false)

    {:ok, scenario_set} =
      Scenarios.update_scenario_set(scenario_set, %{status: "success", json_stats: as_json})

    scenario_set
  end

  def filter_unique_scenarios({:ok, engine_scenarios}) when is_list(engine_scenarios) do
    engine_scenarios
    |> Enum.reduce(%{}, fn engine_scenario, scenario_list ->
      global =
        if engine_scenario |> get_in(["config", "global"]) == true, do: ["global"], else: []

      key =
        engine_scenario
        |> Map.get("options")
        |> Enum.sort()
        |> Kernel.++(global)
        |> Enum.join("---")

      Map.put(scenario_list, key, engine_scenario)
    end)
    |> Map.values()
    |> Enum.sort_by(fn engine_scenario ->
      engine_scenario |> get_in(["stats", "global", "ethelo"])
    end)
    |> Enum.reverse()
  end

  def filter_unique_scenarios(_engine_scenarios) do
    []
  end

  def import_scenario(%ScenarioSet{} = scenario_set, %{} = engine_scenario, %{} = import_data) do
    # Create scenario
    scenario_config = Map.get(engine_scenario, "config")
    status = Map.get(engine_scenario, "status")

    attrs =
      %{
        collective_identity: Map.get(scenario_config, "collective_identity"),
        decision_id: scenario_set.decision_id,
        global: Map.get(scenario_config, "global"),
        minimize: Map.get(scenario_config, "minimize"),
        scenario_set_id: scenario_set.id,
        status: status,
        tipping_point: Map.get(scenario_config, "tipping_point")
      }

    {saved, scenario} = Scenarios.create_scenario(attrs)

    # Add displays & stats
    if status == "success" && saved == :ok do
      build_displays(scenario, engine_scenario, import_data)
      add_options_to_scenario(scenario, engine_scenario, import_data)
    end

    scenario
  end

  def build_displays(%Scenario{} = scenario, %{} = engine_scenario, %{} = import_data) do
    displays =
      Enum.map(Map.get(engine_scenario, "constraints", []), &Map.put(&1, "is_constraint", true)) ++
        Enum.map(Map.get(engine_scenario, "displays", []), &Map.put(&1, "is_constraint", false))

    Enum.each(displays, fn display ->
      slug = Map.get(display, "name")
      is_constraint = Map.get(display, "is_constraint")

      attrs = %{
        name: slug,
        value: Map.get(display, "value"),
        is_constraint: is_constraint,
        decision_id: scenario.decision_id,
        scenario_id: scenario.id
      }

      attrs =
        if is_constraint do
          attrs |> Map.put(:constraint_id, get_id_by_slug(import_data.constraints_by_slug, slug))
        else
          attrs
          |> Map.put(:calculation_id, get_id_by_slug(import_data.calculations_by_slug, slug))
        end

      Scenarios.create_scenario_display(attrs)
    end)
  end

  def get_id_by_slug(list, slug) do
    map = Map.get(list, slug, nil)
    if is_nil(map), do: nil, else: Map.get(map, :id, nil)
  end

  def add_options_to_scenario(%Scenario{} = scenario, %{} = engine_scenario, %{} = import_data) do
    Enum.each(Map.get(engine_scenario, "options", []), fn option_slug ->
      ScenariosOptions.create_changeset(%{
        scenario_id: scenario.id,
        option_id: Map.get(import_data.options_by_slug, option_slug).id
      })
      |> Repo.insert!()
    end)
  end
end
