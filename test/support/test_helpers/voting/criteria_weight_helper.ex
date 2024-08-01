defmodule EtheloApi.Voting.TestHelper.CriteriaWeightHelper do
  @moduledoc """
  CriteriaWeight specific test tools
  """
  import ExUnit.Assertions
  import EtheloApi.Voting.Factory
  import(EtheloApi.TestHelper.GenericHelper)

  def fields() do
    %{
      criteria_id: :string,
      inserted_at: :date,
      participant_id: :string,
      updated_at: :date,
      weighting: :integer
    }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  def input_field_names() do
    [
      :criteria_id,
      :participant_id,
      :weighting
    ]
  end

  def empty_attrs() do
    %{
      criteria_id: nil,
      participant_id: nil,
      weighting: nil
    }
  end

  def invalid_attrs(deps \\ %{}) do
    %{
      criteria_id: 400,
      participant_id: 400,
      weighting: 999
    }
    |> add_record_id(deps)
    |> add_participant_id(deps)
    |> add_criteria_id(deps)
    |> add_decision_id(deps)
  end

  def valid_attrs(deps \\ %{}) do
    %{
      criteria_id: nil,
      participant_id: nil,
      weighting: 35
    }
    |> add_record_id(deps)
    |> add_participant_id(deps)
    |> add_criteria_id(deps)
    |> add_decision_id(deps)
  end

  def create_pair() do
    %{criteria_weight: criteria_weight1, decision: decision} = create_criteria_weight()
    %{criteria_weight: criteria_weight2} = create_criteria_weight(decision)
    [criteria_weight1, criteria_weight2]
  end

  def assert_equivalent(expected, result) do
    assert expected.criteria_id == result.criteria_id
    assert expected.participant_id == result.participant_id
    assert expected.weighting == result.weighting
  end

  def add_record_id(attrs, %{criteria_weight: criteria_weight}),
    do: Map.put(attrs, :id, criteria_weight.id)

  def add_record_id(attrs, _deps), do: attrs
end
