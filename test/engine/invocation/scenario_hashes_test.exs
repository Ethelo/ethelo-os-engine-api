defmodule Engine.Scenarios.ScenarioHashesTest do
  @moduledoc """
  unique hashes
  """
  use EtheloApi.DataCase
  import EtheloApi.Structure.Factory
  alias Engine.Invocation.ScenarioHashes
  @moduletag data: true

  setup do
    EtheloApi.Blueprints.PizzaProject.build()
  end

  def load_bin_vote(decision_id, participant) do
    EtheloApi.Voting.list_bin_votes(decision_id, %{participant_id: participant.id})
    |> List.first()
  end

  def load_ocrv(decision_id, participant) do
    EtheloApi.Voting.list_option_category_range_votes(decision_id, %{participant_id: participant.id})
    |> List.first()
  end

  def update_bin_vote(bin_vote, new_bin, decision) do
    attrs = %{
      bin: new_bin,
      criteria_id: bin_vote.criteria_id,
      option_id: bin_vote.option_id,
      participant_id: bin_vote.participant_id
    }

    {:ok, new_bin_vote} = EtheloApi.Voting.upsert_bin_vote(decision, attrs)
    new_bin_vote
  end

  def update_ocrv(ocrv, new_option, decision) do
    attrs = %{
      option_category_id: ocrv.option_category_id,
      low_option_id: new_option.id,
      high_option_id: new_option.id,
      participant_id: ocrv.participant_id
    }

    {:ok, new_ocrv} = EtheloApi.Voting.upsert_option_category_range_vote(decision, attrs)
    new_ocrv
  end

  test "group influent hash with no votes" do
    decision = create_decision()

    influent_hash = ScenarioHashes.generate_group_influent_hash(decision.id)
    assert {:ok, ""} = influent_hash
  end

  test "participant influent hash with no votes", context do
    participant = context[:participants][:no_votes]

    # correct participant check
    influent_hash = ScenarioHashes.generate_participant_influent_hash(participant)
    assert {:ok, ""} = influent_hash
  end

  test "participant influent hash updates with binvotes", context do
    %{decision: decision} = context

    participant = context[:participants][:one]
    # correct participant check
    assert Decimal.cmp(participant.weighting, Decimal.from_float(1.00)) == :eq

    {:ok, current_hash} = ScenarioHashes.generate_participant_influent_hash(participant)

    bin_vote = load_bin_vote(decision.id, participant)

    Process.sleep(999)

    updated_bin_vote = update_bin_vote(bin_vote, bin_vote.bin + 1, decision)

    assert bin_vote.bin != updated_bin_vote.bin
    assert bin_vote.updated_at != updated_bin_vote.updated_at

    influent_hash = ScenarioHashes.generate_participant_influent_hash(participant)
    assert {:ok, new_hash} = influent_hash

    refute new_hash == current_hash
  end

  test "group influent hash updates with binvotes", context do
    %{decision: decision} = context
    {:ok, current_hash} = ScenarioHashes.generate_group_influent_hash(decision.id)

    participant = context[:participants][:two]
    bin_vote = load_bin_vote(decision.id, participant)

    Process.sleep(999)

    updated_bin_vote = update_bin_vote(bin_vote, bin_vote.bin + 1, decision)

    assert bin_vote.bin != updated_bin_vote.bin
    assert bin_vote.updated_at != updated_bin_vote.updated_at

    influent_hash = ScenarioHashes.generate_group_influent_hash(decision.id)
    assert {:ok, new_hash} = influent_hash

    refute new_hash == current_hash
  end

  test "participant influent hash updates with ocrv", context do
    %{decision: decision} = context

    participant = context[:participants][:one]
    # correct participant check
    assert Decimal.cmp(participant.weighting, Decimal.from_float(1.00)) == :eq

    {:ok, current_hash} = ScenarioHashes.generate_participant_influent_hash(participant)

    ocrv = load_ocrv(decision.id, participant)

    Process.sleep(999)

    option = context[:options][:xor1]
    updated_ocrv = update_ocrv(ocrv, option, decision)

    assert ocrv.low_option_id != updated_ocrv.low_option_id
    assert ocrv.updated_at != updated_ocrv.updated_at

    influent_hash = ScenarioHashes.generate_participant_influent_hash(participant)
    assert {:ok, new_hash} = influent_hash

    refute new_hash == current_hash
  end

  test "group influent hash updates with range votes", context do
    %{decision: decision} = context
    {:ok, current_hash} = ScenarioHashes.generate_group_influent_hash(decision.id)

    participant = context[:participants][:two]
    ocrv = load_ocrv(decision.id, participant)

    Process.sleep(999)

    option = context[:options][:xor2]
    updated_ocrv = update_ocrv(ocrv, option, decision)

    assert ocrv.low_option_id != updated_ocrv.low_option_id
    assert ocrv.updated_at != updated_ocrv.updated_at

    influent_hash = ScenarioHashes.generate_group_influent_hash(decision.id)
    assert {:ok, new_hash} = influent_hash

    refute new_hash == current_hash
  end
end
