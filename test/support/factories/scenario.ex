defmodule EtheloApi.Scenarios.Factory do
  @moduledoc """
  Factories to use when testing Ethelo ScenarioSets
  """
  use EtheloApi.BaseFactory, module: __MODULE__

  alias EtheloApi.Structure.Factory, as: StructureFactory

  alias EtheloApi.Structure.Decision
  alias EtheloApi.Scenarios.ScenarioSet
  alias EtheloApi.Scenarios.SolveDump
  alias EtheloApi.Scenarios.Scenario
  alias EtheloApi.Scenarios.ScenarioDisplay
  alias EtheloApi.Scenarios.ScenariosOptions
  alias EtheloApi.Invocation.Cache

  ## Cache ##
  def cache_defaults() do
    %Cache{
      key: "cache-#{unique_int()}",
      value: short_sentence()
    }
  end

  def cache_deps() do
    decision = StructureFactory.create_decision()
    %{decision: decision}
  end

  def create_cache() do
    decision = StructureFactory.create_decision()
    create_cache(decision)
  end

  def create_cache(%Decision{} = decision, overrides \\ %{}) do
    deps = %{decision: decision}
    values = Map.merge(deps, overrides)
    cache = insert(cache_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:cache, cache)
  end

  def delete_cache(id) do
    Cache |> do_delete_all(id)
  end

  ## ScenarioSet ##
  def scenario_set_defaults() do
    %ScenarioSet{
      status: "pending",
      hash: short_sentence(),
      error: nil,
      cached_decision: random_bool(),
      engine_start: DateTime.utc_now() |> DateTime.add(-1000) |> DateTime.truncate(:second),
      engine_end: DateTime.utc_now() |> DateTime.add(-500) |> DateTime.truncate(:second)
    }
  end

  def scenario_set_deps() do
    decision = StructureFactory.create_decision()
    scenario_set_deps(decision)
  end

  def scenario_set_deps(%Decision{} = decision) do
    %{scenario_config: scenario_config} = StructureFactory.create_scenario_config(decision)
    %{scenario_config: scenario_config, decision: decision}
  end

  def create_scenario_set() do
    decision = StructureFactory.create_decision()
    create_scenario_set(decision)
  end

  def create_scenario_set(%Decision{} = decision, overrides \\ %{}) do
    deps = scenario_set_deps(decision)
    values = Map.merge(deps, overrides)
    scenario_set = insert(scenario_set_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:scenario_set, scenario_set)
  end

  def create_scenario_set_without_deps(%Decision{} = decision, %{} = values) do
    values = Map.put(values, :decision, decision)
    insert(scenario_set_defaults(), values)
  end

  def delete_scenario_set(id) do
    ScenarioSet |> do_delete_all(id)
  end

  ## SolveDump ##

  def solve_dump_defaults() do
    %SolveDump{
      decision_json: "{}",
      influents_json: "{}",
      weights_json: "{}",
      config_json: "{}",
      response_json: "{}",
      error: ""
    }
  end

  def solve_dump_deps() do
    create_scenario_set()
  end

  def solve_dump_deps(%Decision{} = decision) do
    create_scenario_set(decision)
  end

  def create_solve_dump() do
    decision = StructureFactory.create_decision()
    create_solve_dump(decision)
  end

  def create_solve_dump(%Decision{} = decision, overrides \\ %{}) do
    deps = solve_dump_deps(decision)
    values = Map.merge(deps, overrides)
    solve_dump = insert(solve_dump_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:solve_dump, solve_dump)
  end

  def create_solve_dump_without_deps(%Decision{} = decision, %{} = values) do
    values = Map.put(values, :decision, decision)
    insert(solve_dump_defaults(), values)
  end

  def delete_solve_dump(id) do
    SolveDump |> do_delete_all(id)
  end

  ## Scenario ##

  def scenario_defaults() do
    %Scenario{
      status: "pending",
      collective_identity: 0.5,
      tipping_point: 0.333,
      minimize: false,
      global: false
    }
  end

  def scenario_deps() do
    %{scenario_set: scenario_set} = create_scenario_set()
    scenario_deps(scenario_set)
  end

  def scenario_deps(%{} = scenario_set) do
    %{
      decision: scenario_set.decision,
      decision_id: scenario_set.decision_id,
      scenario_set: scenario_set
    }
  end

  def create_scenario() do
    %{scenario_set: scenario_set} = create_scenario_set()
    create_scenario(scenario_set)
  end

  def create_scenario(record, overrides \\ %{})

  def create_scenario(%Decision{} = decision, overrides) do
    %{scenario_set: scenario_set} = create_scenario_set(decision)
    create_scenario(scenario_set, overrides)
  end

  def create_scenario(%{} = scenario_set, overrides) do
    deps = scenario_deps(scenario_set)

    values =
      Map.merge(deps, overrides)
      |> Map.put(:scenario_set_id, scenario_set.id)

    scenario = insert(scenario_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:scenario, scenario)
  end

  def create_scenario_without_deps(%Decision{} = decision, %{} = values) do
    values = Map.put(values, :decision, decision)
    insert(scenario_defaults(), values)
  end

  def create_option_on_scenario(scenario, %Decision{} = decision) do
    %{option: option} = deps = StructureFactory.create_option(decision)

    values = %ScenariosOptions{
      scenario_id: scenario.id,
      option_id: option.id
    }

    scenario_option = insert(values, %{})

    deps
    |> Map.put(:scenario, scenario)
    |> Map.put(:scenario_option, scenario_option)
  end

  def delete_scenario(id) do
    Scenario |> do_delete_all(id)
  end

  def scenario_display_defaults() do
    %ScenarioDisplay{
      name: "ScenarioDisplay#{unique_int()}",
      is_constraint: random_bool(),
      value: Enum.random(1..100) / 10
    }
  end

  def create_scenario_display_without_deps(%Decision{} = decision, %{} = values) do
    values = Map.put(values, :decision, decision)
    insert(scenario_display_defaults(), values)
  end

  def update_scenario_set_stats(scenario_set_id, stats) when is_list(stats) do
    {:ok, as_json} = Jason.encode(stats, pretty: false)

    values = %{json_stats: as_json}

    update(ScenarioSet, scenario_set_id, values)
  end
end
