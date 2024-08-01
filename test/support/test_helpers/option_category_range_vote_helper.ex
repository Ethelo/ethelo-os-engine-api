defmodule EtheloApi.Voting.TestHelper.OptionCategoryRangeVoteHelper do
  @moduledoc false

  import ExUnit.Assertions
  import EtheloApi.Structure.TestHelper.VotingHelper
  import EtheloApi.Voting.Factory

  def empty_attrs() do
    %{
      participant_id: nil, option_category_id: nil,
      low_option_id: nil, high_option_id: nil,
    }
  end

  def invalid_attrs(deps \\ %{}) do
     %{
       participant_id: 30, option_category_id: 302,
       low_option_id: 1499,  high_option_id: 1498,
     }
     |> add_option_category_id(deps)
     |> add_participant_id(deps)
     |> add_high_option_id(deps)
     |> add_low_option_id(deps)
     |> add_decision_id(deps)
  end

  def create_pair() do
    %{option_category_range_vote: option_category_range_vote1, decision: decision} = create_option_category_range_vote()
    %{option_category_range_vote: option_category_range_vote2} = create_option_category_range_vote(decision)
    [option_category_range_vote1, option_category_range_vote2]
  end

  def assert_equivalent(expected, result) do
    assert expected.participant_id == result.participant_id
    assert expected.low_option_id == result.low_option_id
    assert expected.high_option_id == result.high_option_id
    assert expected.option_category_id == result.option_category_id
  end

  def valid_attrs(deps \\ %{}) do
     %{
       participant_id: nil, option_category_id: nil,
       low_option_id: nil,  high_option_id: nil,
     }
     |> add_option_category_id(deps)
     |> add_participant_id(deps)
     |> add_high_option_id(deps)
     |> add_low_option_id(deps)
     |> add_decision_id(deps)
  end

  def add_low_option_id(attrs, %{low_option: low_option}), do: Map.put(attrs, :low_option_id, low_option.id)
  def add_low_option_id(attrs, _deps), do: attrs

  def add_high_option_id(attrs, %{high_option: high_option}), do: Map.put(attrs, :high_option_id, high_option.id)
  def add_high_option_id(attrs, _deps), do: attrs

end
