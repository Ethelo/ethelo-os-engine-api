defmodule EtheloApi.Voting.TestHelper.OptionCategoryRangeVoteHelper do
  @moduledoc """
  OptionCategoryRangeVote specific test tools
  """
  import ExUnit.Assertions
  import EtheloApi.Voting.Factory
  import(EtheloApi.TestHelper.GenericHelper)

  def fields() do
    %{
      high_option_id: :string,
      inserted_at: :date,
      low_option_id: :string,
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
      :high_option_id,
      :low_option_id,
      :option_category_id,
      :participant_id
    ]
  end

  def empty_attrs() do
    %{
      high_option_id: nil,
      low_option_id: nil,
      option_category_id: nil,
      participant_id: nil
    }
  end

  def invalid_attrs(deps \\ %{}) do
    %{
      high_option_id: 1498,
      low_option_id: 1499,
      option_category_id: 302,
      participant_id: 30
    }
    |> add_record_id(deps)
    |> add_option_category_id(deps)
    |> add_participant_id(deps)
    |> add_high_option_id(deps)
    |> add_low_option_id(deps)
    |> add_decision_id(deps)
  end

  def valid_attrs(deps \\ %{}) do
    %{
      high_option_id: nil,
      low_option_id: nil,
      option_category_id: nil,
      participant_id: nil
    }
    |> add_record_id(deps)
    |> add_option_category_id(deps)
    |> add_participant_id(deps)
    |> add_high_option_id(deps)
    |> add_low_option_id(deps)
    |> add_decision_id(deps)
  end

  def create_pair() do
    %{option_category_range_vote: option_category_range_vote1, decision: decision} =
      create_option_category_range_vote()

    %{option_category_range_vote: option_category_range_vote2} =
      create_option_category_range_vote(decision)

    [option_category_range_vote1, option_category_range_vote2]
  end

  def assert_equivalent(expected, result) do
    assert expected.high_option_id == result.high_option_id
    assert expected.low_option_id == result.low_option_id
    assert expected.option_category_id == result.option_category_id
    assert expected.participant_id == result.participant_id
  end

  def add_low_option_id(attrs, %{low_option: low_option}),
    do: Map.put(attrs, :low_option_id, low_option.id)

  def add_low_option_id(attrs, _deps), do: attrs

  def add_high_option_id(attrs, %{high_option: high_option}),
    do: Map.put(attrs, :high_option_id, high_option.id)

  def add_high_option_id(attrs, _deps), do: attrs

  def add_record_id(attrs, %{option_category_range_vote: option_category_range_vote}),
    do: Map.put(attrs, :id, option_category_range_vote.id)

  def add_record_id(attrs, _deps), do: attrs
end
