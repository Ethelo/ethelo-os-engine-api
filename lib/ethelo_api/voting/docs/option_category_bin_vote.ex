defmodule EtheloApi.Voting.Docs.OptionCategoryBinVote do
  @moduledoc "Central repository for documentation strings about OptionCategoryBinVotes."

  require DocsComposer

  @decision_id "The Decision the OptionCategoryBinVote belongs to."

  @option_category_bin_vote " Participant votes for the specified OptionCategory-Criteria combo. This is used in combination with OptionCategoryRangedVotes to generate BinVotes for an entire OptionCategory"

  @bin "Bin selected by Participant"

  @criteria_id "The Criteria the vote is associated with. Criteria are the standards used to judge OptionCategories."

  @participant_id "The Participant the vote is associated with."

  @option_category_id "The OptionCategory to match and weight. Each Option is grouped into a single OptionCategory"

  defp option_category_bin_vote_fields() do
    [
      %{
        name: :bin,
        info: @bin,
        type: :integer,
        required: true,
        validation: "must be between 1 and 9"
      },
      %{name: :decision_id, info: @decision_id, type: "id", required: true},
      %{
        name: :participant_id,
        match_value: @participant_id,
        type: "id",
        required: true,
        validation: "must be part of the same Decision."
      },
      %{
        name: :criteria_id,
        match_value: @criteria_id,
        type: "id",
        required: true,
        validation: "must be part of the same Decision."
      },
      %{
        name: :option_category_id,
        match_value: @option_category_id,
        type: "id",
        required: true,
        validation: "must be part of the same Decision."
      }
    ]
  end

  @doc """
  a list of maps describing all OptionCategoryBinVoteFields schema fields

  Suitable for use with `DocsComposer.schema_fields`.
  """
  def fields() do
    DocsComposer.common_fields([:id, :inserted_at, :updated_at]) ++
      option_category_bin_vote_fields()
  end

  @doc """
  Map describing example records

  Suitable for use with `DocsComposer.schema_examples`.
  """
  def examples() do
    %{
      "Sample 1" => %{
        id: 1,
        bin: 3,
        option_category_id: 2,
        participant_id: 1,
        criteria_id: nil,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00"
      },
      "Sample 2" => %{
        id: 2,
        bin: 5,
        option_category_id: 2,
        participant_id: 2,
        criteria_id: nil,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00"
      }
    }
  end

  @doc """
  strings describing each field as well as the general concept of OptionCategoryBinVotes
  """
  def strings() do
    strings = %{
      bin: @bin,
      criteria_id: @criteria_id,
      criteria: @criteria_id,
      decision_id: @decision_id,
      option_category_bin_vote: @option_category_bin_vote,
      option_category_id: @option_category_id,
      option_category: @option_category_id,
      participant_id: @participant_id,
      participant: @participant_id
    }

    DocsComposer.common_strings() |> Map.merge(strings)
  end
end
