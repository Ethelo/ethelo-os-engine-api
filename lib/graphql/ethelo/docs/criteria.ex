defmodule GraphQL.EtheloApi.Docs.Criteria do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  alias EtheloApi.Structure.Docs.Criteria, as: CriteriaDocs
  alias GraphQL.DocBuilder

  defp sample1() do
    Map.get(CriteriaDocs.examples, "Sample 1")
  end

  defp sample2() do
    Map.get(CriteriaDocs.examples, "Sample 2")
  end

  defp update1() do
    Map.get(CriteriaDocs.examples(), "Update 1")
  end

  def input_fields() do
    [:slug, :info, :support_only, :bins, :title, :weighting, :sort]
  end

  defp object_name() do
    "criteria"
  end

  def list() do
    request = sample1()
    responses = [sample1(), sample2()]
    DocBuilder.list("criterias", request, responses, [:decision_id])
  end

  def get() do
    request = sample1()
    response = sample1()
    param_fields = [:decision_id, :id]
    DocBuilder.get(object_name(), request, response, param_fields)
  end

  def create() do
    query_field = "createCriteria"
    request = sample1()
    response = sample1()

    DocBuilder.create(query_field, request, response, object_name(), input_fields())
  end

  def update() do
    query_field = "updateCriteria"
    request = update1()
    response = update1()
    DocBuilder.update(query_field, request, response, object_name(), input_fields())
  end

  def delete() do
    query_field = "deleteCriteria"
    request = sample1()
    comment = "All associated Criteria Votes will also be removed."

    DocBuilder.delete(query_field, request, object_name(), comment)
  end

end
