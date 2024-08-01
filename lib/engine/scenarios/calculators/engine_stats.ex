defmodule Engine.Scenarios.Calculators.EngineStats do

  def prepare_engine_stats(engine_stats) do
    stat_values = %{
      abstain_votes: engine_stats |> Map.get("abstain_votes", 0) |> Kernel.trunc,
      total_votes: engine_stats |> Map.get("total_votes", 0) |> Kernel.trunc,
      default: true,
      support: engine_stats["support"],
      approval: engine_stats["approval"],
      dissonance: engine_stats["dissonance"],
      ethelo: engine_stats["ethelo"],
      histogram: engine_stats["histogram"],
    }

    if stat_values[:total_votes] < 1 do
      Map.merge(stat_values, %{support: nil, approval: nil, dissonance: nil, ethelo: nil})
    else
      stat_values
    end
  end

  def extract_scenario_stats(%{} = engine_scenario) do
    scenario_stats = get_in(engine_scenario, ["stats", "global"])
    prepare_engine_stats(scenario_stats)
  end

  def extract_option_stats(voting_data, %{} = engine_scenario) do
    option_data = get_in(engine_scenario, ["stats", "options"]) || []

    Enum.map(option_data, fn {option_slug, engine_stats} ->
      option = Map.get(voting_data.options_by_slug, option_slug, %{slug: option_slug})
      %{option: option} |> Map.merge( prepare_engine_stats(engine_stats) )
    end)
  end

  def extract_criteria_stats(voting_data, %{} = engine_scenario) do
    criteria_option_data = get_in(engine_scenario, ["stats","criteria"]) || []
    Enum.map(criteria_option_data, fn({option_slug, criteria_data}) ->
      option = Map.get(voting_data.options_by_slug, option_slug, %{slug: option_slug})

      Enum.map(criteria_data, fn {criteria_slug, engine_stats} ->
        criteria = Map.get(voting_data.criterias_by_slug, criteria_slug, %{slug: criteria_slug})
        %{option: option, criteria: criteria} |> Map.merge( prepare_engine_stats(engine_stats) )
      end)
    end)
    |> List.flatten()
  end

  def extract_option_category_stats(voting_data, %{} = engine_scenario) do
    option_category_data = get_in(engine_scenario, ["stats", "issues"]) || []

    Enum.map(option_category_data, fn {option_category_slug, engine_stats} ->
      option_category = Map.get(voting_data.option_categories_by_slug, String.slice(option_category_slug, 1..-1), %{slug: option_category_slug})
      %{option_category: option_category} |> Map.merge( prepare_engine_stats(engine_stats) )
    end)
  end

end
