defmodule EtheloApi.Voting.Docs.OptionCategoryRangeVote do
  @moduledoc "Central repository for documentation strings about OptionCategoryRangeVotes."

  require DocsComposer

  @decision_id "The Decision the OptionCategoryRangeVote belongs to."

  @option_category_range_vote " Participant range votes for the specified OptionCategory. These are used to generate BinVotes for Options based on the OptionCategory primary OptionDetail. Options will be ordered by the OptionDetailValue, and scores applied to Options between the selected ones."

  @participant_id "The Participant the vote is associated with."

  @option_category_id "The OptionCategory to match and weight. Each Option is grouped into a single OptionCategory"

  @low_option_id "The lower Option the OptionCategoryRangeVote is associated with. Options are the choices that a make up a Decision solution."
  @high_option_id "The higher Option the OptionCategoryRangeVote is associated with.Options are the choices that a make up a Decision solution."

  defp option_category_range_vote_fields() do
    [
      %{name: :decision_id, info: @decision_id, type: "id", required: true},
      %{
        name: :participant_id,
        match_value: @participant_id,
        type: "id",
        required: true,
        validation: "must be part of the same Decision."
      },
      %{
        name: :low_option_id,
        match_value: @low_option_id,
        type: "id",
        required: true,
        validation: "must be part of the same Decision."
      },
      %{
        name: :high_option_id,
        match_value: @high_option_id,
        type: "id",
        required: false,
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
  a list of maps describing all OptionCategoryRangeVote schema fields

  Suitable for use with `DocsComposer.schema_fields`.
  """
  def fields() do
    DocsComposer.common_fields([:id, :inserted_at, :updated_at]) ++
      option_category_range_vote_fields()
  end

  @doc """
  Map describing example records

  Suitable for use with `DocsComposer.schema_examples`.
  """
  def examples() do
    %{
      "Sample 1" => %{
        id: 1,
        option_category_id: 2,
        participant_id: 1,
        low_option_id: 1,
        high_option_id: 2,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00"
      },
      "Sample 2" => %{
        id: 2,
        option_category_id: 2,
        participant_id: 2,
        low_option_id: 2,
        high_option_id: nil,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00"
      }
    }
  end

  @doc """
  strings describing each field as well as the general concept of OptionCategoryRangeVotes
  """
  def strings() do
    strings = %{
      decision_id: @decision_id,
      high_option_id: @high_option_id,
      low_option_id: @low_option_id,
      option_category_id: @option_category_id,
      option_category_range_vote: @option_category_range_vote,
      option_category: @option_category_id,
      participant_id: @participant_id,
      participant: @participant_id
    }

    DocsComposer.common_strings() |> Map.merge(strings)
  end
end
