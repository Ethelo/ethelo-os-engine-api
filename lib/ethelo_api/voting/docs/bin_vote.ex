defmodule EtheloApi.Voting.Docs.BinVote do
  @moduledoc "Central repository for documentation strings about BinVotes."

  require DocsComposer

  @decision_id "The Decision the BinVote belongs to."

  @bin_vote " Participant votes for the specified Option-Criteria combo."

  @bin "Bin selected by Participant"

  @option_id "The Option the BinVote is associated with. Options are the choices that a make up a Decision solution."

  @criteria_id "The Criteria the BinVote is associated with. Criteria are the standards used to judge Options."

  @participant_id "The Participant the BinVote is associated with."

  defp option_fields() do
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
        name: :option_id,
        match_value: @option_id,
        type: "id",
        required: true,
        validation: "must be part of the same Decision."
      }
    ]
  end

  @doc """
  a list of maps describing all BinVote schema fields

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
        updated_at: "2017-05-05T16:48:16+00:00"
      },
      "Sample 2" => %{
        id: 2,
        bin: 5,
        option_id: 2,
        participant_id: 2,
        criteria_id: nil,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00"
      }
    }
  end

  @doc """
  strings describing each field as well as the general concept of "bin_votes"
  """
  def strings() do
    strings = %{
      bin_vote: @bin_vote,
      bin: @bin,
      criteria_id: @criteria_id,
      criteria: @criteria_id,
      decision_id: @decision_id,
      option_id: @option_id,
      option: @option_id,
      participant_id: @participant_id,
      participant: @participant_id
    }

    DocsComposer.common_strings() |> Map.merge(strings)
  end
end
