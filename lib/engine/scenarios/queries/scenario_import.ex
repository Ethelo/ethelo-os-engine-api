defmodule Engine.Scenarios.Queries.ScenarioImport do
  @moduledoc """
  Contains methods that will be delegated to inside scenarios.
  Used purely to reduce the size of scenarios.ex
  """
  require Poison
  require Logger
  use Ecto.Schema
  use Timex.Ecto.Timestamps
  import Ecto.Query, warn: false
  alias EtheloApi.Repo
  alias Engine.Scenarios.ScenarioSet
  alias Engine.Scenarios.Scenario
  alias Engine.Scenarios.ScenarioDisplay
  alias Engine.Scenarios.ScenariosOptions
  alias Engine.Scenarios.Queries.ScenarioStatsBuilder, as: StatsBuilder
  alias Engine.Invocation.ScoringData
  alias Engine.Invocation.SolveSettings

  def import_scenario_set(scenario_set, voting_data, scenarios_json, settings)
  def import_scenario_set(%ScenarioSet{status: "success"} = scenario_set, _, _, %SolveSettings{force: false}), do: {:ok, scenario_set}
  def import_scenario_set(%ScenarioSet{} = scenario_set, %ScoringData{} = voting_data, scenarios_json, settings) do
    voting_data = voting_data |> ScoringData.add_scenario_import_data()

    engine_scenarios = unique_scenarios(scenarios_json)

   response = try do
     parsed = parse_scenarios(engine_scenarios, voting_data, scenario_set)
     scenario_count = Scenario
       |> where(scenario_set_id: ^scenario_set.id )
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

    updated_scenario_set = update_scenario_set(response, scenario_set, voting_data)

    if elem(response, 1) == :error do
      response
    else
      {:ok, updated_scenario_set}
    end
  end

  def unique_scenarios(scenarios_json) do
    scenarios_json
    |> Poison.decode()
    |> filter_unique_scenarios
  end

  def parse_scenarios(engine_scenarios, %{} = voting_data, scenario_set) do
    Enum.reduce_while(engine_scenarios, {:ok, []}, fn(engine_scenario, {:ok, scenario_index}) ->
      {status, scenario} = response = Repo.transaction(fn ->
        import_scenario(scenario_set, engine_scenario, voting_data)
      end)

      if( status === :error) do
        IO.inspect("halt due to error")
        {:halt, response}
      else
        scenario_index = scenario_index || []
        scenario_index = scenario_index ++ [{engine_scenario, scenario}]
        {:cont, {:ok, scenario_index}}
      end
    end)
  end

  def update_scenario_set({:error, _}, scenario_set, _voting_data) do
    ScenarioSet.update_changeset(scenario_set, %{status: "error"}) |> Repo.update!
  end
  def update_scenario_set({:ok, scenario_index}, scenario_set, voting_data) do
    scenario_set = add_json_stats(scenario_set, scenario_index, voting_data )
    ScenarioSet.update_changeset(scenario_set, %{status: "success"}) |> Repo.update!
  end

  def add_json_stats(scenario_set, scenario_index, voting_data) do
    [{engine_scenario, _} | _] = scenario_index

    stats = StatsBuilder.build_shared_stats(scenario_set, voting_data, engine_scenario )

    stats = stats ++ Enum.map(scenario_index, fn({engine_scenario, scenario}) ->
      StatsBuilder.build_scenario_stats(scenario, voting_data, engine_scenario)
    end)

    {:ok, as_json} =  Poison.encode(stats, pretty: false)
    ScenarioSet.update_changeset(scenario_set, %{json_stats: as_json}) |> Repo.update!
  end

  def filter_unique_scenarios({:ok, engine_scenarios}) when is_list(engine_scenarios) do
    engine_scenarios
    |> Enum.reduce(%{}, fn(engine_scenario, scenario_list) ->
        global = if (engine_scenario |> get_in(["config", "global"]) == true), do: ["global"], else: []
        key = engine_scenario |> Map.get("options") |> Enum.sort |> Kernel.++(global) |> Enum.join("---")
        Map.put(scenario_list, key, engine_scenario)
      end)
    |> Map.values()
    |> Enum.sort_by(fn(engine_scenario) ->
      engine_scenario |> get_in(["stats", "global", "ethelo"])
    end)
    |> Enum.reverse()
  end

  def filter_unique_scenarios(_engine_scenarios) do
    []
  end

  def import_scenario(%ScenarioSet{} = scenario_set, %{} = engine_scenario, %{} = voting_data) do
    # Create scenario
    scenario_config = Map.get(engine_scenario, "config")
    status =  Map.get(engine_scenario, "status")

    scenario_changeset = Scenario.create_changeset(%Scenario{}, %{
      status: status,
      collective_identity: Map.get(scenario_config, "collective_identity"),
      tipping_point: Map.get(scenario_config, "tipping_point"),
      minimize: Map.get(scenario_config, "minimize"),
      global: Map.get(scenario_config, "global"),
      decision_id: scenario_set.decision_id,
    }, scenario_set)
    {saved, scenario} = Repo.insert(scenario_changeset)

    # Add displays & stats
    if status == "success" && saved == :ok do
      build_displays(scenario, engine_scenario, voting_data)
      add_options_to_scenario(scenario, engine_scenario, voting_data)
    end

    scenario
  end

  def build_displays(%Scenario{} = scenario, %{} = engine_scenario, %{} = voting_data) do
    displays = Enum.map(Map.get(engine_scenario, "constraints", []), &(Map.put(&1, "is_constraint", true))) ++
               Enum.map(Map.get(engine_scenario, "displays", []), &(Map.put(&1, "is_constraint", false)))

    Enum.each(displays, fn(display) ->
      slug = Map.get(display, "name")
      is_constraint = Map.get(display, "is_constraint")
      attrs = %{
        name: slug,
        value: Map.get(display, "value"),
        is_constraint: is_constraint,
        decision_id: scenario.decision_id,
      }

      attrs = if is_constraint do
        attrs |> Map.put(:constraint_id, get_id_by_slug(voting_data.constraints_by_slug, slug))
      else
        attrs |> Map.put(:calculation_id, get_id_by_slug(voting_data.calculations_by_slug, slug))
      end

      ScenarioDisplay.create_changeset(%ScenarioDisplay{}, attrs, scenario) |> Repo.insert!
    end)
  end

  def get_id_by_slug(list, slug) do
    map = Map.get(list, slug, nil)
    if is_nil(map), do: nil, else: Map.get(map, :id, nil)
  end

  def add_options_to_scenario(%Scenario{} = scenario, %{} = engine_scenario, %{} = voting_data) do
    Enum.each(Map.get(engine_scenario, "options", []), fn(option_slug) ->
      ScenariosOptions.create_changeset(%ScenariosOptions{}, %{
        scenario_id: scenario.id,
        option_id: Map.get(voting_data.options_by_slug, option_slug).id
      }) |> Repo.insert!
    end)
  end

end
