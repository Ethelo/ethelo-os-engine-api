defmodule Engine.Scenarios.Queries.ScenarioDisplay do
  @moduledoc """
  Contains methods that will be delegated to inside scenario.
  Used purely to reduce the size of scenario.ex
  """

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.QueryHelper

  alias EtheloApi.Repo
  alias Engine.Scenarios.Scenario
  alias Engine.Scenarios.ScenarioDisplay

  def valid_filters() do
    [:id, :scenario_id, :is_constraint, :decision_id]
  end

  @doc """
  private method to start querying with acceptable preloads
  """
  def base_query() do
    ScenarioDisplay
  end

  def match_query(scenario_id, filters) do
    filters = Map.put(filters, :scenario_id, scenario_id)

    base_query()
    |> filter_query(filters, valid_filters())
  end

  @doc """
  Returns the list of ScenarioDisplays for a Scenario.

  ## Examples

      iex> list_scenarios_display(scenario_id)
      [%ScenarioDisplay{}, ...]

  """
  def list_scenario_displays(scenario, filters \\ %{})
  def list_scenario_displays(%Scenario{} = scenario, filters), do: list_scenario_displays(scenario.id, filters)
  def list_scenario_displays(nil, _), do: raise ArgumentError, message: "you must supply a Scenario"
  def list_scenario_displays(scenario_id, filters) do
    scenario_id |> match_query(filters) |> Repo.all
  end

  @doc """
  Returns the matching ScenarioDisplays for a Decision. Used by batch processor, do not change signature

  ## Examples

      iex> match_scenario_display(decision_id)
      [%ScenarioDisplay{}, ...]

  """
  def match_scenario_displays(filters \\ %{}, decision_ids)
  def match_scenario_displays(filters, decision_ids) when is_list(decision_ids) do
    decision_ids = Enum.uniq(decision_ids)

    ScenarioDisplay
    |> where([t], t.decision_id in ^decision_ids)
    |> filter_query(filters, valid_filters())
    |> Repo.all
  end
  def match_scenario_displays(_, nil), do: raise ArgumentError, message: "you must supply a list of Decision ids"

  @doc """
  Gets a single ScenarioDisplay by id

  returns nil if ScenarioDisplay does not exist or does not belong to the specified Scenario

  ## Examples

      iex> get_scenario_display(123, 1)
      %ScenarioDisplay{}

      iex> get_scenario_display(456, 3)
      nil

  """
  def get_scenario_display(id, %Scenario{} = scenario), do: get_scenario_display(id, scenario.id)
  def get_scenario_display(_, nil), do: raise ArgumentError, message: "you must supply a Scenario id"
  def get_scenario_display(nil, _), do:  raise ArgumentError, message: "you must supply a ScenarioDisplay id"
  def get_scenario_display(id, scenario_id) do
    base_query() |> Repo.get_by(id: id, scenario_id: scenario_id)
  end

end
