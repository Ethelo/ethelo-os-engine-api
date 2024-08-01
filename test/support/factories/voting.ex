defmodule EtheloApi.Voting.Factory do
  @moduledoc """
  Factories to use when testing Ethelo Decisions
  """
  use EtheloApi.BaseFactory, module: __MODULE__

  alias EtheloApi.Structure.Factory, as: Structure

  alias EtheloApi.Voting.Participant
  alias EtheloApi.Voting.CriteriaWeight
  alias EtheloApi.Voting.OptionCategoryWeight
  alias EtheloApi.Voting.BinVote
  alias EtheloApi.Voting.OptionCategoryBinVote
  alias EtheloApi.Voting.OptionCategoryRangeVote
  alias EtheloApi.Structure.Decision

  defdelegate create_criteria(), to: Structure
  defdelegate create_option_detail_filter(), to: Structure
  defdelegate create_option_category_filter(), to: Structure
  defdelegate create_option_category(), to: Structure
  defdelegate create_option(), to: Structure
  defdelegate create_decision(), to: Structure

  defdelegate delete_criteria(id), to: Structure
  defdelegate delete_option_filter(id), to: Structure
  defdelegate delete_option_category(id), to: Structure
  defdelegate delete_option(id), to: Structure
  defdelegate delete_decision(id), to: Structure

  def option_category_weight_defaults() do
    %OptionCategoryWeight{
      weighting: Enum.random(0..100),
    }
  end

  def option_category_weight_deps() do
    decision = Structure.create_decision()
    option_category_weight_deps(decision)
  end

  def option_category_weight_deps(%Decision{} = decision) do
    %{option_category: option_category} = Structure.create_option_category(decision)
    %{participant: participant} = create_participant(decision)
    %{option_category: option_category, participant: participant, decision: decision}
  end

  def create_option_category_weight() do
    decision = Structure.create_decision()
    create_option_category_weight(decision)
  end

  def create_option_category_weight(%Decision{} = decision, overrides \\ %{}) do
    deps = option_category_weight_deps(decision)
    values = Map.merge(deps, overrides)
    option_category_weight = insert(option_category_weight_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:option_category_weight, option_category_weight)
  end

  def create_option_category_weight_without_deps(%Decision{} = decision, values \\ %{}) do
    values = Map.put(values, :decision, decision)
    insert(option_category_weight_defaults(), values)
  end

  def delete_option_category_weight(id) do
    OptionCategoryWeight |> do_delete_all(id)
  end

  def criteria_weight_defaults() do
    %CriteriaWeight{
      weighting: Enum.random(0..100),
    }
  end

  def criteria_weight_deps() do
    decision = Structure.create_decision()
    criteria_weight_deps(decision)
  end

  def criteria_weight_deps(%Decision{} = decision) do
    %{criteria: criteria} = Structure.create_criteria(decision)
    %{participant: participant} = create_participant(decision)
    %{criteria: criteria, participant: participant, decision: decision}
  end

  def create_criteria_weight() do
    decision = Structure.create_decision()
    create_criteria_weight(decision)
  end

  def create_criteria_weight(%Decision{} = decision, overrides \\ %{}) do
    deps = criteria_weight_deps(decision)
    values = Map.merge(deps, overrides)
    criteria_weight = insert(criteria_weight_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:criteria_weight, criteria_weight)
  end

  def create_criteria_weight_without_deps(%Decision{} = decision, values \\ %{}) do
    values = Map.put(values, :decision, decision)
    insert(criteria_weight_defaults(), values)
  end

  def delete_criteria_weight(id) do
    CriteriaWeight |> do_delete_all(id)
  end

  def bin_vote_defaults() do
    %BinVote{
      bin: Enum.random(1..9),
    }
  end

  def bin_vote_deps() do
    decision = Structure.create_decision()
    bin_vote_deps(decision)
  end

  def bin_vote_deps(%Decision{} = decision) do
    %{criteria: criteria} = Structure.create_criteria(decision)
    %{participant: participant} = create_participant(decision)
    %{option: option} = Structure.create_option(decision)
    %{option: option, criteria: criteria, participant: participant, decision: decision}
  end

  def create_bin_vote() do
    decision = Structure.create_decision()
    create_bin_vote(decision)
  end

  def create_bin_vote(%Decision{} = decision, overrides \\ %{}) do
    deps = bin_vote_deps(decision)
    values = Map.merge(deps, overrides)
    bin_vote = insert(bin_vote_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:bin_vote, bin_vote)
  end

  def create_bin_vote_without_deps(%Decision{} = decision, values \\ %{}) do
    values = Map.put(values, :decision, decision)
    insert(bin_vote_defaults(), values)
  end

  def delete_bin_vote(id) do
    BinVote |> do_delete_all(id)
  end

  def option_category_bin_vote_defaults() do
    %OptionCategoryBinVote{
      bin: Enum.random(1..9),
    }
  end

  def option_category_bin_vote_deps() do
    decision = Structure.create_decision()
    option_category_bin_vote_deps(decision)
  end

  def option_category_bin_vote_deps(%Decision{} = decision) do
    %{criteria: criteria} = Structure.create_criteria(decision)
    %{participant: participant} = create_participant(decision)
    %{option_category: option_category} = Structure.create_option_category(decision)
    %{option_category: option_category, criteria: criteria, participant: participant, decision: decision}
  end

  def create_option_category_bin_vote() do
    decision = Structure.create_decision()
    create_option_category_bin_vote(decision)
  end

  def create_option_category_bin_vote(%Decision{} = decision, overrides \\ %{}) do
    deps = option_category_bin_vote_deps(decision)
    values = Map.merge(deps, overrides)
    option_category_bin_vote = insert(option_category_bin_vote_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:option_category_bin_vote, option_category_bin_vote)
  end

  def create_option_category_bin_vote_without_deps(%Decision{} = decision, values \\ %{}) do
    values = Map.put(values, :decision, decision)
    insert(option_category_bin_vote_defaults(), values)
  end

  def delete_option_category_bin_vote(id) do
    OptionCategoryBinVote |> do_delete_all(id)
  end

  def option_category_range_vote_defaults() do
    %OptionCategoryRangeVote{}
  end

  def option_category_range_vote_deps() do
    decision = Structure.create_decision()
    option_category_range_vote_deps(decision)
  end

  def option_category_range_vote_deps(%Decision{} = decision) do
    %{participant: participant} = create_participant(decision)
    %{option_category: option_category} = Structure.create_option_category(decision)
    low_option = Structure.create_option_without_deps(decision, %{option_category: option_category})
    high_option = Structure.create_option_without_deps(decision, %{option_category: option_category})

    %{option_category: option_category, low_option: low_option, high_option: high_option, participant: participant, decision: decision}
  end

  def create_option_category_range_vote() do
    decision = Structure.create_decision()
    create_option_category_range_vote(decision)
  end

  def create_option_category_range_vote(%Decision{} = decision, overrides \\ %{}) do
    deps = option_category_range_vote_deps(decision)
    values = Map.merge(deps, overrides)
    option_category_range_vote = insert(option_category_range_vote_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:option_category_range_vote, option_category_range_vote)
  end

  def create_option_category_range_vote_without_deps(%Decision{} = decision, values \\ %{}) do
    values = Map.put(values, :decision, decision)
    insert(option_category_range_vote_defaults(), values)
  end

  def delete_option_category_range_vote(id) do
    OptionCategoryRangeVote |> do_delete_all(id)
  end

  def participant_defaults() do
    %Participant{
      weighting: Decimal.from_float(Enum.random(1..1000) / 10),
      influent_hash: "#{unique_int()}",
    }
  end

  def participant_deps() do
    decision = Structure.create_decision()
    participant_deps(decision)
  end

  def participant_deps(%Decision{} = decision) do
    %{decision: decision}
  end

  def create_participant() do
    decision = Structure.create_decision()
    create_participant(decision)
  end

  def create_participant(%Decision{} = decision, overrides \\ %{}) do
    deps = participant_deps(decision)
    values = Map.merge(deps, overrides)
    participant = insert(participant_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:participant, participant)
  end

  def create_participant_without_deps(%Decision{} = decision, values \\ %{}) do
    values = Map.put(values, :decision, decision)
    insert(participant_defaults(), values)
  end

  def delete_participant(id) do
    Participant |> do_delete_all(id)
  end

end
