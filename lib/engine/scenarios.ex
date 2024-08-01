defmodule Engine.Scenarios do
  @moduledoc """
  The boundary for the Scenarios system.

  All access to update database values go through this class.
  To keep code files small, the actual methods are in the /queries folder
  and are linked with defdelegate
  """

  alias Engine.Scenarios.Queries.Scenario
  alias Engine.Scenarios.Queries.ScenarioStats
  alias Engine.Scenarios.Queries.ScenarioDisplay
  alias Engine.Scenarios.Queries.ScenarioSet
  alias Engine.Scenarios.Queries.SolveDump
  alias Engine.Scenarios.Queries.ScenarioImport
  alias Engine.Scenarios.Queries.ScenarioConfig

  defdelegate preloaded_assoc(record, association), to: EtheloApi.Helpers.BatchHelper
  defdelegate associated_id(record, association), to: EtheloApi.Helpers.BatchHelper

  defdelegate list_scenario_sets(decision_id, filters \\ %{}), to: ScenarioSet
  defdelegate list_participant_scenario_sets(decision_id, participant, filters \\ %{}), to: ScenarioSet
  defdelegate match_scenario_sets(filters, decision_ids), to: ScenarioSet
  defdelegate get_latest_scenario_set(decision, filters \\ %{}), to: ScenarioSet
  defdelegate get_scenario_set(id, decision), to: ScenarioSet
  defdelegate touch_scenario_set(id, decision), to: ScenarioSet
  defdelegate set_scenario_set_engine_start(id, decision), to: ScenarioSet
  defdelegate set_scenario_set_engine_end(id, decision), to: ScenarioSet
  defdelegate set_scenario_set_error(id, decision, error), to: ScenarioSet
  defdelegate find_or_create_scenario_set(decision, filters, attrs), to: ScenarioSet
  defdelegate create_scenario_set(decision, attrs), to: ScenarioSet
  defdelegate update_scenario_set(scenario_set, attrs), to: ScenarioSet
  defdelegate delete_scenario_set(scenario_set_id, decision_id), to: ScenarioSet
  defdelegate delete_expired_scenario_sets(decision_id), to: ScenarioSet

  defdelegate list_solve_dumps(decision_id, filters \\ %{}), to: SolveDump
  defdelegate match_solve_dumps(filters, decision), to: SolveDump
  defdelegate get_latest_solve_dump(decision, filters \\ %{}), to: SolveDump
  defdelegate get_solve_dump(id, decision), to: SolveDump
  defdelegate upsert_solve_dump(decision, attrs), to: SolveDump
  defdelegate delete_solve_dump(solve_dump_id, decision_id), to: SolveDump

  defdelegate list_scenario_stats(scenario_set_id, filters \\ %{}), to: ScenarioStats

  defdelegate list_scenario_displays(scenario_id, filters \\ %{}), to: ScenarioDisplay
  defdelegate match_scenario_displays(filters, decision_ids), to: ScenarioDisplay
  defdelegate get_scenario_display(id, scenario_id), to: ScenarioDisplay

  defdelegate list_scenarios(scenario_set_id, filters \\ %{}), to: Scenario
  defdelegate get_global_scenario(scenario_set_id), to: Scenario
  defdelegate match_scenarios(filters, decision_ids), to: Scenario
  defdelegate get_scenario(id, scenario_set_id), to: Scenario
  defdelegate create_scenario(scenario_set_id, attrs), to: Scenario
  defdelegate update_scenario(scenario, attrs), to: Scenario

  defdelegate list_scenario_configs(decision_id, filters \\ %{}), to: ScenarioConfig
  defdelegate match_scenario_configs(filters, decision_ids), to: ScenarioConfig
  defdelegate get_scenario_config(id, decision), to: ScenarioConfig
  defdelegate create_scenario_config(decision, attrs), to: ScenarioConfig
  defdelegate update_scenario_config(scenario_config, attrs), to: ScenarioConfig
  defdelegate delete_scenario_config(scenario_config, decision_id), to: ScenarioConfig

  defdelegate import_scenario_set(scenario_set, voting_data, scenarios_json, options \\ %{}), to: ScenarioImport
end
