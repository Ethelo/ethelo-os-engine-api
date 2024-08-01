defmodule EtheloApi.Graphql.Docs.ScenarioSet do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  alias EtheloApi.Scenarios.Docs.ScenarioSet, as: ScenarioSetDocs
  alias EtheloApi.Graphql.QueryHelper

  defp sample1() do
    ScenarioSetDocs.examples() |> Map.get("All Participants")
  end

  defp sample2() do
    ScenarioSetDocs.examples() |> Map.get("One Participant")
  end

  @spec list() :: String.t()
  def list() do
    QueryHelper.query_example(
      "scenarioSets",
      sample1() |> Map.take([:decision_id]),
      Map.keys(sample1()),
      [sample1(), sample2()],
      "List matching ScenarioSets"
    )
  end

  @spec solve() :: String.t()
  def solve() do
    params = QueryHelper.mutation_params(sample1(), [:decision_id, :id])

    QueryHelper.mutation_example(
      "solveDecision",
      params,
      Map.keys(sample1()),
      sample1(),
      "trigger a Solve Request"
    )
  end
end
