defmodule Engine.Scenarios.QuadScenarioImportTest do
  @moduledoc """
  Validations and basic access for ScoringData with Quadratic Voting
  """
  #@moduletag scenarios: true, quad: true

  require OK
  use EtheloApi.DataCase
  import Ecto.Query, warn: false
  alias EtheloApi.Repo
  alias Engine.Scenarios
  alias Engine.Invocation.ScoringData
  alias Engine.Scenarios.Scenario
  alias Engine.Invocation

  setup do
    %{decision: decision, scenario_config: scenario_config} = EtheloApi.Blueprints.QuadVotingProject.build()

    voting_data = ScoringData.initialize_all_voting(decision.id, scenario_config.id)
      |> ScoringData.add_scenario_import_data()

    scenario_set_json = File.read!(Path.join("#{:code.priv_dir(:ethelo)}", "tests/quadratic/result.json"))
    {:ok, scenario_set} = Scenarios.create_scenario_set(decision.id, %{status: "pending"})
    {:ok, settings} = Invocation.build_solve_settings(decision.id, [scenario_config_id: scenario_config.id])
    {:ok, updated_scenario_set} = Scenarios.import_scenario_set(scenario_set, voting_data, scenario_set_json, settings)
    {:ok, %{
      voting_data: voting_data,
      scenario_set: updated_scenario_set,
      scenario_set_json: Poison.decode!(scenario_set_json),
      settings: settings,
      quadratic_totals: voting_data.quadratic_totals}
    }
  end

  test "issue stats imported", state do
    state.quadratic_totals.by_oc
      |> Enum.each( fn({oc_id, quadratic_stats}) ->
        saved_stats = load_matching_stats(state.scenario_set, %{issue_id: oc_id })
        assert_valid_quadratic_stats(quadratic_stats, saved_stats)
      end)
  end

  test "global stats imported", state do
    scenario = state |> global_scenario

    quadratic_stats = state.quadratic_totals.global
    saved_stats = load_matching_stats(state.scenario_set, %{scenario_id: scenario.imported.id})
    assert_valid_quadratic_stats(quadratic_stats, saved_stats)
  end

  defp global_scenario(state) do
    [engine_scenario | _] = state[:scenario_set_json]
    imported_scenario = %Scenario{} = Scenario |> where(scenario_set_id: ^state.scenario_set.id, global: true)
                                 |> first
                                 |> preload([:scenario_set, :scenario_displays, :options])
                                 |> Repo.one
    %{engine: engine_scenario, imported: imported_scenario}
  end

  defp assert_valid_quadratic_stats(quadratic_stats, imported_stats) do
    assert Map.get( quadratic_stats, :seeds_assigned ) == imported_stats.seeds_assigned
    assert Map.get( quadratic_stats, :positive_seed_votes_sq ) == imported_stats.positive_seed_votes_sq
    assert Map.get( quadratic_stats, :positive_seed_votes_sum ) == imported_stats.positive_seed_votes_sum
    assert Map.get( quadratic_stats, :seed_allocation ) == imported_stats.seed_allocation
    assert Map.get( quadratic_stats, :vote_allocation ) == imported_stats.vote_allocation
    assert Map.get( quadratic_stats, :combined_allocation ) == imported_stats.combined_allocation
    assert Map.get( quadratic_stats, :final_allocation ) == imported_stats.final_allocation
  end

  def load_matching_stats(scenario_set, assocs) do
    scenario_set
      |> Scenarios.list_scenario_stats(assocs)
      |> List.first
  end

end
