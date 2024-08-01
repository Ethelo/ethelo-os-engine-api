defmodule Engine.Scenarios.Queries.ScenarioStatsBuilder do
  use Ecto.Schema

  alias Engine.Scenarios.ScenarioStats
  alias Engine.Scenarios.Calculators.AverageWeightsCalculator
  alias Engine.Scenarios.Calculators.HistogramCalculator
  alias Engine.Scenarios.Calculators.EngineStats

  def build_shared_stats(scenario_set, voting_data, engine_scenario) do
    option_stats = EngineStats.extract_option_stats(voting_data, engine_scenario)
    criteria_stats = EngineStats.extract_criteria_stats(voting_data, engine_scenario)
    option_category_stats = EngineStats.extract_option_category_stats(voting_data, engine_scenario)

    shared_stats = option_stats ++ criteria_stats ++ option_category_stats
    Enum.map( shared_stats, &( add_post_process_stats(&1, voting_data, scenario_set.id) ) )
  end

  def build_scenario_stats(scenario, voting_data, engine_scenario) do
    stats = engine_scenario
      |> EngineStats.extract_scenario_stats()
      |> Map.put(:scenario, scenario)

    add_post_process_stats(stats, voting_data, scenario.scenario_set_id)
  end

  def add_post_process_stats(stats, voting_data, scenario_set_id) do
    stats
    |> Map.put(:scenario_set_id, scenario_set_id)
    |> Map.put(:decision_id, voting_data.decision.id)
    |> add_association_ids()
    |> add_average_weights(voting_data)
    |> add_option_range_vote_counts(voting_data)
    |> add_histogram(voting_data)
    |> add_vote_spectrum()
    |> add_quadratic_data(voting_data)
    |> create_scenario_stats()
  end

  def create_scenario_stats(stats) do
    # we no longer save to db, but changeset is useful to cast everything
    changeset = ScenarioStats.create_changeset(%ScenarioStats{}, stats)
    changeset.changes
  end

  def add_average_weights(stats, voting_data) do
    stats |> Map.merge(AverageWeightsCalculator.average_weights(voting_data, stats))
  end

  def add_option_range_vote_counts(stats, voting_data) do
    counts = HistogramCalculator.option_range_vote_counts(voting_data, stats)
    Map.put(stats, :advanced_stats, counts )
  end

  def add_histogram(%{option_category: _} = stats, voting_data) do
    Map.put(stats, :histogram, HistogramCalculator.bin_vote_histogram(voting_data, stats))
  end
  def add_histogram(%{option: _} = stats, voting_data) do
    Map.put(stats, :histogram, HistogramCalculator.bin_vote_histogram(voting_data, stats))
  end
  def add_histogram(stats, _), do: stats

  def add_vote_spectrum(%{histogram: histogram} = stats) do
    stats |> Map.merge(HistogramCalculator.vote_spectrum(histogram))
  end
  def add_vote_spectrum(stats), do: stats

  def add_association_ids(%{option: option, criteria: criteria} = stats ) do
    stats
    |> Map.put(:option_id, option.id)
    |> Map.put(:criteria_id, criteria.id)
  end
  def add_association_ids(%{option: option} = stats ) do
    Map.put(stats, :option_id, option.id)
  end
  def add_association_ids(%{option_category: option_category} = stats ) do
    Map.put(stats, :issue_id, option_category.id)  # TODO eventually fix this
  end
  def add_association_ids(%{scenario: scenario} = stats ) do
    Map.put(stats, :scenario_id, scenario.id)
  end
  def add_association_ids(stats), do: stats

  def add_quadratic_data(%{scenario: _} = stats, %{quadratic_totals: quadratic_totals}) do
    quadratic_data = Map.get(quadratic_totals, :global)
    Map.merge(stats, quadratic_data)
  end

  def add_quadratic_data(%{option_category: %{id: id, quadratic: true}} = stats, voting_data) do
    quadratic_data = case voting_data do
      %{quadratic_totals: %{by_oc: %{^id => value }}} -> value
      %{} -> %{}
    end
    Map.merge(stats, quadratic_data)
  end
  def add_quadratic_data(stats, _), do: stats

end
