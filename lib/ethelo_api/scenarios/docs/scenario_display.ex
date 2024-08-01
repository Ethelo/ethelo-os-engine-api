defmodule EtheloApi.Scenarios.Docs.ScenarioDisplay do
  @moduledoc "Central repository for documentation strings about ScenarioDisplays."
  require DocsComposer

  @scenario_display "A ScenarioDisplay (calulated value not used in a constraint) in the context of a specific Scenario."

  @scenario_id "The Scenario the ScenarioDisplay belongs to."

  @constraint_id "The Constraint the ScenarioDisplay value is calculated using."

  @calculation_id "The Calculation the ScenarioDisplay value is calulated using"

  @name "The name of the ScenarioDisplay."

  @value "The value the ScenarioDisplay takes on in the Scenario."

  @is_constraint "Whether or not the ScenarioDisplay is a constraint."

  defp scenario_display_fields() do
    [
      %{name: :name, info: @name, type: :string, required: true},
      %{name: :value, info: @value, type: :float, required: true},
      %{name: :is_constraint, info: @is_constraint, type: :boolean, required: true},
      %{name: :scenario_id, info: @scenario_id, type: "id", required: true},
      %{name: :constraint_id, info: @constraint_id, type: "id", required: false},
      %{name: :calculation_id, info: @calculation_id, type: "id", required: false}
    ]
  end

  @doc """
  a list of maps describing all scenario_display schema fields

  Suitable for use with `DocsComposer.schema_fields`.
  """
  def fields() do
    DocsComposer.common_fields([:id, :inserted_at, :updated_at]) ++ scenario_display_fields()
  end

  @doc """
  Map describing example records

  Suitable for use with `DocsComposer.schema_examples`.
  """
  def examples() do
    %{
      "Sample 1" => %{
        calculation_id: 2,
        constraint_id: 1,
        decision_id: 1,
        id: 2,
        inserted_at: "2017-05-05T16:48:16+00:00",
        is_constraint: true,
        name: "Total",
        scenario_id: 4,
        updated_at: "2017-05-05T16:48:16+00:00",
        value: 49.9
      },
      "Sample 2" => %{
        calculation_id: 2,
        constraint_id: 1,
        decision_id: 1,
        id: 3,
        inserted_at: "2017-05-05T16:48:16+00:00",
        is_constraint: false,
        name: "Total with Tax",
        scenario_id: 4,
        updated_at: "2017-05-05T16:48:16+00:00",
        value: 56.9
      }
    }
  end

  @doc """
  strings describing each field as well as the general concept of "scenario_display"
  """
  def strings() do
    scenario_display_strings = %{
      calculation_id: @calculation_id,
      calculation: @calculation_id,
      constraint_id: @constraint_id,
      constraint: @constraint_id,
      is_constraint: @is_constraint,
      name: @name,
      scenario_display: @scenario_display,
      scenario_id: @scenario_id,
      scenario: @scenario_id,
      value: @value
    }

    DocsComposer.common_strings() |> Map.merge(scenario_display_strings)
  end
end
