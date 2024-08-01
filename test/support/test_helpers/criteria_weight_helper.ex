defmodule EtheloApi.Voting.TestHelper.CriteriaWeightHelper do
  @moduledoc false

  import ExUnit.Assertions
  import EtheloApi.Structure.TestHelper.VotingHelper
  import EtheloApi.Voting.Factory

  def create_pair() do
    %{criteria_weight: criteria_weight1, decision: decision} = create_criteria_weight()
    %{criteria_weight: criteria_weight2} = create_criteria_weight(decision)
    [criteria_weight1, criteria_weight2]
  end

  def assert_equivalent(expected, result) do
    assert expected.participant_id == result.participant_id
    assert expected.criteria_id == result.criteria_id
    assert expected.weighting == result.weighting
  end

  def empty_attrs() do
    %{
      weighting: nil,
      criteria_id: nil, participant_id: nil
    }
  end

  def invalid_attrs(deps \\ %{}) do
     %{
       weighting: "max",
       criteria_id: 400,  participant_id: 400,
     }
     |> add_criteria_weight_id(deps)
     |> add_participant_id(deps)
     |> add_criteria_id(deps)
     |> add_decision_id(deps)
  end

  def valid_attrs(deps) do
    %{
      weighting: 35,
      criteria_id: nil, participant_id: nil,
    }
    |> add_criteria_weight_id(deps)
    |> add_participant_id(deps)
    |> add_criteria_id(deps)
    |> add_decision_id(deps)
  end

  def add_criteria_weight_id(attrs, %{criteria_weight: criteria_weight}), do: Map.put(attrs, :id, criteria_weight.id)
  def add_criteria_weight_id(attrs, _deps), do: attrs

end
