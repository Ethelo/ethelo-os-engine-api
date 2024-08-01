defmodule EtheloApi.Scenarios.ScenarioImportTest do
  @moduledoc """
  Validations and basic access for ScoringData
  """

  use EtheloApi.DataCase
  @moduletag scenarios: true

  import Ecto.Query, warn: false
  import EtheloApi.Structure.Factory

  alias EtheloApi.Repo
  alias EtheloApi.Invocation.ScoringData
  alias EtheloApi.Invocation.InvocationSettings
  alias EtheloApi.Scenarios
  alias EtheloApi.Scenarios.Scenario
  alias EtheloApi.Scenarios.Queries.ScenarioImport

  setup do
    %{decision: decision, scenario_config: scenario_config} =
      EtheloApi.Blueprints.PizzaProject.build()

    voting_data = ScoringData.initialize_all_voting(decision.id, scenario_config)

    result_json = load_support_file("pizza/result.json")

    {:ok, settings} =
      InvocationSettings.build(decision.id, scenario_config.id)

    {:ok, scenario_set} = Scenarios.create_scenario_set(%{status: "pending"}, decision)

    {:ok, updated_scenario_set} =
      ScenarioImport.import(scenario_set, voting_data, result_json, settings)

    {:ok, decoded_result} = Jason.decode(result_json)

    %{
      voting_data: voting_data,
      scenario_set: updated_scenario_set,
      decoded_result: decoded_result,
      result_json: result_json,
      settings: settings
    }
  end

  test "all scenarios imported", context do
    %{scenario_set: scenario_set, decoded_result: decoded_result} = context
    # 12?
    scenario_count =
      Scenario |> where([s], scenario_set_id: ^scenario_set.id) |> Repo.aggregate(:count, :id)

    # one duplicate in the results
    assert scenario_count == length(decoded_result) - 1
  end

  test "Options imported", context do
    scenario = context |> global_scenario
    refute nil == scenario.imported

    selection_engine = MapSet.new(Map.get(scenario.json_scenario, "options"))
    selection_imported = MapSet.new(Enum.map(scenario.imported.options, & &1.slug))
    assert selection_engine == selection_imported
  end

  test "displays imported", context do
    scenario = context |> global_scenario
    refute nil == scenario.imported

    scenario_displays_by_name = Enum.group_by(scenario.imported.scenario_displays, & &1.name)

    (Map.get(scenario.json_scenario, "constraints") ++ Map.get(scenario.json_scenario, "displays"))
    |> Enum.each(fn display ->
      assert Map.has_key?(scenario_displays_by_name, display["name"])
      assert List.first(scenario_displays_by_name[display["name"]]).value == display["value"]
    end)
  end

  test "import stats detailed test", context do
    %{voting_data: voting_data, scenario_set: scenario_set, result_json: decoded_result} = context
    import_data = voting_data |> ScoringData.add_scenario_import_data()

    engine_scenarios = ScenarioImport.unique_scenarios(decoded_result)
    {engine_scenario, _} = engine_scenarios |> List.pop_at(0)

    scenario = ScenarioImport.import_scenario(scenario_set, engine_scenario, import_data)
    assert %Scenario{} = scenario

    updated_scenario_set =
      ScenarioImport.add_json_stats(scenario_set, [{engine_scenario, scenario}], import_data)

    {:ok, parsed} = Jason.decode(updated_scenario_set.json_stats)

    option_count = length(import_data.options)
    criteria_count = length(import_data.criterias)
    # two of the test categories have no Options and are not included
    oc_count = 3

    # scenario
    expected_length = option_count * criteria_count + option_count + oc_count + 1

    assert length(parsed) == expected_length
  end

  test "filtering stats" do
    decision = create_decision()

    scenario_stats_json = load_support_file("scenarios/scenario_stats.json")

    {:ok, scenario_set} =
      Scenarios.create_scenario_set(
        %{
          status: "success",
          json_stats: scenario_stats_json
        },
        decision
      )

    scenario_id = 1

    scenario_stats =
      scenario_set
      |> Scenarios.list_scenario_stats(%{
        scenario_id: scenario_id,
        issue_id: nil,
        option_id: nil,
        criteria_id: nil
      })

    assert [%{scenario_id: 1}] = scenario_stats

    criteria_id = 1
    criteria_stats = scenario_set |> Scenarios.list_scenario_stats(%{criteria_id: criteria_id})
    assert [a, b, c, d, e] = criteria_stats
    assert a.criteria_id == criteria_id
    assert b.criteria_id == criteria_id
    assert c.criteria_id == criteria_id
    assert d.criteria_id == criteria_id
    assert e.criteria_id == criteria_id

    option_id = 4

    option_stats =
      scenario_set |> Scenarios.list_scenario_stats(%{option_id: option_id, criteria_id: nil})

    assert [%{option_id: option_id}] = option_stats

    criteria_option_stats =
      scenario_set
      |> Scenarios.list_scenario_stats(%{option_id: option_id, criteria_id: criteria_id})

    assert [f] = criteria_option_stats
    assert f.option_id == option_id
    assert f.criteria_id == criteria_id

    issue_id = 2
    issue_stats = scenario_set |> Scenarios.list_scenario_stats(%{issue_id: issue_id})
    assert [f] = issue_stats
    assert f.issue_id == issue_id
  end

  defp global_scenario(context) do
    [json_scenario | _] = context[:decoded_result]

    imported_scenario =
      Scenario
      |> where(scenario_set_id: ^context.scenario_set.id, global: true)
      |> first
      |> preload([:scenario_set, :scenario_displays, :options])
      |> Repo.one()

    %{json_scenario: json_scenario, imported: imported_scenario}
  end
end
