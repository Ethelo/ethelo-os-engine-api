defmodule EtheloApi.Structure.TestHelper.ScenarioConfigHelper do
  @moduledoc """

  ScenarioConfig specific test tools
  """

  import EtheloApi.TestHelper.GenericHelper
  import ExUnit.Assertions

  def fields() do
    %{
      bins: :integer,
      # decimals not supported
      collective_identity: :float,
      enabled: :boolean,
      engine_timeout: :integer,
      id: :string,
      inserted_at: :date,
      max_scenarios: :integer,
      normalize_influents: :boolean,
      normalize_satisfaction: :boolean,
      per_option_satisfaction: :boolean,
      quad_cutoff: :integer,
      quad_max_allocation: :integer,
      quad_round_to: :integer,
      quad_seed_percent: :float,
      quad_total_available: :integer,
      quad_user_seeds: :integer,
      quad_vote_percent: :float,
      quadratic: :boolean,
      skip_solver: :boolean,
      slug: :string,
      support_only: :boolean,
      # decimals not supported
      tipping_point: :float,
      title: :string,
      ttl: :integer,
      updated_at: :date
    }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  def input_field_names() do
    [
      :bins,
      :collective_identity,
      :enabled,
      :engine_timeout,
      :max_scenarios,
      :normalize_influents,
      :normalize_satisfaction,
      :per_option_satisfaction,
      :quad_cutoff,
      :quad_max_allocation,
      :quad_round_to,
      :quad_seed_percent,
      :quad_total_available,
      :quad_user_seeds,
      :quad_vote_percent,
      :quadratic,
      :skip_solver,
      :slug,
      :support_only,
      :tipping_point,
      :title,
      :ttl
    ]
  end

  def rename_ci(%{ci: ci} = attrs) do
    Map.put(attrs, :collective_identity, ci)
  end

  def rename_ci(%{} = attrs), do: attrs

  def decimals_to_floats(attrs) do
    attrs = decimal_attr_to_float(attrs, :ci)
    attrs = decimal_attr_to_float(attrs, :collective_identity)
    attrs = decimal_attr_to_float(attrs, :tipping_point)

    attrs
  end

  def empty_attrs() do
    %{
      bins: nil,
      ci: nil,
      enabled: nil,
      engine_timeout: nil,
      max_scenarios: nil,
      normalize_influents: nil,
      normalize_satisfaction: nil,
      quad_cutoff: nil,
      quad_max_allocation: nil,
      quad_round_to: nil,
      quad_seed_percent: nil,
      quad_total_available: nil,
      quad_user_seeds: nil,
      quad_vote_percent: nil,
      quadratic: nil,
      skip_solver: nil,
      slug: nil,
      support_only: nil,
      tipping_point: nil,
      title: nil,
      ttl: nil
    }
  end

  def invalid_attrs(%{} = deps \\ %{}) do
    %{
      bins: "nine",
      ci: 50,
      enabled: "nope",
      engine_timeout: 0,
      max_scenarios: 3200,
      normalize_influents: "nope",
      normalize_satisfaction: "foobared",
      quad_cutoff: "nope",
      quad_max_allocation: "nope",
      quad_round_to: "nope",
      quad_seed_percent: "nope",
      quad_total_available: "nope",
      quad_user_seeds: "nope",
      quad_vote_percent: "nope",
      quadratic: 3,
      skip_solver: "nope",
      slug: "@@@",
      support_only: 7,
      tipping_point: 10,
      title: " ",
      ttl: 60 * 60 * 60 * 60
    }
    |> add_decision_id(deps)
    |> add_record_id(deps)
  end

  def invalid_quad_attrs(%{} = deps \\ %{}) do
    %{
      bins: 9,
      ci: 0.15,
      enabled: true,
      engine_timeout: 10 * 1000,
      max_scenarios: 8,
      normalize_influents: true,
      normalize_satisfaction: true,
      quad_cutoff: 0,
      quad_max_allocation: nil,
      quad_round_to: 0,
      quad_seed_percent: nil,
      quad_total_available: 0,
      quad_user_seeds: 0,
      quad_vote_percent: nil,
      quadratic: true,
      skip_solver: true,
      slug: "foo",
      support_only: true,
      tipping_point: 0.5,
      title: "sample title",
      ttl: 60 * 60
    }
    |> add_decision_id(deps)
    |> add_record_id(deps)
  end

  def valid_attrs(%{} = deps \\ %{}) do
    %{
      bins: 9,
      ci: 0.1,
      enabled: true,
      engine_timeout: 10 * 1000,
      max_scenarios: 8,
      normalize_influents: true,
      normalize_satisfaction: true,
      per_option_satisfaction: true,
      quad_cutoff: 7000,
      quad_max_allocation: 51_000,
      quad_round_to: 4000,
      quad_seed_percent: 0.70,
      quad_total_available: 581_000,
      quad_user_seeds: 121,
      quad_vote_percent: 0.30,
      quadratic: true,
      skip_solver: true,
      slug: "foo",
      support_only: true,
      tipping_point: 0.5,
      title: "sample title",
      ttl: 60 * 60
    }
    |> add_decision_id(deps)
    |> add_record_id(deps)
  end

  def valid_quad_attrs(%{} = deps \\ %{}) do
    %{
      bins: 5,
      ci: 0.1,
      enabled: true,
      engine_timeout: 10 * 1000,
      max_scenarios: 8,
      normalize_influents: true,
      normalize_satisfaction: true,
      per_option_satisfaction: false,
      quad_cutoff: 7000,
      quad_max_allocation: 51_000,
      quad_round_to: 4000,
      quad_seed_percent: 0.70,
      quad_total_available: 581_000,
      quad_user_seeds: 121,
      quad_vote_percent: 0.30,
      quadratic: true,
      skip_solver: true,
      slug: "slug",
      support_only: true,
      tipping_point: 0.5,
      title: "Title",
      ttl: 60 * 60
    }
    |> add_decision_id(deps)
    |> add_record_id(deps)
  end

  def assert_equivalent(expected, result) do
    assert expected.bins == result.bins
    assert_decimal_eq(expected.ci, result.ci)
    assert expected.enabled == result.enabled
    assert expected.engine_timeout == result.engine_timeout
    assert expected.max_scenarios == result.max_scenarios
    assert expected.normalize_influents == result.normalize_influents
    assert expected.normalize_satisfaction == result.normalize_satisfaction
    assert expected.quad_cutoff == result.quad_cutoff
    assert expected.quad_max_allocation == result.quad_max_allocation
    assert expected.quad_round_to == result.quad_round_to
    assert expected.quad_seed_percent == result.quad_seed_percent
    assert expected.quad_total_available == result.quad_total_available
    assert expected.quad_user_seeds == result.quad_user_seeds
    assert expected.quad_vote_percent == result.quad_vote_percent
    assert expected.quadratic == result.quadratic
    assert expected.skip_solver == result.skip_solver
    assert_equivalent_slug(expected.slug, result.slug)
    assert expected.support_only == result.support_only
    assert_decimal_eq(expected.tipping_point, result.tipping_point)
    assert expected.title == result.title
    assert expected.ttl == result.ttl
  end

  def assert_invalid_data_errors(errors) do
    assert "is invalid" in errors.bins
    assert "must be less than or equal to 1" in errors.ci
    assert "is invalid" in errors.enabled
    assert "must be greater than or equal to 500" in errors.engine_timeout
    assert "is invalid" in errors.normalize_influents
    assert "is invalid" in errors.normalize_satisfaction
    assert "must have numbers and/or letters" in errors.slug
    assert "is invalid" in errors.support_only
    assert "is invalid" in errors.skip_solver
    assert "must be less than or equal to 20" in errors.max_scenarios
    assert "can't be blank" in errors.title
    assert "must be less than or equal to 604800" in errors.ttl
    assert "must be less than or equal to 1" in errors.tipping_point
    assert "is invalid" in errors.quad_user_seeds
    assert "is invalid" in errors.quad_total_available
    assert "is invalid" in errors.quad_cutoff
    assert "is invalid" in errors.quad_round_to
    assert "is invalid" in errors.quad_max_allocation
    assert "is invalid" in errors.quad_seed_percent
    assert "is invalid" in errors.quad_vote_percent
    assert "is invalid" in errors.quadratic

    expected = [
      :bins,
      :ci,
      :enabled,
      :engine_timeout,
      :max_scenarios,
      :normalize_influents,
      :normalize_satisfaction,
      :quad_cutoff,
      :quad_max_allocation,
      :quad_round_to,
      :quad_seed_percent,
      :quad_total_available,
      :quad_user_seeds,
      :quad_vote_percent,
      :quadratic,
      :skip_solver,
      :slug,
      :support_only,
      :tipping_point,
      :title,
      :ttl
    ]

    assert {[], []} = error_diff(expected, Map.keys(errors))
  end

  def add_record_id(attrs, %{scenario_config: scenario_config}),
    do: Map.put(attrs, :id, scenario_config.id)

  def add_record_id(attrs, _deps), do: attrs
end
