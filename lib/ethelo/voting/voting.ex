defmodule EtheloApi.Voting do
  @moduledoc """
  The boundary for the Voting system.

  All access to update database values go through this class.
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

  def maybe_update_voting_hashes({:error, _} = result, _, _, _), do: result
  def maybe_update_voting_hashes(result, %{} = values, decision_id, mode) do
    update_participant_influent_hash(Map.get(values, :participant_id), decision_id)
    if mode == :influent do
      Structure.update_decision_influent_hash(decision_id)
    end
    if mode == :weighting do
      Structure.update_decision_weighting_hash(decision_id)
    end

    result
  end

  defdelegate preloaded_assoc(record, association), to: EtheloApi.Helpers.BatchHelper
  defdelegate associated_id(record, association), to: EtheloApi.Helpers.BatchHelper

  defdelegate vote_dump(decision_id), to: EtheloApi.Voting.VoteExportData, as: :vote_data_dump

  defdelegate list_participants(decision_id, filters \\ %{}), to: Participant
  defdelegate get_participant(id, decision), to: Participant
  defdelegate create_participant(decision, attrs), to: Participant
  defdelegate update_participant(participant, attrs), to: Participant
  defdelegate delete_participant(participant, decision_id), to: Participant
  defdelegate update_participant_influent_hash(participant), to: Participant
  defdelegate update_participant_influent_hash(participant_id, decision_id), to: Participant

  defdelegate list_bin_votes(decision_id, filters \\ %{}), to: BinVote
  defdelegate match_bin_votes(filters \\ %{}, decision_ids), to: BinVote
  defdelegate bin_votes_histogram(decision_id, type \\ "day", filters \\ %{}), to: BinVote
  defdelegate get_bin_vote(id, decision), to: BinVote
  defdelegate upsert_bin_vote(decision, attrs), to: BinVote
  defdelegate delete_bin_vote(bin_vote, decision_id), to: BinVote

  defdelegate list_option_category_bin_votes(decision_id, filters \\ %{}), to: OptionCategoryBinVote
  defdelegate match_option_category_bin_votes(filters \\ %{}, decision_ids), to: OptionCategoryBinVote
  defdelegate option_category_bin_votes_histogram(decision_id, type \\ "day", filters \\ %{}), to: OptionCategoryBinVote
  defdelegate get_option_category_bin_vote(id, decision), to: OptionCategoryBinVote
  defdelegate upsert_option_category_bin_vote(decision, attrs), to: OptionCategoryBinVote
  defdelegate delete_option_category_bin_vote(option_category_bin_vote, decision_id), to: OptionCategoryBinVote

  defdelegate list_option_category_range_votes(decision_id, filters \\ %{}), to: OptionCategoryRangeVote
  defdelegate match_option_category_range_votes(filters \\ %{}, decision_ids), to: OptionCategoryRangeVote
  defdelegate option_category_range_votes_histogram(decision_id, type \\ "day", filters \\ %{}), to: OptionCategoryRangeVote
  defdelegate get_option_category_range_vote(id, decision), to: OptionCategoryRangeVote
  defdelegate upsert_option_category_range_vote(decision, attrs), to: OptionCategoryRangeVote
  defdelegate delete_option_category_range_vote(option_category_range_vote, decision_id), to: OptionCategoryRangeVote

  defdelegate list_criteria_weights(decision_id, filters \\ %{}), to: CriteriaWeight
  defdelegate match_criteria_weights(filters \\ %{}, decision_ids), to: CriteriaWeight
  defdelegate get_criteria_weight(id, decision), to: CriteriaWeight
  defdelegate upsert_criteria_weight(decision, attrs), to: CriteriaWeight
  defdelegate delete_criteria_weight(criteria_weight, decision_id), to: CriteriaWeight

  defdelegate list_option_category_weights(decision_id, filters \\ %{}), to: OptionCategoryWeight
  defdelegate match_option_category_weights(filters \\ %{}, decision_ids), to: OptionCategoryWeight
  defdelegate get_option_category_weight(id, decision), to: OptionCategoryWeight
  defdelegate upsert_option_category_weight(decision, attrs), to: OptionCategoryWeight
  defdelegate delete_option_category_weight(option_category_weight, decision_id), to: OptionCategoryWeight

end
