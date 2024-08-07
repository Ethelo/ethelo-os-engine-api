defmodule EtheloApi.Voting.Docs.OptionCategoryWeight do
  @moduledoc "Central repository for documentation strings about OptionCategoryWeights."

  require DocsComposer

  @decision_id "The Decision the OptionCategoryWeight belongs to. "

  @option_category_weight "Participant weighting for all Options matching the specified OptionCategory."

  @weighting "Multiplier applied to all Participant BinVotes matching the specified OptionCategory"

  @option_category_id "The OptionCategory to match and weight. Each Option is grouped into a single OptionCategory"

  @participant_id "The Participant the vote is associated with."

  defp option_category_weight_fields() do
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
        name: :option_category_id,
        match_value: @option_category_id,
        type: "id",
        required: true,
        validation: "must be part of the same Decision."
      }
    ]
  end

  @doc """
  a list of maps describing all OptionCategoryWeight schema fields

  Suitable for use with `DocsComposer.schema_fields`.
  """
  def fields() do
    DocsComposer.common_fields([:id, :inserted_at, :updated_at]) ++
      option_category_weight_fields()
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
        option_category_id: nil,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00"
      },
      "Sample 2" => %{
        id: 2,
        weighting: 67,
        participant_id: 2,
        option_category_id: nil,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00"
      }
    }
  end

  @doc """
  strings describing each field as well as the general concept of "option_category_weights"
  """
  def strings() do
    strings = %{
      decision_id: @decision_id,
      option_category_id: @option_category_id,
      option_category_weight: @option_category_weight,
      option_category: @option_category_id,
      participant_id: @participant_id,
      participant: @participant_id,
      weighting: @weighting
    }

    DocsComposer.common_strings() |> Map.merge(strings)
  end
end
