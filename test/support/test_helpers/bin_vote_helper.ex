defmodule EtheloApi.Voting.TestHelper.BinVoteHelper do
  @moduledoc false

  import ExUnit.Assertions
  import EtheloApi.Structure.TestHelper.VotingHelper
  import EtheloApi.Voting.Factory

  def create_pair() do
    %{bin_vote: bin_vote1, decision: decision} = create_bin_vote()
    %{bin_vote: bin_vote2} = create_bin_vote(decision)
    [bin_vote1, bin_vote2]
  end

  def assert_equivalent(expected, result) do
    assert expected.participant_id == result.participant_id
    assert expected.criteria_id == result.criteria_id
    assert expected.option_id == result.option_id
    assert expected.bin == result.bin
  end

  def empty_attrs() do
    %{
      bin: nil,
      option_id: nil, criteria_id: nil, participant_id: nil
    }
  end

  def invalid_attrs(deps \\ %{}) do
     %{
       bin: -29.4,
       option_id: 400, criteria_id: 400, participant_id: 400,
     }
     |> add_bin_vote_id(deps)
     |> add_participant_id(deps)
     |> add_criteria_id(deps)
     |> add_option_id(deps)
     |> add_decision_id(deps)
  end

  def valid_attrs(deps) do
    %{
      bin: 3,
      option_id: nil, criteria_id: nil, participant_id: nil,
    }
    |> add_bin_vote_id(deps)
    |> add_participant_id(deps)
    |> add_criteria_id(deps)
    |> add_option_id(deps)
    |> add_decision_id(deps)
  end

  def add_bin_vote_id(attrs, %{bin_vote: bin_vote}), do: Map.put(attrs, :id, bin_vote.id)
  def add_bin_vote_id(attrs, _deps), do: attrs

end
