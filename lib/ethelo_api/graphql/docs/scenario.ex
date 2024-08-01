defmodule EtheloApi.Graphql.Docs.Scenario do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  alias EtheloApi.Scenarios.Docs.Scenario, as: ScenarioDocs
  alias EtheloApi.Graphql.QueryHelper
  # TODO inline fields

  defp sample1() do
    ScenarioDocs.examples() |> Map.get("Sample 1")
  end

  defp sample2() do
    ScenarioDocs.examples() |> Map.get("Sample 2")
  end

  @spec list() :: String.t()
  def list() do
    QueryHelper.query_example(
      "scenarios",
      sample1() |> Map.take([:decision_id]),
      Map.keys(sample1()),
      [sample1(), sample2()],
      "List matching scenarios"
    )
  end
end
