defmodule EtheloApi.Scenarios.Docs.ScenarioSet do
  @moduledoc "Central repository for documentation strings about ScenarioSets."
  require DocsComposer

  @scenario_set "A collection of Scenarios that pass all Decision Constraints."

  @decision_id "The Decision the ScenarioSet belongs to."

  @scenario_config_id "The configuration used to generate the ScenarioSet."

  @participant_id "The Participant, if any, the ScenarioSet belongs to."

  @status "The engine status for the Solve call."

  @hash "The settings and influent used in the call"

  @error "An optional string containing an error message if an error occurred while generating the ScenarioSet."

  @cached_decision "Flags if the ScenarioSet was generated from a cached (published) Decision."

  @engine_start "Optional timestamp of when engine solve call was started"

  @engine_end "Optional timestamp of when engine solve call was started"

  defp scenario_set_fields() do
    [
      %{name: :cached_decision, info: @cached_decision, type: :boolean, required: false},
      %{name: :decision_id, info: @decision_id, type: "id", required: true},
      %{name: :engine_end, info: @engine_end, type: :datetime, required: false},
      %{name: :engine_start, info: @engine_start, type: :datetime, required: false},
      %{name: :error, info: @error, type: :string, required: false},
      %{name: :hash, info: @hash, type: :string, required: false},
      %{name: :json_stats, info: @status, type: :string, required: false},
      %{name: :participant_id, info: @participant_id, type: "id", required: true},
      %{name: :scenario_config_id, info: @scenario_config_id, type: "id", required: true},
      %{name: :status, info: @status, type: :string, required: true}
    ]
  end

  @doc """
  a list of maps describing all scenario_set schema fields

  Suitable for use with `DocsComposer.schema_fields`.
  """
  def fields() do
    DocsComposer.common_fields([:id, :inserted_at, :updated_at]) ++ scenario_set_fields()
  end

  @doc """
  Map describing example records

  Suitable for use with `DocsComposer.schema_examples`.
  """
  def examples() do
    %{
      "All Participants" => %{
        cached_decision: true,
        decision_id: 1,
        engine_end: "2017-05-05T16:48:16+00:00",
        engine_start: "2017-05-05T16:48:16+00:00",
        error: nil,
        hash: "abcdef",
        json_stats: "[]",
        participant_id: nil,
        scenario_config_id: 1,
        status: "pending",
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00"
      },
      "One Participant" => %{
        cached_decision: true,
        decision_id: 1,
        engine_end: "2017-05-05T16:48:16+00:00",
        engine_start: "2017-05-05T16:48:16+00:00",
        error: nil,
        hash: "abcdef",
        inserted_at: "2017-05-05T16:48:16+00:00",
        json_stats: "[]",
        participant_id: 2,
        scenario_config_id: 2,
        status: "success",
        updated_at: "2017-05-05T16:48:16+00:00"
      }
    }
  end

  @doc """
  strings describing each field as well as the general concept of "scenario"
  """
  def strings() do
    scenario_set_strings = %{
      cached_decision: @cached_decision,
      decision_id: @decision_id,
      engine_end: @engine_end,
      engine_start: @engine_start,
      error: @error,
      hash: @hash,
      participant_id: @participant_id,
      participant: @participant_id,
      scenario_config: @scenario_config_id,
      scenario_config_id: @scenario_config_id,
      scenario_set: @scenario_set,
      status: @status
    }

    DocsComposer.common_strings() |> Map.merge(scenario_set_strings)
  end
end
