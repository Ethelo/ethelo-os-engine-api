defmodule EtheloApi.Voting.TestHelper.ParticipantHelper do
  @moduledoc """
  Participant specific test tools
  """

  import ExUnit.Assertions
  import EtheloApi.Voting.Factory
  import(EtheloApi.TestHelper.GenericHelper)

  def fields() do
    %{
      id: :string,
      inserted_at: :date,
      updated_at: :date,
      # decimals not supported
      weighting: :float
    }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  def input_field_names() do
    [:weighting]
  end

  def decimals_to_floats(attrs) do
    attrs = decimal_attr_to_float(attrs, :weighting)
    attrs
  end

  def empty_attrs(),
    do: %{
      influent_hash: nil,
      participant_id: nil,
      weighting: nil
    }

  def invalid_attrs(deps \\ %{}) do
    %{
      participant_id: 30,
      weighting: 999_999
    }
    |> add_record_id(deps)
    |> add_decision_id(deps)
  end

  def valid_attrs(deps \\ %{}) do
    %{
      weighting: 1.72,
      influent_hash: "123"
    }
    |> add_record_id(deps)
    |> add_decision_id(deps)
  end

  def create_pair() do
    %{participant: participant1, decision: decision} = create_participant()
    %{participant: participant2} = create_participant(decision)
    [participant1, participant2]
  end

  def assert_equivalent(expected, result) do
    assert expected.influent_hash == result.influent_hash
    assert Decimal.compare(Decimal.from_float(expected.weighting), result.weighting) == :eq
  end

  def add_record_id(attrs, %{participant: participant}),
    do: Map.put(attrs, :id, participant.id)

  def add_record_id(attrs, _deps), do: attrs
end
