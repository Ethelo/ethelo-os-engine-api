defmodule EtheloApi.Voting.TestHelper.OptionCategoryBinVoteHelper do
  @moduledoc """
  OptionCategoryBinVote specific test tools
  """

  import ExUnit.Assertions
  import EtheloApi.Voting.Factory
  import(EtheloApi.TestHelper.GenericHelper)

  def fields() do
    %{
      bin: :integer,
      criteria_id: :string,
      inserted_at: :date,
      option_category_id: :string,
      participant_id: :string,
      updated_at: :date
    }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  def input_field_names() do
    [
      :bin,
      :criteria_id,
      :option_category_id,
      :participant_id
    ]
  end

  def empty_attrs() do
    %{
      bin: nil,
      criteria_id: nil,
      option_category_id: nil,
      participant_id: nil
    }
  end

  def invalid_attrs(deps \\ %{}) do
    %{
      bin: 20,
      criteria_id: 400,
      option_category_id: 400,
      participant_id: 400
    }
    |> add_record_id(deps)
    |> add_participant_id(deps)
    |> add_criteria_id(deps)
    |> add_option_category_id(deps)
    |> add_decision_id(deps)
  end

  def valid_attrs(deps \\ %{}) do
    %{
      bin: 3,
      criteria_id: nil,
      option_category_id: nil,
      participant_id: nil
    }
    |> add_record_id(deps)
    |> add_participant_id(deps)
    |> add_criteria_id(deps)
    |> add_option_category_id(deps)
    |> add_decision_id(deps)
  end

  def create_pair() do
    %{option_category_bin_vote: option_category_bin_vote1, decision: decision} =
      create_option_category_bin_vote()

    %{option_category_bin_vote: option_category_bin_vote2} =
      create_option_category_bin_vote(decision)

    [option_category_bin_vote1, option_category_bin_vote2]
  end

  def assert_equivalent(expected, result) do
    assert expected.bin == result.bin
    assert expected.criteria_id == result.criteria_id
    assert expected.option_category_id == result.option_category_id
    assert expected.participant_id == result.participant_id
  end

  def add_record_id(attrs, %{option_category_bin_vote: option_category_bin_vote}),
    do: Map.put(attrs, :id, option_category_bin_vote.id)

  def add_record_id(attrs, _deps), do: attrs
end
