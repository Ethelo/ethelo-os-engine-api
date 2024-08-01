defmodule EtheloApi.Scenarios.Queries.ScenarioDisplay do
  @moduledoc """
  Contains methods that will be delegated to inside EtheloApi.Scenarios.
  """

  alias EtheloApi.Repo
  alias EtheloApi.Scenarios.Scenario
  alias EtheloApi.Scenarios.ScenarioDisplay
  import Ecto.Query, warn: false
  import EtheloApi.Helpers.EctoHelper

  def valid_filters() do
    [:id, :scenario_id, :is_constraint, :decision_id]
  end

  def match_query(scenario_id, modifiers) do
    modifiers = Map.put(modifiers, :scenario_id, scenario_id)

    ScenarioDisplay
    |> filter_query(modifiers, valid_filters())
  end

  @doc """
  Returns the list of ScenarioDisplays for a Scenario.

  ## Examples

      iex> list_scenarios_display(scenario_id)
      [%ScenarioDisplay{}, ...]

  """
  def list_scenario_displays(scenario, modifiers \\ %{})

  def list_scenario_displays(%Scenario{} = scenario, modifiers),
    do: list_scenario_displays(scenario.id, modifiers)

  def list_scenario_displays(nil, _),
    do: raise(ArgumentError, message: "you must supply a Scenario")

  def list_scenario_displays(scenario_id, modifiers) do
    scenario_id |> match_query(modifiers) |> Repo.all()
  end

  @doc """
  Creates a ScenarioDisplay value.

  ## Examples

      iex> create_scenario_display( %{value:  48, scenario_id: 1})
      {:ok, %ScenarioDisplay{}}

      iex> create_scenario_display(d %{value: " "})
      {:error, %Ecto.Changeset{}}

  """
  def create_scenario_display(%{} = attrs) do
    ScenarioDisplay.create_changeset(attrs)
    |> Repo.insert()
  end
end
