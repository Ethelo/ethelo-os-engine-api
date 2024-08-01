defmodule EtheloApi.Graphql.Docs.ScenarioConfig do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  # TODO add cache queries
  alias EtheloApi.Structure.Docs.ScenarioConfig, as: ScenarioConfigDocs
  alias EtheloApi.Graphql.QueryHelper

  def input_fields() do
    [
      :bins,
      :ci,
      :enabled,
      :engine_timeout,
      :max_scenarios,
      :normalize_influents,
      :normalize_satisfaction,
      :per_option_satisfaction,
      :quad_cutoff,
      :quad_max_allocation,
      :quad_round_to,
      :quad_seed_percent,
      :quad_total_available,
      :quad_user_seeds,
      :quad_vote_percent,
      :quadratic,
      :skip_solver,
      :slug,
      :support_only,
      :tipping_point,
      :title,
      :ttl
    ]
  end

  def rename_ci(%{} = map) do
    Map.put(map, :collective_identity, map.ci)
  end

  defp sample1() do
    ScenarioConfigDocs.examples() |> Map.get("Standard") |> rename_ci()
  end

  defp sample2() do
    ScenarioConfigDocs.examples() |> Map.get("Quadratic") |> rename_ci()
  end

  defp update1() do
    sample2() |> Map.put(:id, sample1().id)
  end

  @spec list() :: String.t()
  def list() do
    QueryHelper.query_example(
      "scenarioConfigs",
      sample1() |> Map.take([:decision_id]),
      Map.keys(sample1()),
      [sample1(), sample2()],
      "List matching ScenarioConfigs"
    )
  end

  @spec create() :: String.t()
  def create() do
    params = QueryHelper.mutation_params(sample1(), input_fields())

    QueryHelper.mutation_example(
      "createScenarioConfig",
      params,
      Map.keys(sample1()),
      sample1(),
      "Add a ScenarioConfig"
    )
  end

  @spec update() :: String.t()
  def update() do
    params = QueryHelper.mutation_params(update1(), input_fields())

    QueryHelper.mutation_example(
      "updateScenarioConfig",
      params,
      Map.keys(sample1()),
      update1(),
      "Update a ScenarioConfig"
    )
  end

  def delete() do
    params = QueryHelper.mutation_params(sample1(), [:decision_id, :id])
    comment = "Delete a ScenarioConfig.

    All associated ScenarioSets will also be removed."

    QueryHelper.delete_mutation_example(
      "deleteScenarioConfig",
      params,
      [:id],
      sample1() |> Map.take([:id]),
      comment
    )

    ""
  end
end
