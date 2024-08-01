defmodule EtheloApi.Voting.TestHelper.OptionCategoryWeightHelper do
  @moduledoc """
  OptionCategoryWeight specific test tools
  """

  import ExUnit.Assertions
  import EtheloApi.Voting.Factory
  import(EtheloApi.TestHelper.GenericHelper)

  def fields() do
    %{
      inserted_at: :date,
      updated_at: :date,
      option_category_id: :string,
      weighting: :integer
    }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  def input_field_names() do
    [
      :option_category_id,
      :participant_id,
      :weighting
    ]
  end

  def empty_attrs() do
    %{
      option_category_id: nil,
      participant_id: nil,
      weighting: nil
    }
  end

  def invalid_attrs(deps \\ %{}) do
    %{
      option_category_id: 400,
      participant_id: 400,
      weighting: 999
    }
    |> add_record_id(deps)
    |> add_participant_id(deps)
    |> add_option_category_id(deps)
    |> add_decision_id(deps)
  end

  def valid_attrs(deps \\ %{}) do
    %{
      option_category_id: nil,
      participant_id: nil,
      weighting: 35
    }
    |> add_record_id(deps)
    |> add_participant_id(deps)
    |> add_option_category_id(deps)
    |> add_decision_id(deps)
  end

  def create_pair() do
    %{option_category_weight: option_category_weight1, decision: decision} =
      create_option_category_weight()

    %{option_category_weight: option_category_weight2} = create_option_category_weight(decision)
    [option_category_weight1, option_category_weight2]
  end

  def assert_equivalent(expected, result) do
    assert expected.option_category_id == result.option_category_id
    assert expected.participant_id == result.participant_id
    assert expected.weighting == result.weighting
  end

  def add_record_id(attrs, %{option_category_weight: option_category_weight}),
    do: Map.put(attrs, :id, option_category_weight.id)

  def add_record_id(attrs, _deps), do: attrs
end
