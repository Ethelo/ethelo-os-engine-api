defmodule EtheloApi.Scenarios.TestHelper.ScenarioSetHelper do
  @moduledoc """
  ScenarioSet specific test tools
  """

  import EtheloApi.TestHelper.GenericHelper
  import ExUnit.Assertions

  def fields() do
    %{
      cached_decision: :boolean,
      engine_end: :date,
      engine_start: :date,
      error: :string,
      hash: :string,
      id: :string,
      inserted_at: :date,
      participant_id: :string,
      scenario_config_id: :string,
      status: :string,
      updated_at: :date
    }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  def json_stats() do
    ~s(
    [{
    "total_votes": 3,
    "support": 0.5,
    "scenario_set_id": 1,
    "positive_votes": 4,
    "option_id": 2,
    "neutral_votes": 0,
    "negative_votes": 0,
    "histogram": [0, 0, 0, 2, 2],
    "ethelo": 0.5,
    "dissonance": 0.25,
    "default": true,
    "decision_id": 1,
    "approval": 0.6666666666666666,
    "advanced_stats": [0,0],
    "abstain_votes": 0
    }]
  )
  end

  def empty_attrs() do
    %{
      cached_decision: nil,
      engine_end: nil,
      engine_start: nil,
      error: nil,
      hash: nil,
      json_stats: nil,
      status: nil,
      updated_at: nil
    }
  end

  def invalid_attrs(%{} = deps \\ %{}) do
    %{
      cached_decision: "foo",
      engine_end: 434,
      engine_start: 443,
      error: %{},
      hash: false,
      json_stats: 434,
      participant_id: "moo",
      scenario_config_id: "bar",
      status: true,
      updated_at: true
    }
    |> add_scenario_config_id(deps)
    |> add_participant_id(deps)
    |> add_decision_id(deps)
    |> add_record_id(deps)
  end

  def valid_attrs(%{} = deps \\ %{}) do
    %{
      cached_decision: true,
      engine_end: offset_date_value(-4000),
      engine_start: offset_date_value(-13_000),
      error: "no votes",
      hash: "foo bar",
      json_stats: json_stats(),
      participant_id: nil,
      scenario_config_id: nil,
      status: "success",
      updated_at: offset_date_value(-1000)
    }
    |> add_scenario_config_id(deps)
    |> add_participant_id(deps)
    |> add_decision_id(deps)
    |> add_record_id(deps)
  end

  def assert_equivalent(expected, result) do
    assert expected.cached_decision == result.cached_decision
    assert expected.decision_id == result.decision_id
    assert expected.engine_end == result.engine_end
    assert expected.engine_start == result.engine_start
    assert expected.error == result.error
    assert expected.participant_id == result.participant_id
    assert expected.scenario_config_id == result.scenario_config_id
    assert expected.status == result.status
  end

  def add_record_id(attrs, %{scenario_set: scenario_set}),
    do: Map.put(attrs, :id, scenario_set.id)

  def add_record_id(attrs, _deps), do: attrs
end
