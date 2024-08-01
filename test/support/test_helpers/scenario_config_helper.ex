defmodule EtheloApi.Structure.TestHelper.ScenarioConfigHelper do
  @moduledoc false

  import EtheloApi.Structure.TestHelper.GenericHelper
  import ExUnit.Assertions
  alias EtheloApi.Structure.Decision

  def empty_attrs() do
    %{
      slug: nil, title: nil,
      bins: nil, support_only: nil, quadratic: nil,
      normalize_influents: nil, normalize_satisfaction: nil,
      max_scenarios: nil, ci: nil, tipping_point: nil,
      enabled: nil, skip_solver: nil, ttl: nil, engine_timeout: nil,
      quad_user_seeds: nil, quad_total_available: nil, quad_cutoff: nil,
      quad_round_to: nil, quad_max_allocation: nil,
      quad_seed_percent: nil, quad_vote_percent: nil,
    }
  end

  def invalid_attrs() do
    %{
      slug: "  ", title: "@@@",
      bins: "nine", support_only: 7, quadratic: 3,
      normalize_influents: "nope", normalize_satisfaction: "foobared",
      max_scenarios: 3200, ci: 50, tipping_point: 10,
      enabled: "nope", skip_solver: "nope", ttl: 60*60*60*60, engine_timeout: 0,
      quad_user_seeds: "nope", quad_total_available: "nope", quad_cutoff: "nope",
      quad_round_to: "nope", quad_max_allocation: "nope",
      quad_seed_percent: "nope", quad_vote_percent: "nope",
    }
  end

  def invalid_quad(decision \\ nil) do
    %{
      slug: "sample slug", title: "sample title",
      bins: 9, support_only: true, quadratic: true,
      normalize_influents: true, normalize_satisfaction: true,
      max_scenarios: 8, ci: 0.1, tipping_point: 0.5,
      enabled: true, skip_solver: true, ttl: 60*60, engine_timeout: 10*1000,
      quad_user_seeds: 0, quad_total_available: 0, quad_cutoff: 0,
      quad_round_to: 0, quad_max_allocation: nil,
      quad_seed_percent: nil, quad_vote_percent: nil,
    }
     |> add_decision_id(decision)
  end

  def valid_attrs(decision  \\ nil) do
    %{
     slug: "sample slug", title: "sample title",
     bins: 9, support_only: true, quadratic: true,
     normalize_influents: true, normalize_satisfaction: true,
     max_scenarios: 8, ci: 0.1, tipping_point: 0.5,
     enabled: true, skip_solver: true, ttl: 60*60, engine_timeout: 10*1000,
     quad_user_seeds: 121, quad_total_available: 581000, quad_cutoff: 7000,
     quad_round_to: 4000, quad_max_allocation: 51000,
     quad_seed_percent: 0.70, quad_vote_percent: 0.30,
    }
    |> add_decision_id(decision)
  end

  def valid_attrs(decision, scenario_config) do
    decision |> valid_attrs() |> add_scenario_config_id(scenario_config)
  end

  def valid_quad_attrs(decision) do
    %{
       slug: "slug", title: "Title",
       bins: 5, quadratic: true, support_only: true, per_option_satisfaction: false, ttl: 60*60, engine_timeout: 10*1000,
       max_scenarios: 8, ci: 0.1, tipping_point: 0.5,
       enabled: true, normalize_satisfaction: true, normalize_influents: true, skip_solver: true,
       quad_user_seeds: 121, quad_total_available: 581000, quad_cutoff: 7000,
       quad_round_to: 4000, quad_max_allocation: 51000,
       quad_seed_percent: 0.70, quad_vote_percent: 0.30,
     }
     |> add_decision_id(decision)
  end

  def valid_quad_attrs(decision, scenario_config) do
     decision |> valid_quad_attrs()  |> add_scenario_config_id(scenario_config)
  end

  def default_attrs() do
    defaults = %{
      bins: 5, support_only: false, quadratic: false, normalize_influents: false,
      normalize_satisfaction: true, max_scenarios: 10, ci: 0.5,
      tipping_point: 0.33333, enabled: true,
      skip_solver: false, ttl: 3600, engine_timeout: 10*1000
    }
    Map.merge(empty_attrs(), defaults)
  end

  def assert_equivalent(expected, result) do
    assert expected.title == result.title
    assert_equivalent_slug(expected.slug, result.slug)
    assert expected.support_only == result.support_only
    assert expected.bins == result.bins
    assert expected.ttl == result.ttl
    assert expected.engine_timeout == result.engine_timeout
    assert expected.normalize_satisfaction == result.normalize_satisfaction
    assert expected.normalize_influents == result.normalize_influents
    assert expected.skip_solver == result.skip_solver
    assert expected.max_scenarios == result.max_scenarios
    assert Decimal.cmp(Decimal.from_float(expected.ci), result.ci) == :eq
    assert Decimal.cmp(Decimal.from_float(expected.tipping_point), result.tipping_point) == :eq
    assert expected.enabled == result.enabled

    assert expected.quadratic == result.quadratic
    assert expected.quad_seed_percent == result.quad_seed_percent
    assert expected.quad_vote_percent == result.quad_vote_percent
    assert expected.quad_user_seeds == result.quad_user_seeds
    assert expected.quad_total_available == result.quad_total_available
    assert expected.quad_cutoff == result.quad_cutoff
    assert expected.quad_round_to == result.quad_round_to
    assert expected.quad_max_allocation == result.quad_max_allocation

  end

  def assert_invalid_data_errors(errors) do
    assert "must include at least one word" in errors.title
    assert "must have numbers and/or letters" in errors.slug
    assert "is invalid" in errors.bins
    assert "is invalid" in errors.support_only
    assert "is invalid" in errors.normalize_satisfaction
    assert "is invalid" in errors.normalize_influents
    assert "is invalid" in errors.skip_solver
    assert "must be less than or equal to 20" in errors.max_scenarios
    assert "must be less than or equal to 604800" in errors.ttl
    assert "must be greater than or equal to 500" in errors.engine_timeout
    assert "must be less than or equal to 1" in errors.ci
    assert "must be less than or equal to 1" in errors.tipping_point
    assert "is invalid" in errors.enabled

    assert "is invalid" in errors.quadratic
    assert "is invalid" in errors.quad_user_seeds
    assert "is invalid" in errors.quad_total_available
    assert "is invalid" in errors.quad_cutoff
    assert "is invalid" in errors.quad_round_to
    assert "is invalid" in errors.quad_max_allocation
    assert "is invalid" in errors.quad_seed_percent
    assert "is invalid" in errors.quad_vote_percent

    assert [:bins, :ci, :enabled, :engine_timeout, :max_scenarios,
           :normalize_influents, :normalize_satisfaction, :quad_cutoff,
           :quad_max_allocation, :quad_round_to, :quad_seed_percent,
           :quad_total_available, :quad_user_seeds, :quad_vote_percent,
           :quadratic, :skip_solver, :slug, :support_only, :tipping_point,
           :title, :ttl] = Map.keys(errors) #20
  end

  def to_graphql_attrs(attrs) do
    attrs
  end

  def add_decision_id(attrs, %Decision{} = decision), do: Map.put(attrs, :decision_id, decision.id)
  def add_decision_id(attrs, _deps), do: attrs

  def add_scenario_config_id(attrs, %{} = scenario_config), do: Map.put(attrs, :id, scenario_config.id)
  def add_scenario_config_id(attrs, _deps), do: attrs

end
