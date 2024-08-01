defmodule EtheloApi.Structure.Docs.Criteria do
  @moduledoc "Central repository for documentation strings about Criteria."

  require DocsComposer

  @decision_id "The Decision the Criteria belongs to."

  @criteria """
  Criteria are the standards used to judge Options.

  All Decisions have a single Criteria by default: "Approval". This is the simplest set up and allows Participants to register their approval (or disapproval) of an Option.

  If your Participants need to compare different aspects for an Option, multiple Criteria allow a Participant a vote on each aspect. Participants can then (optionally) weight these aspects to state which is most important to them. By default, all Criteria are weighted equally.
  """

  @criteria_example """
  A simple example when choosing pizza has two Criteria: "Value" and "Taste".

  Each Participant rates the pizza choices, voting on Value and Taste for each.
  The also specify which Criteria is most important:
    Chewy thinks Taste should count for 75% of the score, and Value should count for 25%.
    C3P0 thinks Taste should count for 10% of the score, and Value should count for 90%.

  Their scores will be weighted based on their preference before being used to select a Decision.
  """
  @title "Name of Criteria. Used to generate slug if none supplied"
  @info "Informative text describing the Criteria."
  @bins """
  The number of vote increments to allow, between one and nine.

  These will correspond to the number of buttons or inputs on the presentation layer. While the actual interface is up to the presentation layer, we recommend using a Likert Scale.

  For example, if a Criteria has 5 bins, then presentation layer could show 5 buttons:
  [Strongly Disapprove] [Disapprove] [Neutral] [Approve] [Strongly Approve]
  """

  @weighting "Multiplier for a Decision-wide weighting to all votes to this Criteria. Participant specific weightings can also be entered."

  @support_only """
  A boolean that indicates if the Criteria should not include "disapproval" values. Defaults to "false".

  The Ethelo algorythm takes into account how polarizing a Decision is - if many Participants are "for" or "against" an Option, it will affect the score.

  By default, the system assumes that a vote in the lower bins indicates disapproval - Participants who use these values are against the Option.
  Bins are distributed from "Extremely Against" to "Neutral" to "Extremely Support".

  When "support only" is enbabled, then the assumption changes. Votes in the lower bins are instead considered neutral votes.
  Bins are distributed from "Neutral" to "Extremely Support".
  """

  @apply_participant_weights "A boolean indicating if Participant weighting should be applied to this OptionCategory"

  defp criteria_fields() do
    [
      %{
        name: :title,
        info: @title,
        type: :string,
        validation: "Must include at least one word",
        required: true,
        automatic: false,
        immutable: false
      },
      %{
        name: :info,
        info: @info,
        type: "markdown",
        required: false,
        automatic: false,
        immutable: false
      },
      %{
        name: :bins,
        info: @bins,
        type: :integer,
        validation: "must be between 1 and 9",
        default: 5,
        required: true,
        automatic: false,
        immutable: false
      },
      %{
        name: :weighting,
        info: @weighting,
        type: :integer,
        validation: "must be between 1 and 100",
        required: false,
        automatic: false,
        immutable: false
      },
      %{name: :support_only, info: @support_only, type: :boolean, required: false},
      %{
        name: :apply_participant_weights,
        info: @apply_participant_weights,
        type: :boolean,
        required: true,
        default: true
      },
      %{name: :decision_id, info: @decision_id, type: "id", required: true}
    ]
  end

  @doc """
  a list of maps describing all Criteria schema fields

  Suitable for use with `DocsComposer.schema_fields`.
  """
  def fields() do
    DocsComposer.common_fields([:id, :slug, :sort, :deleted, :inserted_at, :updated_at]) ++
      criteria_fields()
  end

  @doc """
  Map describing example records

  Suitable for use with `DocsComposer.schema_examples`.
  """
  def examples() do
    %{
      "Sample 1" => %{
        id: 1,
        support_only: false,
        title: "Value",
        slug: "value",
        info: "Is this a good value?",
        bins: 5,
        apply_participant_weights: true,
        decision_id: 1,
        weighting: 10,
        deleted: false,
        sort: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00"
      },
      "Sample 2" => %{
        id: 2,
        support_only: false,
        title: "Taste",
        slug: "taste",
        info: "Is this tasty?",
        bins: 5,
        apply_participant_weights: false,
        weighting: 40,
        decision_id: 1,
        deleted: false,
        sort: 2,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00"
      },
      "Sample 3" => %{
        id: 3,
        support_only: true,
        title: "Nutrition",
        slug: "Nutrition",
        info: "How Nutrious is this?",
        apply_participant_weights: true,
        bins: 5,
        decision_id: 1,
        weighting: nil,
        deleted: false,
        sort: 3,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00"
      },
      "Update 1" => %{
        id: 1,
        support_only: false,
        title: "Price",
        slug: "price",
        info: "Is the price a good value?",
        bins: 7,
        weighing: 23,
        apply_participant_weights: false,
        sort: 4,
        decision_id: 1,
        deleted: false,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00"
      }
    }
  end

  @doc """
  strings describing each field as well as the general concept of "criterias"
  """
  def strings() do
    criteria_strings = %{
      apply_participant_weights: @apply_participant_weights,
      bins: @bins,
      criteria: @criteria,
      decision_id: @decision_id,
      info: @info,
      mini_tutorial: @criteria_example,
      support_only: @support_only,
      title: @title,
      weighting: @weighting
    }

    DocsComposer.common_strings() |> Map.merge(criteria_strings)
  end
end
