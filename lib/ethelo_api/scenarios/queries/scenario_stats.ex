defmodule EtheloApi.Scenarios.Queries.ScenarioStats do
  @moduledoc """
  Contains methods that will be delegated to inside scenario.
  Used purely to reduce the size of scenario.ex
  """

  alias EtheloApi.Repo
  alias EtheloApi.Scenarios.ScenarioSet
  alias EtheloApi.Scenarios.ScenarioStats

  def valid_filters() do
    [
      :id,
      :scenario_set_id,
      :scenario_id,
      :criteria_id,
      :option_id,
      :issue_id,
      :default,
      :decision_id
    ]
  end

  @doc """
  Returns the list of ScenarioStats for a ScenarioSet.

  ## Examples

      iex> list_scenarios_stats(scenario_set_id)
      [%Scenario{}, ...]


  """
  def list_scenario_stats(scenario_set, modifiers \\ %{})

  def list_scenario_stats(nil, _),
    do: raise(ArgumentError, message: "you must supply a ScenarioSet")

  def list_scenario_stats(scenario_set_id, modifiers) when is_integer(scenario_set_id) do
    Repo.get_by(ScenarioSet, id: scenario_set_id)
    |> list_scenario_stats(modifiers)
  end

  def list_scenario_stats(%ScenarioSet{} = scenario_set, modifiers) do
    scenario_set
    |> parsed_stats_for()
    |> filter_stat_list(modifiers)
  end

  defp parsed_stats_for(%ScenarioSet{parsed_stats: nil, json_stats: json_stats}) do
    for stat_row <- decode_stats(json_stats) do
      struct(ScenarioStats, stat_row)
    end
  end

  defp parsed_stats_for(%ScenarioSet{parsed_stats: parsed_stats}), do: parsed_stats

  defp filter_stat_list(stat_list, modifiers) do
    values = modifiers |> Map.take(valid_filters())
    keys = values |> Map.keys()

    stat_list
    |> Enum.filter(fn row ->
      row_values = Map.take(row, keys)
      row_values == values
    end)
  end

  defp decode_stats(nil), do: []

  defp decode_stats(json) do
    case Jason.decode(json, keys: :atoms!) do
      {:ok, stats} -> stats
      {:error, _} -> []
    end
  end
end
