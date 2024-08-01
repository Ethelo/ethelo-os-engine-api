defmodule EtheloApi.Graphql.Schemas.ScenarioTest do
  @moduledoc """
  Test graphql queries for Scenarios
  """
  use EtheloApi.Graphql.SchemaCase
  @moduletag scenario: true, graphql: true

  import EtheloApi.Scenarios.Factory
  import EtheloApi.Structure.Factory
  import EtheloApi.Graphql.QueryHelper

  import EtheloApi.Scenarios.TestHelper.ScenarioHelper
  alias EtheloApi.Scenarios.TestHelper.ScenarioStatsHelper, as: StatsHelper

  def create_scenario_pair(override1 \\ %{status: "success"}, override2 \\ %{status: "success"}) do
    decision = create_decision()
    %{scenario_set: scenario_set} = deps = create_scenario_set(decision, %{status: "success"})
    %{scenario: to_match1} = create_scenario(scenario_set, override1)
    %{scenario: to_match2} = create_scenario(scenario_set, override2)
    deps |> Map.put(:to_match1, to_match1) |> Map.put(:to_match2, to_match2)
  end

  def scenario_query(deps, requested_fields) do
    %{decision: decision, scenario_set: scenario_set} = deps

    ~s[
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            scenarioSets(id: #{scenario_set.id}){
              scenarios{
                #{requested_fields}
              }
            }
          }
        }
      ]
  end

  def scenario_query(deps, requested_fields, params) do
    %{decision: decision, scenario_set: scenario_set} = deps
    params = to_graphql_params(params)

    ~s[
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            scenarioSets(id: #{scenario_set.id}){
              scenarios(
                #{params}
              ){
                #{requested_fields}
              }
            }
          }
        }
      ]
  end

  def scenario_results(response) do
    {:ok, %{data: data}} = response
    [scenario_set_result] = get_in(data, ["decision", "scenarioSets"])

    result_list = get_in(scenario_set_result, ["scenarios"])

    result_list |> Enum.sort_by(&Map.get(&1, "id"))
  end

  describe "decision => scenarioSets => scenarios query" do
    test "without filter returns all records" do
      %{to_match1: to_match1, to_match2: to_match2} = deps = create_scenario_pair()

      requested_fields = fields() |> Map.keys() |> simple_fields()
      query = scenario_query(deps, requested_fields)

      response = evaluate_graphql(query)

      result_list = scenario_results(response)

      match_list = [to_match1, to_match2]
      assert_equivalent_graphql(match_list, result_list, fields())
    end

    test "filters by id" do
      %{to_match1: to_match, to_match2: _excluded} = deps = create_scenario_pair()

      params = to_match |> Map.take([:id])

      query = scenario_query(deps, "id", params)

      response = evaluate_graphql(query)

      result_list = scenario_results(response)

      assert_equivalent_graphql([to_match], result_list, fields([:id]))
    end

    test "filters by global" do
      %{to_match1: to_match, to_match2: _excluded} =
        deps =
        create_scenario_pair(
          %{global: true, status: "success"},
          %{global: false, status: "success"}
        )

      params = to_match |> Map.take([:global])

      query = scenario_query(deps, "id", params)

      response = evaluate_graphql(query)

      result_list = scenario_results(response)

      assert_equivalent_graphql([to_match], result_list, fields([:id]))
    end

    test "filters by status" do
      %{to_match1: to_match, to_match2: _excluded} =
        deps = create_scenario_pair(%{status: "success"}, %{status: "error"})

      params = to_match |> Map.take([:status])

      query = scenario_query(deps, "id", params)

      response = evaluate_graphql(query)

      result_list = scenario_results(response)

      assert_equivalent_graphql([to_match], result_list, fields([:id]))
    end

    @tag skip: true
    test "filters by rank" do
      # requires additional setup of json status on scenario sets
      %{to_match1: to_match, to_match2: _excluded} =
        deps = create_scenario_pair()

      params = %{rank: 2}

      query = scenario_query(deps, "id", params)

      response = evaluate_graphql(query)

      result_list = scenario_results(response)

      assert_equivalent_graphql([to_match], result_list, fields([:id]))
    end

    test "applies limit" do
      %{to_match1: _, to_match2: _, scenario_set: scenario_set} =
        deps = create_scenario_pair()

      %{scenario: _excluded} = create_scenario(scenario_set, %{status: "success"})

      params = %{limit: 2}

      query = scenario_query(deps, "id", params)

      response = evaluate_graphql(query)

      result_list = scenario_results(response)

      assert [_, _] = result_list
    end
  end

  describe "scenarios inline records" do
    test "inline Options" do
      decision = create_decision()

      %{scenario: scenario, scenario_set: scenario_set} =
        create_scenario(decision, %{status: "success"})

      %{option: option1} = create_option_on_scenario(scenario, decision)
      %{option: option2} = create_option_on_scenario(scenario, decision)

      query = ~s[
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            scenarioSets(id: #{scenario_set.id}){
              scenarios{
                id
                options {
                  id
                }
              }
            }
          }
        }
      ]

      response = evaluate_graphql(query)

      result_list = scenario_results(response)

      expected = [
        %{
          "id" => "#{scenario.id}",
          "options" => [
            %{"id" => "#{option1.id}"},
            %{"id" => "#{option2.id}"}
          ]
        }
      ]

      assert expected == result_list
    end

    test "inline ScenarioDisplays" do
      decision = create_decision()

      %{scenario: scenario, scenario_set: scenario_set} =
        create_scenario(decision, %{status: "success"})

      %{calculation: calculation} = create_calculation(decision)
      %{constraint: constraint} = create_variable_constraint(decision)

      scenario_display1 =
        create_scenario_display_without_deps(decision, %{
          scenario: scenario,
          is_constraint: false,
          calculation: calculation,
          value: 10.1
        })

      scenario_display2 =
        create_scenario_display_without_deps(decision, %{
          scenario: scenario,
          is_constraint: true,
          constraint: constraint,
          value: 20.1
        })

      query = ~s[
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            scenarioSets(id: #{scenario_set.id}){
              scenarios{
                id
                displays {
                  calculationId
                  constraintId
                  isConstraint
                  value
                }
              }
            }
          }
        }
      ]

      response = evaluate_graphql(query)

      result_list = scenario_results(response)

      expected = [
        %{
          "id" => "#{scenario.id}",
          "displays" => [
            %{
              "calculationId" => "#{scenario_display1.calculation_id}",
              "constraintId" => nil,
              "isConstraint" => scenario_display1.is_constraint,
              "value" => scenario_display1.value
            },
            %{
              "constraintId" => "#{scenario_display2.constraint_id}",
              "calculationId" => nil,
              "isConstraint" => scenario_display2.is_constraint,
              "value" => scenario_display2.value
            }
          ]
        }
      ]

      assert expected == result_list
    end

    test "inline ScenariooStats" do
      decision = create_decision()

      %{scenario_set: scenario_set} =
        deps = create_scenario(decision, %{status: "success"})

      stats = StatsHelper.base_quadratic_stats(deps)
      update_scenario_set_stats(scenario_set.id, [stats])

      requested_fields = stats |> Map.keys() |> simple_fields()

      query = ~s[
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            scenarioSets(id: #{scenario_set.id}){
              scenarios{
                id
                scenarioStats {
                  #{requested_fields}
                }
              }
            }
          }
        }
      ]

      response = evaluate_graphql(query)

      result_list = scenario_results(response)
      [scenario] = result_list
      result_stats = Map.get(scenario, "scenarioStats")

      expected = StatsHelper.decimals_to_floats(stats)

      assert_equivalent_graphql(expected, result_stats, StatsHelper.fields())

      # AbsintheErrorPayload doesn't handle integer lists properly

      assert expected.advanced_stats == Map.get(result_stats, "advancedStats")
      assert expected.histogram == Map.get(result_stats, "histogram")
    end
  end
end
