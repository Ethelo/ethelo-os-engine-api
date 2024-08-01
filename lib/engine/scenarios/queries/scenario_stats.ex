defmodule Engine.Scenarios.Queries.ScenarioStats do
  @moduledoc """
  Contains methods that will be delegated to inside scenario.
  Used purely to reduce the size of scenario.ex
  """

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.QueryHelper

  alias EtheloApi.Repo
  alias Engine.Scenarios.ScenarioSet
  alias Engine.Scenarios.ScenarioStats

  def valid_filters() do
    [:id, :scenario_set_id, :scenario_id, :criteria_id, :option_id, :issue_id, :default, :decision_id]
  end

  @doc """
  private method to start querying with acceptable preloads
  """
  def base_query() do
    ScenarioStats
  end

  def match_query(scenario_set_id, filters) do
    filters = Map.put(filters, :scenario_set_id, scenario_set_id)

    base_query()
    |> filter_query(filters, valid_filters())
  end

  @doc """
  Returns the list of ScenarioStats for a ScenarioSet.

  ## Examples

      iex> list_scenarios_stats(scenario_set_id)
      [%Scenario{}, ...]


  """
  def list_scenario_stats(scenario_set, filters \\ %{})
  def list_scenario_stats(nil, _), do: raise ArgumentError, message: "you must supply a ScenarioSet"
  def list_scenario_stats(scenario_set_id, filters) when is_integer(scenario_set_id) do
   Repo.get_by(ScenarioSet, id: scenario_set_id)
    |> list_scenario_stats(filters)
  end
  def list_scenario_stats(%ScenarioSet{} = scenario_set, filters) do
      scenario_set
      |> parsed_stats_for()
      |> filter_stat_list(filters)
  end

  defp parsed_stats_for(%ScenarioSet{parsed_stats: nil, json_stats: json_stats}) do
    decode_stats(json_stats) |> Enum.map(&(struct(ScenarioStats, &1)))
  end
  defp parsed_stats_for(%ScenarioSet{parsed_stats: parsed_stats}), do: parsed_stats

  defp filter_stat_list(stat_list, filters) do
    values = filters |> Map.take(valid_filters())
    keys = values |> Map.keys
    stat_list
    |> Enum.filter(fn(row) ->
      row_values = Map.take(row, keys)
      row_values == values
    end)
  end

  defp decode_stats(nil), do: []
  defp decode_stats(json) do
    case Poison.Parser.parse(json, %{keys: :atoms!}) do
      {:ok, stats } -> stats
      {:error, _} -> []
    end
  end

end
