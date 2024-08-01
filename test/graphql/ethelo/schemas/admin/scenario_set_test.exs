defmodule GraphQL.EtheloApi.AdminSchema.ScenarioSetTest do
  @moduledoc """
  Test graphql queries for decisions
  """
  use GraphQL.EtheloApi.AdminSchemaCase
  @moduletag option: true, graphql: true

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

  describe "decision => scenarioSets query " do
    test "no filter" do
      decision = create_decision()
      %{scenario_set: first} = create_scenario_set(decision, %{status: "success"})
      create_solve_dump_without_deps(decision, %{scenario_set: first})

      %{scenario_set: second} = create_scenario_set(decision, %{status: "success"})

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            scenarioSets{
              id
              engineStart
              engineEnd
              updatedAt
              insertedAt
              solveDump {
                id
              }
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "scenarioSets"])
      assert [second_result, first_result] = result

      assert_equivalent_graphql(first, first_result, fields())
      assert_equivalent_graphql(second, second_result, fields())
    end

    test "filter by id" do
      decision = create_decision()
      %{scenario_set: matching} = create_scenario_set(decision, %{status: "success"})
      create_scenario_set(decision, %{status: "success"})

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            scenarioSets(
              id: #{matching.id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "scenarioSets"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end
  end
end
