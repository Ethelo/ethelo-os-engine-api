defmodule EtheloApi.Voting.TestHelper.OptionCategoryBinVoteHelper do
  @moduledoc false

  import ExUnit.Assertions
  import EtheloApi.Structure.TestHelper.VotingHelper
  import EtheloApi.Voting.Factory

  def create_pair() do
    %{option_category_bin_vote: option_category_bin_vote1, decision: decision} = create_option_category_bin_vote()
    %{option_category_bin_vote: option_category_bin_vote2} = create_option_category_bin_vote(decision)
    [option_category_bin_vote1, option_category_bin_vote2]
  end

  def assert_equivalent(expected, result) do
    assert expected.participant_id == result.participant_id
    assert expected.criteria_id == result.criteria_id
    assert expected.option_category_id == result.option_category_id
    assert expected.bin == result.bin
  end

  def empty_attrs() do
    %{
      bin: nil,
      option_category_id: nil, criteria_id: nil, participant_id: nil
    }
  end

  def invalid_attrs(deps \\ %{}) do
     %{
       bin: -29.4,
       option_category_id: 400, criteria_id: 400, participant_id: 400,
     }
     |> add_option_category_bin_vote_id(deps)
     |> add_participant_id(deps)
     |> add_criteria_id(deps)
     |> add_option_category_id(deps)
     |> add_decision_id(deps)
  end

  def valid_attrs(deps) do
    %{
      bin: 3,
      option_category_id: nil, criteria_id: nil, participant_id: nil,
    }
    |> add_option_category_bin_vote_id(deps)
    |> add_participant_id(deps)
    |> add_criteria_id(deps)
    |> add_option_category_id(deps)
    |> add_decision_id(deps)
  end

  def add_option_category_bin_vote_id(attrs, %{option_category_bin_vote: option_category_bin_vote}), do: Map.put(attrs, :id, option_category_bin_vote.id)
  def add_option_category_bin_vote_id(attrs, _deps), do: attrs

end
