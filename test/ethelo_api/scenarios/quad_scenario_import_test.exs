defmodule EtheloApi.Scenarios.QuadScenarioImportTest do
  @moduledoc """
  Validations and basic access for ScoringData with Quadratic Voting
  """

  use EtheloApi.DataCase
  @moduletag scenarios: true, quad: true

  import Ecto.Query, warn: false

  alias EtheloApi.Repo
  alias EtheloApi.Invocation.ScoringData
  alias EtheloApi.Invocation.InvocationSettings
  alias EtheloApi.Scenarios
  alias EtheloApi.Scenarios.Scenario
  alias EtheloApi.Scenarios.Queries.ScenarioImport

  setup do
    %{decision: decision, scenario_config: scenario_config} =
      EtheloApi.Blueprints.QuadVotingProject.build()

    # initialize Scenario import early so we can use it in tests
    import_data =
      ScoringData.initialize_all_voting(decision.id, scenario_config)
      |> ScoringData.add_scenario_import_data()

    result_json = load_support_file("quadratic/result.json")

    {:ok, settings} =
      InvocationSettings.build(decision.id, scenario_config.id)

    {:ok, scenario_set} = Scenarios.create_scenario_set(%{status: "pending"}, decision)

    {:ok, updated_scenario_set} =
      ScenarioImport.import(scenario_set, import_data, result_json, settings)

    {:ok, decoded_result} = Jason.decode(result_json)

    %{
      scenario_set: updated_scenario_set,
      decoded_result: decoded_result,
      quadratic_totals: import_data.quadratic_totals
    }
  end

  test "quad stats added to issues", context do
    context.quadratic_totals.by_oc
    |> Enum.each(fn {oc_id, quadratic_stats} ->
      saved_stats = load_matching_stats(context.scenario_set, %{issue_id: oc_id})
      assert_valid_quadratic_stats(quadratic_stats, saved_stats)
    end)
  end

  test "global stats imported", context do
    scenario = context |> global_scenario

    quadratic_stats = context.quadratic_totals.global
    saved_stats = load_matching_stats(context.scenario_set, %{scenario_id: scenario.imported.id})
    assert_valid_quadratic_stats(quadratic_stats, saved_stats)
  end

  defp global_scenario(context) do
    [engine_scenario | _] = context.decoded_result

    imported_scenario =
      %Scenario{} =
      Scenario
      |> where(scenario_set_id: ^context.scenario_set.id, global: true)
      |> first
      |> preload([:scenario_set, :scenario_displays, :options])
      |> Repo.one()

    %{engine: engine_scenario, imported: imported_scenario}
  end

  defp assert_valid_quadratic_stats(quadratic_stats, imported_stats) do
    assert Map.get(quadratic_stats, :seeds_assigned) == imported_stats.seeds_assigned

    assert Map.get(quadratic_stats, :positive_seed_votes_sq) ==
             imported_stats.positive_seed_votes_sq

    assert Map.get(quadratic_stats, :positive_seed_votes_sum) ==
             imported_stats.positive_seed_votes_sum

    assert Map.get(quadratic_stats, :seed_allocation) == imported_stats.seed_allocation
    assert Map.get(quadratic_stats, :vote_allocation) == imported_stats.vote_allocation
    assert Map.get(quadratic_stats, :combined_allocation) == imported_stats.combined_allocation
    assert Map.get(quadratic_stats, :final_allocation) == imported_stats.final_allocation
  end

  def load_matching_stats(scenario_set, assocs) do
    scenario_set
    |> Scenarios.list_scenario_stats(assocs)
    |> List.first()
  end
end
