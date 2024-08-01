defmodule EtheloApi.Graphql.Schemas.ScenarioSetTest do
  @moduledoc """
  Test graphql queries for ScenarioSets
  """
  use EtheloApi.Graphql.SchemaCase
  @moduletag scenario_set: true, graphql: true

  import EtheloApi.Scenarios.Factory
  import EtheloApi.Structure.Factory
  import EtheloApi.Voting.Factory, only: [create_participant: 1]
  import EtheloApi.Scenarios.TestHelper.ScenarioSetHelper
  alias EtheloApi.Scenarios.TestHelper.SolveDumpHelper, as: DumpHelper

  describe "decision => scenarioSets query" do
    test "without filter returns all records" do
      decision = create_decision()
      %{scenario_set: to_match1} = create_scenario_set(decision, %{status: "success"})
      %{scenario_set: to_match2} = create_scenario_set(decision, %{status: "success"})

      assert_list_many_query(
        "scenarioSets",
        decision.id,
        %{},
        [to_match1, to_match2],
        fields()
      )
    end

    test "filters by id" do
      %{scenario_set: to_match, decision: decision} = create_scenario_set()
      %{scenario_set: _excluded} = create_scenario_set(decision)

      assert_list_one_query("scenarioSets", to_match, [:id], fields([:id]))
    end

    test "filters by cached_decision" do
      decision = create_decision()
      %{scenario_set: to_match} = create_scenario_set(decision, %{cached_decision: true})
      %{scenario_set: _excluded} = create_scenario_set(decision, %{cached_decision: false})

      assert_list_one_query(
        "scenarioSets",
        to_match,
        [:cached_decision],
        fields([:cached_decision])
      )
    end

    test "filters by status" do
      decision = create_decision()
      %{scenario_set: to_match} = create_scenario_set(decision, %{status: "pending"})
      %{scenario_set: _excluded} = create_scenario_set(decision, %{status: "error"})

      assert_list_one_query("scenarioSets", to_match, [:status], fields([:status]))
    end

    test "filters by scenario_config_id" do
      %{scenario_set: to_match, decision: decision} = create_scenario_set()
      %{scenario_set: _excluded} = create_scenario_set(decision)

      assert_list_one_query(
        "scenarioSets",
        to_match,
        [:scenario_config_id],
        fields([:scenario_config_id])
      )
    end

    test "filters by participant_id" do
      decision = create_decision()
      %{participant: participant1} = create_participant(decision)
      %{participant: participant2} = create_participant(decision)
      %{scenario_set: to_match} = create_scenario_set(decision, %{participant: participant1})
      %{scenario_set: _excluded} = create_scenario_set(decision, %{participant: participant2})

      assert_list_one_query(
        "scenarioSets",
        to_match,
        [:participant_id],
        fields([:participant_id])
      )
    end

    test "filters by latest" do
      decision = create_decision()

      older =
        DateTime.utc_now()
        |> DateTime.add(-1, :second)
        |> DateTime.truncate(:second)

      %{scenario_set: _excluded} =
        create_scenario_set(decision, %{status: "success", updated_at: older})

      newer = DateTime.utc_now() |> DateTime.truncate(:second)

      %{scenario_set: to_match} =
        create_scenario_set(decision, %{status: "success", updated_at: newer})

      params = %{latest: true}

      query =
        decision_child_query(
          "scenarioSets",
          to_match.decision_id,
          params,
          [:id]
        )

      result_list = evaluate_query_graphql(query, "scenarioSets")
      assert [result] = result_list

      assert_equivalent_graphql(to_match, result, fields([:id]))
    end

    test "no matching records" do
      decision = create_decision()
      assert_list_none_query("scenarioSets", %{decision_id: decision.id}, [:id])
    end

    test "inline records without participant" do
      decision = create_decision()
      %{participant: participant1} = create_participant(decision)

      %{scenario_set: _excluded} =
        create_scenario_set(decision, %{status: "success", participant_id: participant1.id})

      scenario_stats_json = ~s|
      [{ "total_votes": 2,  "ethelo": -0.197265625}]
      |

      %{scenario_set: scenario_set1, scenario_config: scenario_config1} =
        create_scenario_set(decision, %{status: "success", json_stats: scenario_stats_json})

      %{scenario: scenario} = create_scenario(scenario_set1, %{status: "success"})

      %{scenario_set: scenario_set2, scenario_config: scenario_config2} =
        create_scenario_set(decision, %{status: "success"})

      solve_dump = create_solve_dump_without_deps(decision, %{scenario_set: scenario_set2})

      query = ~s|
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            scenarioSets{
              id
              scenarios {
                id
              }
              scenarioConfig{
                id
              }
              participant{
                id
              }
              solveDump{
                id
              }
              scenarioStats {
                totalVotes
              }
            }
          }
        }

      |

      result_list = evaluate_query_graphql(query, "scenarioSets")

      expected = [
        %{
          "id" => "#{scenario_set2.id}",
          "participant" => nil,
          "scenarios" => [],
          "scenarioStats" => [],
          "scenarioConfig" => %{"id" => "#{scenario_config2.id}"},
          "solveDump" => %{"id" => "#{solve_dump.id}"}
        },
        %{
          "id" => "#{scenario_set1.id}",
          "scenarios" => [%{"id" => "#{scenario.id}"}],
          "scenarioStats" => [%{"totalVotes" => 2}],
          "participant" => nil,
          "scenarioConfig" => %{"id" => "#{scenario_config1.id}"},
          "solveDump" => nil
        }
      ]

      assert expected == result_list
    end

    test "inline Participant" do
      decision = create_decision()
      %{participant: participant1} = create_participant(decision)

      %{scenario_set: scenario_set} =
        create_scenario_set(decision, %{status: "success", participant_id: participant1.id})

      %{participant: participant2} = create_participant(decision)

      %{scenario_set: _excluded} =
        create_scenario_set(decision, %{status: "success", participant_id: participant2.id})

      %{scenario_set: _excluded} = create_scenario_set(decision, %{status: "success"})

      query = ~s|
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            scenarioSets(
              participant_id: #{participant1.id}
            ){
              id

              participant{
                id
              }

            }
          }
        }
      |

      result_list = evaluate_query_graphql(query, "scenarioSets")

      expected = [
        %{
          "id" => "#{scenario_set.id}",
          "participant" => %{"id" => "#{participant1.id}"}
        }
      ]

      assert expected == result_list
    end

    test "inline SolveDump" do
      decision = create_decision()

      %{scenario_set: scenario_set} =
        create_scenario_set(decision, %{status: "success"})

      solve_dump = create_solve_dump_without_deps(decision, %{scenario_set: scenario_set})

      requested_fields = DumpHelper.fields() |> Map.keys() |> simple_fields()

      query = ~s|
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            scenarioSets{
              solveDump{
                #{requested_fields}
              }

            }
          }
        }
      |

      result_list = evaluate_query_graphql(query, "scenarioSets")

      [scenario_set] = result_list
      result_solve_dump = Map.get(scenario_set, "solveDump")

      assert_equivalent_graphql(solve_dump, result_solve_dump, DumpHelper.fields())
    end
  end
end
