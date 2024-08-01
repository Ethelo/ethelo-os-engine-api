defmodule EtheloApi.Scenarios.TestHelper.ScenarioHelper do
  @moduledoc """
  Scenario specific test tools
  """

  import EtheloApi.TestHelper.GenericHelper
  import ExUnit.Assertions

  def fields() do
    %{
      updated_at: :date,
      tipping_point: :float,
      status: :string,
      minimize: :boolean,
      inserted_at: :date,
      id: :string,
      global: :boolean,
      collective_identity: :float
    }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  def decimals_to_floats(attrs) do
    attrs = decimal_attr_to_float(attrs, :collective_identity)
    attrs = decimal_attr_to_float(attrs, :tipping_point)
    attrs
  end

  def empty_attrs() do
    %{
      collective_identity: nil,
      global: nil,
      minimize: nil,
      status: nil,
      tipping_point: nil
    }
  end

  def invalid_attrs(%{} = deps \\ %{}) do
    %{
      collective_identity: "e",
      global: "",
      minimize: "",
      status: "",
      tipping_point: ""
    }
    |> add_record_id(deps)
    |> add_scenario_set_id(deps)
    |> add_decision_id(deps)
  end

  def valid_attrs(%{} = deps \\ %{}) do
    %{
      collective_identity: 0.0,
      global: false,
      minimize: false,
      status: "pending",
      tipping_point: 0.44
    }
    |> add_record_id(deps)
    |> add_scenario_set_id(deps)
    |> add_decision_id(deps)
  end

  def assert_equivalent(expected, result) do
    assert expected.collective_identity == result.collective_identity
    assert expected.minimize == result.minimize
    assert expected.status == result.status
    assert expected.tipping_point == result.tipping_point
  end

  def add_record_id(attrs, %{scenario: scenario}),
    do: Map.put(attrs, :id, scenario.id)

  def add_record_id(attrs, _deps), do: attrs
end
