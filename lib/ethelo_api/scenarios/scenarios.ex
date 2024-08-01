defmodule EtheloApi.Scenarios do
  @moduledoc """
  The boundary for the Scenarios system.

  All access to update database values go through this module.
  To keep code files small, the actual methods are in the /queries folder
  and are linked with defdelegate
  """

  alias EtheloApi.Scenarios.Queries.Scenario
  alias EtheloApi.Scenarios.Queries.ScenarioStats
  alias EtheloApi.Scenarios.Queries.ScenarioDisplay
  alias EtheloApi.Scenarios.Queries.ScenarioSet
  alias EtheloApi.Scenarios.Queries.SolveDump

  defdelegate list_scenario_sets(decision_id, modifiers \\ %{}), to: ScenarioSet
  defdelegate match_latest_scenario_set(decision, modifiers \\ %{}), to: ScenarioSet
  defdelegate get_scenario_set(id, decision), to: ScenarioSet
  defdelegate touch_scenario_set(id, decision), to: ScenarioSet
  defdelegate set_scenario_set_engine_start(id, decision), to: ScenarioSet
  defdelegate set_scenario_set_engine_end(id, decision), to: ScenarioSet
  defdelegate set_scenario_set_error(id, decision, error), to: ScenarioSet

  defdelegate create_scenario_set(attrs, decision), to: ScenarioSet
  defdelegate update_scenario_set(scenario_set, attrs), to: ScenarioSet
  defdelegate delete_scenario_set(scenario_set_id, decision_id), to: ScenarioSet
  defdelegate delete_expired_scenario_sets(decision_id), to: ScenarioSet
  defdelegate clean_pending_scenario_sets(decision_id), to: ScenarioSet

  defdelegate list_scenario_displays(scenario_id, modifiers \\ %{}), to: ScenarioDisplay
  defdelegate create_scenario_display(attrs), to: ScenarioDisplay

  defdelegate list_scenario_stats(scenario_set_id, modifiers \\ %{}), to: ScenarioStats

  defdelegate list_scenarios(scenario_set_id, modifiers \\ %{}), to: Scenario
  defdelegate create_scenario(attrs), to: Scenario

  defdelegate get_solve_dump(scenario_set_id), to: SolveDump
  defdelegate upsert_solve_dump(attrs), to: SolveDump
end
