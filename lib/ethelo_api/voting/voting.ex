defmodule EtheloApi.Voting do
  @moduledoc """
  The boundary for the Voting system.

  All access to update database values go through this module.
  To keep code files small, the actual methods are in the /queries folder
  and are linked with defdelegate
  """

  alias EtheloApi.Structure
  alias EtheloApi.Voting.Queries.BinVote
  alias EtheloApi.Voting.Queries.OptionCategoryBinVote
  alias EtheloApi.Voting.Queries.OptionCategoryRangeVote
  alias EtheloApi.Voting.Queries.CriteriaWeight
  alias EtheloApi.Voting.Queries.OptionCategoryWeight
  alias EtheloApi.Voting.Queries.Participant

  def maybe_update_influent_hash({:error, _} = result, _, _), do: result

  def maybe_update_influent_hash(result, %{} = values, decision_id) do
    update_participant_influent_hash(Map.get(values, :participant_id), decision_id)

    Structure.update_decision_influent_hash(decision_id)

    result
  end

  defdelegate vote_dump(decision_id), to: EtheloApi.Voting.VoteExportData, as: :vote_data_dump

  defdelegate list_participants(decision_id, modifiers \\ %{}), to: Participant
  defdelegate get_participant(id, decision), to: Participant
  defdelegate create_participant(attrs, decision), to: Participant
  defdelegate update_participant(participant, attrs), to: Participant
  defdelegate delete_participant(participant, decision_id), to: Participant
  defdelegate update_participant_influent_hash(participant), to: Participant
  defdelegate update_participant_influent_hash(participant_id, decision_id), to: Participant

  defdelegate list_bin_votes(decision_id, modifiers \\ %{}), to: BinVote

  defdelegate bin_vote_activity(decision_id, interval \\ "day", modifiers \\ %{}), to: BinVote

  defdelegate get_bin_vote(id, decision), to: BinVote
  defdelegate upsert_bin_vote(attrs, decision), to: BinVote
  defdelegate delete_bin_vote(bin_vote, decision_id), to: BinVote

  defdelegate list_option_category_bin_votes(decision_id, modifiers \\ %{}),
    to: OptionCategoryBinVote

  defdelegate option_category_bin_vote_activity(decision_id, interval \\ "day", modifiers \\ %{}),
    to: OptionCategoryBinVote

  defdelegate get_option_category_bin_vote(id, decision), to: OptionCategoryBinVote
  defdelegate upsert_option_category_bin_vote(attrs, decision), to: OptionCategoryBinVote

  defdelegate delete_option_category_bin_vote(option_category_bin_vote, decision_id),
    to: OptionCategoryBinVote

  defdelegate list_option_category_range_votes(decision_id, modifiers \\ %{}),
    to: OptionCategoryRangeVote

  defdelegate option_category_range_vote_activity(
                decision_id,
                interval \\ "day",
                modifiers \\ %{}
              ),
              to: OptionCategoryRangeVote

  defdelegate get_option_category_range_vote(id, decision), to: OptionCategoryRangeVote
  defdelegate upsert_option_category_range_vote(attrs, decision), to: OptionCategoryRangeVote

  defdelegate delete_option_category_range_vote(option_category_range_vote, decision_id),
    to: OptionCategoryRangeVote

  defdelegate list_criteria_weights(decision_id, modifiers \\ %{}), to: CriteriaWeight
  defdelegate get_criteria_weight(id, decision), to: CriteriaWeight
  defdelegate upsert_criteria_weight(attrs, decision), to: CriteriaWeight
  defdelegate delete_criteria_weight(criteria_weight, decision_id), to: CriteriaWeight

  defdelegate list_option_category_weights(decision_id, modifiers \\ %{}),
    to: OptionCategoryWeight

  defdelegate get_option_category_weight(id, decision), to: OptionCategoryWeight
  defdelegate upsert_option_category_weight(attrs, decision), to: OptionCategoryWeight

  defdelegate delete_option_category_weight(option_category_weight, decision_id),
    to: OptionCategoryWeight
end
