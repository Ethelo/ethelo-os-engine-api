defmodule Engine.Scenarios.Docs.Scenario do
  @moduledoc "Central repository for documentation strings about Scenarios."
  require DocsComposer

  @scenario "A solution to a decision."

  @scenario_set_id "Unique identifier for the ScenarioSet the Scenario belongs to. All Scenarios are associated with a single ScenarioSet."

  @status "A string describing whether or not the solver was able to obtain a solution for the decision."

  @collective_identity "How much of a factor unity will have on the decision."

  @tipping_point "The dissonance at which people will cease to resist the outcome because of inequality aversion, and begin to support it due to fairness and the unity it creates."

  @minimize "Whether or not to minimize the Ethelo function rather than maximize it. When the function is minimized, the 'worst' scenarios will be selected."

  @global "Whether or not the scenario is a 'global' scenario (the all options scenario)."

  @scenario_displays "The display-value pairs associated with the scenario."

  @scenario_stats "The statistics associated with the scenario."

  @options "The options selected for the scenario."

  defp scenario_fields() do
    [
     %{name: :status, info: @status, type: :string, required: true},
     %{name: :collective_identity, info: @collective_identity, type: :float, required: true},
     %{name: :tipping_point, info: @tipping_point, type: :float, required: true},
     %{name: :minimize, info: @minimize, type: :boolean, required: true},
     %{name: :global, info: @global, type: :boolean, required: true},
     %{name: :scenario_displays, info: @scenario_displays, type: :has_many, required: true},
     %{name: :scenario_stats, info: @scenario_stats, type: :has_many, required: true},
     %{name: :options, info: @options, type: :many_to_many, required: true},
     %{name: :scenario_set_id, info: @scenario_set_id, type: "id" , required: true},
   ]
  end

  @doc """
  a list of maps describing all scenario schema fields

  Suitable for use with `DocsComposer.schema_fields`.
  """
  def fields() do
    DocsComposer.common_fields([:id, :slug, :inserted_at, :updated_at]) ++ scenario_fields()
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
    scenario_strings = %{
      scenario: @scenario,
      status: @status,
      collective_identity: @collective_identity,
      tipping_point: @tipping_point,
      minimize: @minimize,
      global: @global,
      scenario_displays: @scenario_displays,
      scenario_stats: @scenario_stats,
      options: @options,
      scenario_set_id: @scenario_set_id,
    }
    DocsComposer.common_strings() |> Map.merge(scenario_strings)
  end

end
