defmodule GraphQL.EtheloApi.Docs.ScenarioSet do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """

  alias GraphQL.DocBuilder

  defp input_fields() do
    [:participant_id]
  end

  defp object_name() do
    "scenarioSet"
  end

  def create() do
    #TODO: add examples
    query_field = "createScenarioSet"
    request = %{}
    response = %{}

    DocBuilder.create(query_field, request, response, object_name(), input_fields())
  end
end
