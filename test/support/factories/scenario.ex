defmodule Engine.Scenarios.Factory do
  @moduledoc """
  Factories to use when testing Ethelo ScenarioSets
  """
  use EtheloApi.BaseFactory, module: __MODULE__

  alias EtheloApi.Structure.Factory, as: StructureFactory

  alias EtheloApi.Structure.Decision
  alias Engine.Scenarios.ScenarioSet
  alias Engine.Scenarios.SolveDump
  alias Engine.Scenarios.Scenario
  alias Engine.Scenarios.ScenarioDisplay
  alias Engine.Scenarios.ScenarioConfig

  ## ScenarioConfig ##

  def scenario_config_defaults() do
    %ScenarioConfig{
      title: "ScenarioConfig#{unique_int()}",
      slug: "scenario-config#{unique_int()}",
      bins: Enum.random(1..9),
      skip_solver: random_bool(),
      ttl: Enum.random(100..10000),
      engine_timeout: Enum.random(10000..80000),
      preview_engine_hash: "#{unique_int()}",
      published_engine_hash: "#{unique_int()}",
      support_only: random_bool(),
      per_option_satisfaction: random_bool(),
      max_scenarios: Enum.random(1..20),
      normalize_satisfaction: random_bool(),
      normalize_influents: random_bool(),
      ci: Decimal.from_float(Enum.random(100..1000) / 1000),
      tipping_point: Decimal.from_float(Enum.random(100..1000) / 1000),
      enabled: random_bool(),
      quadratic: random_bool(),
      quad_user_seeds: Enum.random(100..200),
      quad_total_available: Enum.random(30000..580000),
      quad_cutoff: Enum.random(3000..7500),
      quad_seed_percent: Enum.random(100..1000) / 1000,
      quad_vote_percent: Enum.random(100..1000) / 1000,
      quad_max_allocation: Enum.random(3000..50000),
      quad_round_to: Enum.random(1000..5000),
    }
  end

  def scenario_config_deps() do
    decision = StructureFactory.create_decision()
    scenario_config_deps(decision)
  end

  def scenario_config_deps(%Decision{} = decision) do
    %{decision: decision}
  end

  def create_scenario_config() do
    decision = StructureFactory.create_decision()
    create_scenario_config(decision)
  end

  def create_scenario_config(%Decision{} = decision, overrides \\ %{}) do
    deps = scenario_config_deps(decision)
    values = Map.merge(deps, overrides)
    scenario_config = insert(scenario_config_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:scenario_config, scenario_config)
  end

  def create_scenario_config_without_deps(%Decision{} = decision, %{} = values) do
    values = Map.put(values, :decision, decision)
    insert(scenario_config_defaults(), values)
  end

  def delete_scenario_config(id) do
    ScenarioConfig |> do_delete_all(id)
  end


  ## ScenarioSet ##

  def scenario_set_defaults() do
    %ScenarioSet{
      status: "pending",
    }
  end

  def scenario_set_deps() do
    decision = StructureFactory.create_decision()
    scenario_set_deps(decision)
  end

  def scenario_set_deps(%Decision{} = decision) do
    %{decision: decision}
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
      error: "",
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
      decision: scenario_set.decision, decision_id: scenario_set.decision_id,
      scenario_set: scenario_set,
    }
  end

  def create_scenario() do
    %{scenario_set: scenario_set} = create_scenario_set()
    create_scenario(scenario_set)
  end

  def create_scenario(%{} = scenario_set, overrides \\ %{}) do
    deps = scenario_deps(scenario_set)
    values = Map.merge(deps, overrides)
          |> Map.put(:scenario_set_id, scenario_set.id)

    scenario = insert(scenario_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:scenario, scenario)
  end

  def create_scenario_without_deps(%Decision{} = decision, %{} = values) do
    values = Map.put(values, :decision, decision)
    insert(scenario_defaults(), values)
  end

  def delete_scenario(id) do
    Scenario |> do_delete_all(id)
  end

  def scenario_display_defaults() do
    %ScenarioDisplay{
      name: "ScenarioDisplay#{unique_int()}",
      is_constraint:  random_bool(),
      value: Enum.random(1..100) / 10
    }
  end

  def create_scenario_display_without_deps(%Decision{} = decision, %{} = values) do
    values = Map.put(values, :decision, decision)
    insert(scenario_display_defaults(), values)
  end

end
