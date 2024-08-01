defmodule GraphQL.EtheloApi.Docs.ScenarioConfig do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  alias Engine.Scenarios.Docs.ScenarioConfig, as: ScenarioConfigDocs
  alias GraphQL.DocBuilder

  defp sample1() do
    ScenarioConfigDocs.examples() |> Map.get("Defaults") |> rename_ci()
  end

  defp sample2() do
    ScenarioConfigDocs.examples() |> Map.get("Example 1") |> rename_ci()
  end

  defp update1() do
    sample2() |> Map.put(:id, sample1().id)
  end

  def rename_ci(%{} = map) do
    Map.put(map, :collective_identity, map.ci)
  end

  def input_fields() do
    [:slug, :title, :bins, :support_only, :per_option_satisfaction, :normalize_satisfaction,
    :normalize_influents, :ttl, :engine_timeout, :max_scenarios, :ci, :tipping_point, :enabled, :skip_solver,
    :quadratic, :quad_user_seeds, :quad_total_available, :quad_cutoff, :quad_max_allocation,
    :quad_round_to, :quad_seed_percent, :quad_vote_percent,
  ]
  end

  defp object_name() do
    "scenarioConfig"
  end

  def list() do
    request = sample1()
    responses = [sample1(), sample2()]
    DocBuilder.list("scenarioConfigs", request, responses, [:decision_id])
  end

  def get() do
    request = sample1()
    response = sample1()
    param_fields = [:decision_id, :id]
    DocBuilder.get(object_name(), request, response, param_fields)
  end

  def create() do
    query_field = "createScenarioConfig"
    request = sample1()
    response = sample1()

    DocBuilder.create(query_field, request, response, object_name(), input_fields())
  end

  def update() do
    query_field = "updateScenarioConfig"
    request = update1()
    response = update1()
    DocBuilder.update(query_field, request, response, object_name(), input_fields())
  end

  def delete() do
    query_field = "deleteScenarioConfig"
    request = sample1()
    comment = ""

    DocBuilder.delete(query_field, request, object_name(), comment)
  end

end
