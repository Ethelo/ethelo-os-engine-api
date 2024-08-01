defmodule EtheloApi.Voting.Docs.BinVote do
  @moduledoc "Central repository for documentation strings about BinVotes."

  require DocsComposer

  @decision_id "Unique identifier for the Decision the BinVote belongs to. All BinVotes are associated with a single Decision."

  @bin_vote " Participant votes for the specified option-criteria combo."

  @bin "Bin selected by participant"

  @option "Options are the choices that a make up a Decision solution."

  @option_id "Unique identifier for the Option the vote is associated with."

  @criteria "Criteria are the standards used to judge Options."

  @criteria_id "Unique identifier for the Criteria the vote is associated with."

  @participant "Ethelo User placing a vote."

  @participant_id "Unique identifier for the Participant the vote is associated with."

  defp option_fields() do
    [
     %{name: :bin, info: @bin, type: :integer, required: true, validation: "must be between 1 and 9"},
     %{name: :decision_id, info: @decision_id, type: "id", required: true},
     %{name: :participant_id, match_value: @participant_id, type: "id", required: true, validation: "must be part of the same Decision."},
     %{name: :criteria_id, match_value: @criteria_id, type: "id", required: true, validation: "must be part of the same Decision."},
     %{name: :option_id, match_value: @option_id, type: "id", required: true, validation: "must be part of the same Decision."},
   ]
  end

  @doc """
  a list of maps describing all option schema fields

  Suitable for use with `DocsComposer.schema_fields`.
  """
  def fields() do
    DocsComposer.common_fields([:id, :inserted_at, :updated_at]) ++ option_fields()
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
        option_id: 2,
        participant_id: 1,
        criteria_id: nil,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      },
      "Sample 2" => %{
        id: 2,
        bin: 5,
        option_id: 2,
        participant_id: 2,
        criteria_id: nil,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      },
    }
  end

  @doc """
  strings describing each field as well as the general concept of "bin_votes"
  """
  def strings() do
    strings = %{
      bin_vote: @bin_vote,
      option: @option,
      option_id: @option_id,
      criteria: @criteria,
      criteria_id: @criteria_id,
      participant: @participant,
      participant_id: @participant_id,
      bin: @bin,
      decision_id: @decision_id,
    }
    DocsComposer.common_strings() |> Map.merge(strings)
  end

end
