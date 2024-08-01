defmodule EtheloApi.Voting.Docs.Participant do
  @moduledoc "Central repository for documentation strings about Participants."

  require DocsComposer

  @participant "Ethelo User Participating in a Decision, including submitting BinVotes and Weightings for a Decision."

  @decision_id "The Decision the Participant belongs to."

  @weighting "Weighting applied to all votes from Participant"

  @influent_hash "A unique hash identify the Participant's current votes"

  defp participant_fields() do
    [
      %{
        name: :weighting,
        info: @weighting,
        type: :integer,
        required: true,
        validation: "must be between 1 and 100"
      },
      %{name: :decision_id, info: @decision_id, type: "id", required: true},
      %{name: :influent_hash, info: @influent_hash, type: :strig, required: false}
    ]
  end

  @doc """
  a list of maps describing all Participant schema fields

  Suitable for use with `DocsComposer.schema_fields`.
  """
  def fields() do
    DocsComposer.common_fields([:id, :inserted_at, :updated_at]) ++ participant_fields()
  end

  @doc """
  Map describing example records

  Suitable for use with `DocsComposer.schema_examples`.
  """
  def examples() do
    %{
      "Sample 1" => %{
        id: 1,
        weighting: Decimal.from_float(0.5),
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00"
      },
      "Sample 2" => %{
        id: 2,
        weighting: Decimal.from_float(1.5),
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00"
      }
    }
  end

  @doc """
  strings describing each field as well as the general concept of Participants
  """
  def strings() do
    strings = %{
      decision_id: @decision_id,
      participant: @participant,
      weighting: @weighting
    }

    DocsComposer.common_strings() |> Map.merge(strings)
  end
end
