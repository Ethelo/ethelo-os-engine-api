defmodule GraphQL.EtheloApi.AdminSchema.ScenarioTest do
  @moduledoc """
  Test graphql queries for decisions
  """
  use GraphQL.EtheloApi.AdminSchemaCase
  @moduletag scenario: true, graphql: true

  import Engine.Scenarios.Factory
  import EtheloApi.Structure.Factory

  def fields() do
    %{
      id: :string,
      updated_at: :date, inserted_at: :date,
    }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  describe "decision => scenarios query " do
    test "no filter" do
      decision = create_decision()
      %{option: option1} = create_option(decision)
      %{option: option2} = create_option(decision)
      %{scenario_set: scenario_set} = create_scenario_set(decision, %{status: "success"})
      %{scenario: first} = create_scenario(scenario_set, %{status: "success", options: [option1]})
      %{scenario: second} = create_scenario(scenario_set, %{status: "success", options: [option2]})

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            scenarioSets(id: #{scenario_set.id}){
              scenarios{
                id
                updatedAt
                insertedAt
              }
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "scenarioSets"]) |> List.first
            |> get_in(["scenarios"])
      [second_result, first_result] = result

      assert_equivalent_graphql(first, first_result, fields())
      assert_equivalent_graphql(second, second_result, fields())
    end

    test "filter by id" do
      decision = create_decision()
      %{scenario_set: scenario_set} = create_scenario_set(decision, %{status: "success"})
      %{scenario: matching} = create_scenario(scenario_set, %{status: "success"})
      %{scenario: _not_matching} = create_scenario(scenario_set, %{status: "success"})

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            scenarioSets(
              id: #{scenario_set.id}
            ){
              scenarios(
                id: #{matching.id}
              ){
                id
              }
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "scenarioSets"]) |> List.first
            |> get_in(["scenarios"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end

    test "related records" do
      decision = create_decision()
      scenario_id = 389
      scenario_stats_json = "
      [{ \"issue_id\": 2,  \"ethelo\": -0.197265625}, {\"scenario_id\": #{scenario_id},  \"ethelo\": 0.23776584201388892}]
      "

      %{scenario_set: scenario_set} = create_scenario_set(decision, %{status: "success", json_stats: scenario_stats_json})
      %{scenario: scenario} = create_scenario(scenario_set, %{status: "success", id: scenario_id})

      %{calculation: calculation} = create_calculation(decision)
      %{constraint: constraint} = create_variable_constraint(decision)

      _scenario_display = create_scenario_display_without_deps(decision, %{
          scenario: scenario, is_constraint: false, calculation: calculation,
        })

      _scenario_display = create_scenario_display_without_deps(decision, %{
          scenario: scenario, is_constraint: true, constraint: constraint,
        })

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            scenarioSets(
              id: #{scenario_set.id}
            ){
              scenarioStats{
                ethelo
              }
              scenarios(
                id: #{scenario.id}
              ){
                id
                displays {
                  value
                }
                stats {
                  ethelo
                }
              }
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      scenario = get_in(data, ["decision", "scenarioSets"]) |> List.first
            |> get_in(["scenarios"]) |> List.first
      assert [_|_] = scenario["displays"]
      assert %{"ethelo" => _} = scenario["stats"]

      scenario_set_stats = get_in(data, ["decision", "scenarioSets"]) |> List.first
            |> get_in(["scenarioStats"])
      assert [_ | _] = scenario_set_stats

    end
  end
end
