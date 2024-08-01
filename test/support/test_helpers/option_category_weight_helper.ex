defmodule EtheloApi.Voting.TestHelper.OptionCategoryWeightHelper do
  @moduledoc false

  import ExUnit.Assertions
  import EtheloApi.Structure.TestHelper.VotingHelper
  import EtheloApi.Voting.Factory

  def create_pair() do
    %{option_category_weight: option_category_weight1, decision: decision} = create_option_category_weight()
    %{option_category_weight: option_category_weight2} = create_option_category_weight(decision)
    [option_category_weight1, option_category_weight2]
  end

  def assert_equivalent(expected, result) do
    assert expected.participant_id == result.participant_id
    assert expected.option_category_id == result.option_category_id
    assert expected.weighting == result.weighting
  end

  def empty_attrs() do
    %{
      weighting: nil,
      option_category_id: nil, participant_id: nil
    }
  end

  def invalid_attrs(deps \\ %{}) do
     %{
       weighting: "max",
       option_category_id: 400,  participant_id: 400,
     }
     |> add_option_category_weight_id(deps)
     |> add_participant_id(deps)
     |> add_option_category_id(deps)
     |> add_decision_id(deps)
  end

  def valid_attrs(deps) do
    %{
      weighting: 35,
      option_category_id: nil, participant_id: nil,
    }
    |> add_option_category_weight_id(deps)
    |> add_participant_id(deps)
    |> add_option_category_id(deps)
    |> add_decision_id(deps)
  end

  def add_option_category_weight_id(attrs, %{option_category_weight: option_category_weight}), do: Map.put(attrs, :id, option_category_weight.id)
  def add_option_category_weight_id(attrs, _deps), do: attrs

end
