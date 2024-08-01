defmodule EtheloApi.Scenarios.Docs.Scenario do
  @moduledoc "Central repository for documentation strings about Scenarios."
  require DocsComposer

  @scenario "A solution to a Decision."

  @scenario_set_id "The ScenarioSet the Scenario belongs to. All Scenarios are associated with a single ScenarioSet."

  @status "A string describing whether or not the solver was able to obtain a solution for the decision."

  @collective_identity "How much of a factor unity will have on the decision."

  @tipping_point "The dissonance at which people will cease to resist the outcome because of inequality aversion, and begin to support it due to fairness and the unity it creates."

  @minimize "Whether or not to minimize the Ethelo function rather than maximize it. When the function is minimized, the 'worst' scenarios will be selected."

  @global "Whether or not the Scenario is a 'global' Scenario (the all options Scenario)."

  @scenario_displays "The display-value pairs associated with the Scenario."

  @scenario_stats "The statistics associated with the Scenario."

  @options "The Options selected for the Scenario."

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
      %{name: :scenario_set_id, info: @scenario_set_id, type: "id", required: true}
    ]
  end

  @doc """
  a list of maps describing all Scenario schema fields

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
    %{
      "Sample 1" => %{
        collective_identity: 0.0,
        decision_id: 1,
        global: false,
        id: 2,
        inserted_at: "2017-05-05T16:48:16+00:00",
        minimize: false,
        scenario_set_id: 2,
        status: "pending",
        tipping_point: 0.44,
        updated_at: "2017-05-05T16:48:16+00:00"
      },
      "Sample 2" => %{
        collective_identity: 0.5,
        decision_id: 1,
        global: true,
        id: 3,
        inserted_at: "2017-05-05T16:48:16+00:00",
        minimize: false,
        scenario_set_id: 3,
        status: "success",
        tipping_point: 0.39,
        updated_at: "2017-05-05T16:48:16+00:00"
      }
    }
  end

  @doc """
  strings describing each field as well as the general concept of "scenario"
  """
  def strings() do
    scenario_strings = %{
      collective_identity: @collective_identity,
      global: @global,
      minimize: @minimize,
      option_ids: @options,
      options: @options,
      scenario_displays: @scenario_displays,
      scenario_set_id: @scenario_set_id,
      scenario_set: @scenario_set_id,
      scenario_stats: @scenario_stats,
      scenario: @scenario,
      status: @status,
      tipping_point: @tipping_point
    }

    DocsComposer.common_strings() |> Map.merge(scenario_strings)
  end
end
