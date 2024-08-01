defmodule Engine.Scenarios.Docs.ScenarioDisplay do
  @moduledoc "Central repository for documentation strings about ScenarioDisplays."
  require DocsComposer

  @scenario_display "A display (calulated value) and the value it takes on in the context of a Scenario."

  @scenario_id "The scenario the ScenarioDisplay belongs to."

  @constraint_id "The constraint the ScenarioDisplay value is calculated using."

  @calculation_id "The calculation the ScenarioDisplay value is calulated using"

  @name "The name of the display."

  @value "The value the display takes on in the Scenario."

  @is_constraint "Whether or not the display is a constraint."

  defp scenario_display_fields() do
    [
     %{name: :name, info: @name, type: :string, required: true},
     %{name: :value, info: @value, type: :float, required: true},
     %{name: :is_constraint, info: @is_constraint, type: :boolean, required: true},
     %{name: :scenario_id, info: @scenario_id, type: "id" , required: true},
     %{name: :constraint_id, info: @constraint_id, type: "id" , required: false},
     %{name: :calculation_id, info: @calculation_id, type: "id" , required: false},
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
    %{}
  end

  @doc """
  strings describing each field as well as the general concept of "scenario_display"
  """
  def strings() do
    scenario_display_strings = %{
      scenario_display: @scenario_display,
      name: @name,
      value: @value,
      is_constraint: @is_constraint,
      scenario_id: @scenario_id,
      calculation_id: @calculation_id,
      constraint_id: @constraint_id,
    }
    DocsComposer.common_strings() |> Map.merge(scenario_display_strings)
  end

end
