defmodule EtheloApi.Invocation.ConfigJson do
  @moduledoc """
  assembles necessary data for engine configuration
  """

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.ScenarioConfig

  @spec build(EtheloApi.Structure.ScenarioConfig.t()) :: map()
  def build(%ScenarioConfig{} = config) do
    %{
      "single_outcome" => config.skip_solver,
      "support_only" => config.support_only,
      "per_option_satisfaction" => config.per_option_satisfaction,
      "normalize_satisfaction" => config.normalize_satisfaction,
      "normalize_influents" => config.normalize_influents,
      "collective_identity" => decimal_to_float(config.ci),
      "tipping_point" => decimal_to_float(config.tipping_point),
      "histogram_bins" => config.bins,
      "solution_limit" => Kernel.min(config.max_scenarios, 20)
    }
  end

  @spec build(EtheloApi.Structure.ScenarioConfig.t(), list(map())) :: map()
  def build(%ScenarioConfig{} = config, option_categories) when is_list(option_categories) do
    issues =
      for cat <- option_categories do
        "C" <> cat.slug
      end

    build(config) |> Map.put("issues", issues)
  end

  def build_json(scenario_config, decision, pretty \\ true)

  def build_json(%ScenarioConfig{} = scenario_config, option_categories, pretty)
      when is_list(option_categories) do
    build(scenario_config, option_categories) |> to_json(pretty)
  end

  def build_json(%ScenarioConfig{} = scenario_config, %Decision{} = decision, pretty) do
    option_categories = Structure.list_option_categories(decision.id)
    build(scenario_config, option_categories) |> to_json(pretty)
  end

  defp decimal_to_float(%Decimal{} = value), do: Decimal.to_float(value)
  defp decimal_to_float(value) when is_float(value), do: value

  def to_json(map, pretty \\ true), do: Jason.encode!(map, pretty: pretty)
end
