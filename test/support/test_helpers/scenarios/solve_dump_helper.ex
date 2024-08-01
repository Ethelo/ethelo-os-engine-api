defmodule EtheloApi.Scenarios.TestHelper.SolveDumpHelper do
  @moduledoc """
  SolveDump specific test tools
  """

  import EtheloApi.TestHelper.GenericHelper
  import ExUnit.Assertions

  def fields() do
    %{
      config_json: :string,
      decision_json: :string,
      error: :string,
      id: :string,
      influents_json: :string,
      inserted_at: :date,
      participant_id: :string,
      response_json: :string,
      scenario_set_id: :string,
      updated_at: :date,
      weights_json: :string
    }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  def empty_attrs() do
    %{
      config_json: 32,
      decision_json: 10,
      error: 3_143_123,
      influents_json: 11,
      response_json: 322,
      weights_json: 12
    }
  end

  def invalid_attrs(%{} = deps \\ %{}) do
    %{
      config_json: 32,
      decision_json: 10,
      error: 3_143_123,
      influents_json: 11,
      response_json: 322,
      weights_json: 12
    }
    |> add_record_id(deps)
    |> add_scenario_set_id(deps)
    |> add_decision_id(deps)
    |> add_participant_id(deps)
  end

  def valid_attrs(%{} = deps \\ %{}) do
    %{
      config_json: "{}",
      decision_json: "{}",
      error: nil,
      influents_json: "{}",
      response_json: "{}",
      weights_json: "{}"
    }
    |> add_record_id(deps)
    |> add_scenario_set_id(deps)
    |> add_decision_id(deps)
    |> add_participant_id(deps)
  end

  def assert_equivalent(expected, result) do
    assert expected.config_json == result.config_json
    assert expected.decision_json == result.decision_json
    assert expected.error == result.error
    assert expected.influents_json == result.influents_json
    assert expected.response_json == result.response_json
    assert expected.weights_json == result.weights_json
  end

  def add_record_id(attrs, %{solve_dump: solve_dump}),
    do: Map.put(attrs, :id, solve_dump.id)

  def add_record_id(attrs, _deps), do: attrs
end
