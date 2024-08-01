defmodule Engine.Scenarios.Docs.ScenarioSet do
  @moduledoc "Central repository for documentation strings about ScenarioSets."
  require DocsComposer

  @scenario_set "A collection of scenarios."

  @decision_id "The decision the ScenarioSet belongs to."

  @scenario_config_id "The configuration used to generate the ScenarioSet."

  @participant_id "The participant, if any, the ScenarioSet belongs to."

  @status "The engine status for the ScenarioSet."

  @error "An optional string containing an error message if an error occurred while generating the ScenarioSet."

  @cached_decision "The ScenarioSet was generated from a cached (published) decision."

  @engine_start "Optional timestamp of when engine solve call was started"

  @engine_end "Optional timestamp of when engine solve call was started"

  defp scenario_set_fields() do
    [
     %{name: :status, info: @status, type: :string, required: true},
     %{name: :json_stats, info: @status, type: :string, required: true},
     %{name: :error, info: @error, type: :string, required: false},
     %{name: :cached_decision, info: @cached_decision, type: :string, required: false},
     %{name: :decision_id, info: @decision_id, type: "id" , required: true},
     %{name: :scenario_config_id, info: @scenario_config_id, type: "id" , required: true},
     %{name: :participant_id, info: @participant_id, type: "id" , required: true},
     %{name: :engine_start, info: @engine_start, type: :datetime, required: false},
     %{name: :engine_end, info: @engine_end, type: :datetime, required: false},
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
    %{}
  end

  @doc """
  strings describing each field as well as the general concept of "scenario"
  """
  def strings() do
    scenario_set_strings = %{
      scenario_set: @scenario_set,
      status: @status,
      error: @error,
      cached_decision: @cached_decision,
      decision_id: @decision_id,
      scenario_config_id: @scenario_config_id,
      participant_id: @participant_id,
      engine_start: @engine_start,
      engine_end: @engine_end,
    } 
    DocsComposer.common_strings() |> Map.merge(scenario_set_strings)
  end

end
