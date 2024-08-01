defmodule EtheloApi.Scenarios.Docs.SolveDump do
  @moduledoc "Central repository for documentation strings about SolveDumps."
  require DocsComposer

  @solve_dump "A dump of the jsons used to solve a Decision"

  @decision_id "The Decision the SolveDump belongs to."

  @scenario_set_id "The Scenario set id matching the dump."

  @participant_id "The Participant, if any, the SolveDump belongs to."

  @decision_json "the decision json sent to the engine"
  @influents_json "the influents json sent to the engine"
  @weights_json "the weights json sent to the engine"
  @config_json "the config json sent to the engine"
  @response_json "the response json returned by the engine"
  @error "the error returned by the engine"

  defp solve_dump_fields() do
    [
      %{name: :decision_json, info: @decision_json, type: "text", required: false},
      %{name: :influents_json, info: @influents_json, type: "text", required: false},
      %{name: :weights_json, info: @weights_json, type: "text", required: false},
      %{name: :config_json, info: @config_json, type: "text", required: false},
      %{name: :response_json, info: @response_json, type: "text", required: false},
      %{name: :error, info: @error, type: "text", required: false},
      %{name: :decision_id, info: @decision_id, type: "id", required: true},
      %{name: :scenario_set_id, info: @scenario_set_id, type: "id", required: true},
      %{name: :participant_id, info: @participant_id, type: "id", required: true}
    ]
  end

  @doc """
  a list of maps describing all SolveDump schema fields

  Suitable for use with `DocsComposer.schema_fields`.
  """
  def fields() do
    DocsComposer.common_fields([:id, :inserted_at, :updated_at]) ++ solve_dump_fields()
  end

  @doc """
  Map describing example records

  Suitable for use with `DocsComposer.schema_examples`.
  """
  def examples() do
    %{
      "Sample 1" => %{
        config_json: "{....}",
        decision_id: 1,
        decision_json: "{....}",
        error: nil,
        id: 2,
        influents_json: "{....}",
        inserted_at: "2017-05-05T16:48:16+00:00",
        participant_id: nil,
        response_json: "{....}",
        scenario_set_id: 1,
        updated_at: "2017-05-05T16:48:16+00:00",
        weights_json: "{....}"
      },
      "Sample 2" => %{
        config_json: "{....}",
        decision_id: 1,
        decision_json: "{....}",
        error: "Failed to Solve",
        id: 3,
        influents_json: "{....}",
        inserted_at: "2017-05-05T16:48:16+00:00",
        participant_id: 1,
        response_json: nil,
        scenario_set_id: 1,
        updated_at: "2017-05-05T16:48:16+00:00",
        weights_json: "{....}"
      }
    }
  end

  @doc """
  strings describing each field as well as the general concept of "scenario"
  """
  def strings() do
    solve_dump_strings = %{
      config_json: @config_json,
      decision_json: @decision_json,
      error: @error,
      influents_json: @influents_json,
      participant_id: @participant_id,
      participant: @participant_id,
      response_json: @response_json,
      scenario_set_id: @scenario_set_id,
      scenario_set: @scenario_set_id,
      solve_dump: @solve_dump,
      weights_json: @weights_json
    }

    DocsComposer.common_strings() |> Map.merge(solve_dump_strings)
  end
end
