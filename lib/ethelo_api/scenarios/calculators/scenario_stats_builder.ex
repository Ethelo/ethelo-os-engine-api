defmodule EtheloApi.Scenarios.Queries.ScenarioStatsBuilder do
  @moduledoc """
  Builds out all ScenarioStats, including any post-processing like Average Weights
  """
  use Ecto.Schema

  alias EtheloApi.Scenarios.ScenarioStats
  alias EtheloApi.Scenarios.Calculators.AverageWeightsCalculator
  alias EtheloApi.Scenarios.Calculators.HistogramCalculator
  alias EtheloApi.Scenarios.Calculators.EngineStats

  def build_shared_stats(scenario_set, import_data, engine_scenario) do
    option_stats = EngineStats.extract_option_stats(import_data, engine_scenario)
    criteria_stats = EngineStats.extract_criteria_stats(import_data, engine_scenario)

    option_category_stats =
      EngineStats.extract_option_category_stats(import_data, engine_scenario)

    shared_stats = option_stats ++ criteria_stats ++ option_category_stats
    Enum.map(shared_stats, &add_post_process_stats(&1, import_data, scenario_set.id))
  end

  def build_scenario_stats(scenario, import_data, engine_scenario) do
    stats =
      engine_scenario
      |> EngineStats.extract_scenario_stats()
      |> Map.put(:scenario, scenario)

    add_post_process_stats(stats, import_data, scenario.scenario_set_id)
  end

  def add_post_process_stats(stats, import_data, scenario_set_id) do
    stats
    |> Map.put(:scenario_set_id, scenario_set_id)
    |> Map.put(:decision_id, import_data.decision.id)
    |> add_association_ids()
    |> add_average_weights(import_data)
    |> add_option_range_vote_counts(import_data)
    |> add_histogram(import_data)
    |> add_vote_spectrum()
    |> add_quadratic_data(import_data)
    |> create_scenario_stats()
  end

  def create_scenario_stats(stats) do
    # we no longer save to db, but changeset is useful to cast everything
    changeset = ScenarioStats.cast_changeset(stats)
    changeset.changes
  end

  def add_average_weights(stats, import_data) do
    stats |> Map.merge(AverageWeightsCalculator.average_weights(import_data, stats))
  end

  def add_option_range_vote_counts(stats, import_data) do
    counts = HistogramCalculator.option_range_vote_counts(import_data, stats)
    Map.put(stats, :advanced_stats, counts)
  end

  def add_histogram(%{option_category: _} = stats, import_data) do
    Map.put(stats, :histogram, HistogramCalculator.bin_vote_histogram(import_data, stats))
  end

  def add_histogram(%{option: _} = stats, import_data) do
    Map.put(stats, :histogram, HistogramCalculator.bin_vote_histogram(import_data, stats))
  end

  def add_histogram(stats, _), do: stats

  def add_vote_spectrum(%{histogram: histogram} = stats) do
    stats |> Map.merge(HistogramCalculator.vote_spectrum(histogram))
  end

  def add_vote_spectrum(stats), do: stats

  def add_association_ids(%{option: option, criteria: criteria} = stats) do
    stats
    |> Map.put(:option_id, option.id)
    |> Map.put(:criteria_id, criteria.id)
  end

  def add_association_ids(%{option: option} = stats) do
    Map.put(stats, :option_id, option.id)
  end

  def add_association_ids(%{option_category: option_category} = stats) do
    # TODO eventually fix the issue/option_category mismatch
    Map.put(stats, :issue_id, option_category.id)
  end

  def add_association_ids(%{scenario: scenario} = stats) do
    Map.put(stats, :scenario_id, scenario.id)
  end

  def add_association_ids(stats), do: stats

  def add_quadratic_data(%{scenario: _} = stats, %{quadratic_totals: quadratic_totals}) do
    quadratic_data = Map.get(quadratic_totals, :global)
    Map.merge(stats, quadratic_data)
  end

  def add_quadratic_data(%{option_category: %{id: id, quadratic: true}} = stats, import_data) do
    quadratic_data =
      case import_data do
        %{quadratic_totals: %{by_oc: %{^id => value}}} -> value
        %{} -> %{}
      end

    Map.merge(stats, quadratic_data)
  end

  def add_quadratic_data(stats, _), do: stats
end
