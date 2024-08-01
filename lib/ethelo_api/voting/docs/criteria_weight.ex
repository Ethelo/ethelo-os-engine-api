defmodule EtheloApi.Voting.Docs.CriteriaWeight do
  @moduledoc "Central repository for documentation strings about CriteriaWeights."

  require DocsComposer

  @decision_id "The CriteriaWeight belongs to."

  @criteria_weight "Participant weighting for all votes matching the specified Criteria."

  @weighting "Amount to weight, selected by Participant"

  @criteria_id "The Criteria to weight. Criteria are the standards used to judge Options"

  @participant_id "The Participant the vote is associated with."

  defp option_fields() do
    [
      %{
        name: :weighting,
        info: @weighting,
        type: :integer,
        required: true,
        validation: "must be between 1 and 100"
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
      }
    ]
  end

  @doc """
  a list of maps describing all CriteriaWeight schema fields

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
        weighting: 33,
        participant_id: 1,
        criteria_id: nil,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00"
      },
      "Sample 2" => %{
        id: 2,
        weighting: 35,
        participant_id: 2,
        criteria_id: nil,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00"
      }
    }
  end

  @doc """
  strings describing each field as well as the general concept of "criteria_weights"
  """
  def strings() do
    strings = %{
      criteria_id: @criteria_id,
      criteria_weight: @criteria_weight,
      criteria: @criteria_id,
      decision_id: @decision_id,
      participant_id: @participant_id,
      participant: @participant_id,
      weighting: @weighting
    }

    DocsComposer.common_strings() |> Map.merge(strings)
  end
end
