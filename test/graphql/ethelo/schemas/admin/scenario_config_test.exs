defmodule GraphQL.EtheloApi.AdminSchema.ScenarioConfigTest do
  @moduledoc """
  Test graphql queries for decisions
  """
  use GraphQL.EtheloApi.AdminSchemaCase
  @moduletag scenario_config: true, graphql: true

  alias Engine.Scenarios
  alias Engine.Scenarios.ScenarioConfig
  alias Kronky.ValidationMessage
  import EtheloApi.Structure.Factory
  import Engine.Scenarios.Factory

  def fields() do
    %{
    id: :string, title: :string, slug: :string,
    bins: :integer, support_only: :boolean,
    per_option_satisfaction: :boolean,
    normalize_satisfaction: :boolean,
    normalize_influents: :boolean,
    max_scenarios: :integer, collective_identity: :decimal,
    ttl: :integer, engine_timeout: :integer, skip_solver: :boolean,
    tipping_point: :decimal, enabled: :boolean,
    updated_at: :date, inserted_at: :date,
    override_criteria_weights: :boolean,
    override_option_category_weights: :boolean,
    quadratic: :boolean, quad_user_seeds: :integer,
    quad_total_available: :integer, quad_cutoff: :integer,
    quad_max_allocation: :integer, quad_round_to: :integer,
    quad_seed_percent: :decimal, quad_vote_percent: :decimal,
   }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  defp rename_ci(%{ci: ci} = attrs) do
    Map.put(attrs, :collective_identity, ci)
  end
  defp rename_ci(%{} = attrs), do: attrs

  describe "decision => scenario_configs query " do
    test "no filter" do
      %{scenario_config: first, decision: decision} = create_scenario_config()
      %{scenario_config: second} = create_scenario_config(decision)
      first = first |> rename_ci()
      second = second |> rename_ci()

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            scenarioConfigs{
              id
              title
              slug
              bins
              ttl
              engineTimeout
              skipSolver
              overrideCriteriaWeights
              overrideOptionCategoryWeights
              supportOnly
              quadratic
              quadUserSeeds
              quadTotalAvailable
              quadCutoff
              quadRoundTo
              quadSeedPercent
              quadVotePercent
              quadMaxAllocation
              perOptionSatisfaction
              maxScenarios
              normalizeInfluents
              normalizeSatisfaction
              collectiveIdentity
              tippingPoint
              enabled
              updatedAt
              insertedAt
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "scenarioConfigs"])
      assert [_, _] = result
      [first_result, second_result] = result |> Enum.sort_by(&(Map.get(&1, "id")))

      assert_equivalent_graphql(first, first_result, fields())
      assert_equivalent_graphql(second, second_result, fields())
    end

    test "filter by id" do
      %{scenario_config: existing, decision: decision} = create_scenario_config()

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            scenarioConfigs(
              id: #{existing.id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "scenarioConfigs"])
      assert [%{"id" => id}] = result
      assert to_string(existing.id) == id
    end

    test "filter by slug" do
      %{scenario_config: existing, decision: decision} = create_scenario_config()

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            scenarioConfigs(
              slug: "#{existing.slug}"
            ){
              slug
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "scenarioConfigs"])
      assert [%{"slug" => slug}] = result
      assert to_string(existing.slug) == slug
    end

    test "no matches" do
      decision = create_decision()

      query = """
        {
          decision(
            decisionId: "#{decision.id}"
          )
          {
            scenarioConfigs{
              slug
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "scenarioConfigs"])
      assert [] = result
    end
  end

  describe "createScenarioConfig mutation" do

    test "succeeds" do
      %{decision: decision} = scenario_config_deps()
      input = %{
         slug: "moo",
         title: "Moogle",
         bins: 5,
         skip_solver: true,
         engine_timeout: 5*1000,
         normalize_satisfaction: true,
         normalize_influents: false,
         support_only: true,
         quadratic: false,
         per_option_satisfaction: false,
         max_scenarios: 8,
         collective_identity: 0.1,
         tipping_point: 0.5,
         ttl: 60*60,
         enabled: true,
         decision_id: decision.id,
      }

      query = """
        mutation{
          createScenarioConfig(
            input: {
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
              bins: #{input.bins}
              ttl: #{input.ttl}
              engineTimeout: #{input.engine_timeout}
              normalizeSatisfaction: #{input.normalize_satisfaction}
              normalizeInfluents: #{input.normalize_influents}
              skipSolver: #{input.skip_solver}
              supportOnly: #{input.support_only}
              quadratic: #{input.quadratic}
              perOptionSatisfaction: #{input.per_option_satisfaction}
              maxScenarios: #{input.max_scenarios}
              collectiveIdentity: #{input.collective_identity}
              tippingPoint: #{input.tipping_point}
              enabled: #{input.enabled}
            }
          )
          {
            successful
            result {
              id
              title
              slug
              bins
              ttl
              engineTimeout
              skipSolver
              normalizeSatisfaction
              normalizeInfluents
              supportOnly
              quadratic
              perOptionSatisfaction
              maxScenarios
              collectiveIdentity
              tippingPoint
              enabled
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"createScenarioConfig" => payload} = data
      fields = fields() |> Map.drop([:id])
      assert_mutation_success(input, payload, fields)
      assert %ScenarioConfig{} = Scenarios.get_scenario_config(payload["result"]["id"], decision)
    end

    test "failure" do
      %{decision: decision} = scenario_config_deps()
      input = %{
        title: "-", slug: "A",
        decision_id: decision.id,
      }

      query = """
        mutation{
          createScenarioConfig(
            input: {
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
            }
          ){
            successful
            messages {
              field
              message
              code
            }
            result {
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"createScenarioConfig" => payload} = data
      expected = [
        %ValidationMessage{code: :format, field: :title, message: "must include at least one word"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end

    test "decision not found" do
      %{decision: decision} = scenario_config_deps()
      delete_decision(decision)
      input = %{
        title: "-", slug: "A",
        decision_id: decision.id,
      }

      query = """
        mutation{
          createScenarioConfig(
            input: {
              decisionId: #{input.decision_id}
              title: "#{input.title}"
            }
          ){
            successful
            messages {
              field
              message
              code
            }
            result {
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"createScenarioConfig" => payload} = data
      expected = [
        %ValidationMessage{code: :not_found, field: :decisionId, message: "does not exist"}
      ]
      assert_mutation_failure(expected, payload, [:field, :message, :code])
    end
  end

  describe "updateScenarioConfig mutation" do

    test "succeeds" do
      %{decision: decision, scenario_config: existing} = create_scenario_config()
      input = %{
        slug: "moo",
        title: "Moogle",
        bins: 5,
        skip_solver: true,
        support_only: true,
        per_option_satisfaction: false,
        max_scenarios: 8,
        normalize_satisfaction: false,
        normalize_influents: false,
        collective_identity: 0.1,
        tipping_point: 0.5,
        enabled: true,
        ttl: 60*60*2,
        engine_timeout: 5*1000,
        decision_id: decision.id,
        id: existing.id,
        quadratic: true,
        quad_user_seeds: 121,
        quad_total_available: 581000,
        quad_max_allocation: 51000,
        quad_cutoff: 7000,
        quad_round_to: 4000,
        quad_seed_percent: 0.70,
        quad_vote_percent: 0.30,

      }
      query = """
        mutation{
          updateScenarioConfig(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
              bins: #{input.bins}
              ttl: #{input.ttl}
              engineTimeout: #{input.engine_timeout}
              normalizeSatisfaction: #{input.normalize_satisfaction}
              normalizeInfluents: #{input.normalize_influents}
              skipSolver: #{input.skip_solver}
              supportOnly: #{input.support_only}
              quadratic: #{input.quadratic}
              perOptionSatisfaction: #{input.per_option_satisfaction}
              maxScenarios: #{input.max_scenarios}
              collectiveIdentity: #{input.collective_identity}
              tippingPoint: #{input.tipping_point}
              enabled: #{input.enabled}
              quadUserSeeds: #{input.quad_user_seeds}
              quadTotalAvailable: #{input.quad_total_available}
              quadCutoff: #{input.quad_cutoff}
              quadRoundTo: #{input.quad_round_to}
              quadMaxAllocation: #{input.quad_max_allocation}
              quadSeedPercent: #{input.quad_seed_percent}
              quadVotePercent: #{input.quad_vote_percent}
            }
          )
          {
            successful
            result {
              id
              id
              title
              slug
              bins
              ttl
              engineTimeout
              skipSolver
              normalizeSatisfaction
              normalizeInfluents
              supportOnly
              quadratic
              perOptionSatisfaction
              maxScenarios
              collectiveIdentity
              tippingPoint
              enabled
              quadUserSeeds
              quadTotalAvailable
              quadCutoff
              quadRoundTo
              quadMaxAllocation
              quadSeedPercent
              quadVotePercent
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"updateScenarioConfig" => payload} = data
      assert_mutation_success(input, payload, fields())
      assert %ScenarioConfig{} = Scenarios.get_scenario_config(payload["result"]["id"], decision)
    end

    test "failure" do
      %{decision: decision, scenario_config: existing} = create_scenario_config()
      input = %{
        title: "-", slug: "A",
        decision_id: decision.id,
        id: existing.id
      }

      query = """
        mutation{
          updateScenarioConfig(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
            }
          ){
            successful
            messages {
              field
              message
              code
            }
            result {
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"updateScenarioConfig" => payload} = data
      expected = %ValidationMessage{
        code: :format, field: :title, message: "must include at least one word"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end

    test "scenario_config not found" do
      %{scenario_config: existing} = create_scenario_config()
      decision = create_decision()
      delete_scenario_config(existing)

      input = %{
        title: "-", slug: "A",
        decision_id: decision.id, id: existing.id
      }

      query = """
        mutation{
          updateScenarioConfig(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
              title: "#{input.title}"
            }
          ){
            successful
            messages {
              field
              message
              code
            }
            result {
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"updateScenarioConfig" => payload} = data
      expected = %ValidationMessage{
        code: "not_found", field: :id, message: "does not exist"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end
  end

  describe "deleteScenarioConfig mutation" do
    test "succeeds" do
      %{decision: decision, scenario_config: first} = create_scenario_config()
      %{scenario_config: _second} = create_scenario_config(decision)

      input = %{id: first.id, decision_id: decision.id}

      query = """
        mutation{
          deleteScenarioConfig(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
            }
          ){
            successful
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"deleteScenarioConfig" => %{"successful" => true}} = data
      assert nil == Scenarios.get_scenario_config(first.id, decision)
    end

    test "failure" do
      %{decision: decision, scenario_config: only} = create_scenario_config()

      input = %{id: only.id, decision_id: decision.id}

      query = """
        mutation{
          deleteScenarioConfig(
            input: {
              id: #{input.id}
              decisionId: #{input.decision_id}
            }
          ){
            successful
            messages {
              field
              message
              code
            }
            result {
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"deleteScenarioConfig" => payload} = data
      expected = %ValidationMessage{
        code: "protected_record", field: :id, message: "cannot be deleted"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
      refute nil == Scenarios.get_scenario_config(only.id, decision)
    end
  end

end
