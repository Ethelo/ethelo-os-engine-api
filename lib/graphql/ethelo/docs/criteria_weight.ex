defmodule GraphQL.EtheloApi.Docs.CriteriaWeight do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  alias EtheloApi.Voting.Docs.CriteriaWeight, as: CriteriaWeightDocs
  alias GraphQL.DocBuilder

  defp sample1() do
    Map.get(CriteriaWeightDocs.examples, "Sample 1")
  end

  defp sample2() do
    Map.get(CriteriaWeightDocs.examples, "Sample 2")
  end

  defp update1() do
    Map.get(CriteriaWeightDocs.examples, "Sample 1")
  end  

  def input_fields() do
    [:decision_id, :weighting]
  end

  defp object_name() do
    "criteriaWeight"
  end

  def list() do
    request = sample1()
    responses = [sample1(), sample2()]
    DocBuilder.list("criteriaWeights", request, responses, [:decision_id])
  end

  def get() do
    request = sample1()
    response = sample1()
    param_fields = [:decision_id, :id]
    DocBuilder.get(object_name(), request, response, param_fields)
  end

  def create() do
    query_field = "createCriteriaWeight"
    request = sample1()
    response = sample1()

    DocBuilder.create(query_field, request, response, object_name(), input_fields())
  end

  def update() do
    query_field = "updateCriteriaWeight"
    request = update1()
    response = update1()
    DocBuilder.update(query_field, request, response, object_name(), input_fields())
  end

  def delete() do
    query_field = "deleteCriteriaWeight"
    request = sample1()

    DocBuilder.delete(query_field, request, object_name(), "")
  end

end
