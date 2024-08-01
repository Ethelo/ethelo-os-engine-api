defmodule GraphQL.EtheloApi.Docs.OptionCategoryWeight do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  alias EtheloApi.Voting.Docs.OptionCategoryWeight, as: OptionCategoryWeightDocs
  alias GraphQL.DocBuilder

  defp sample1() do
    Map.get(OptionCategoryWeightDocs.examples, "Sample 1")
  end

  defp sample2() do
    Map.get(OptionCategoryWeightDocs.examples, "Sample 2")
  end

  defp update1() do
    Map.get(OptionCategoryWeightDocs.examples, "Sample 1")
  end  

  def input_fields() do
    [:decision_id, :weighting]
  end

  defp object_name() do
    "optionCategoryWeight"
  end

  def list() do
    request = sample1()
    responses = [sample1(), sample2()]
    DocBuilder.list("optionCategoryWeights", request, responses, [:decision_id])
  end

  def get() do
    request = sample1()
    response = sample1()
    param_fields = [:decision_id, :id]
    DocBuilder.get(object_name(), request, response, param_fields)
  end

  def create() do
    query_field = "createOptionCategoryWeight"
    request = sample1()
    response = sample1()

    DocBuilder.create(query_field, request, response, object_name(), input_fields())
  end

  def update() do
    query_field = "updateOptionCategoryWeight"
    request = update1()
    response = update1()
    DocBuilder.update(query_field, request, response, object_name(), input_fields())
  end

  def delete() do
    query_field = "deleteOptionCategoryWeight"
    request = sample1()

    DocBuilder.delete(query_field, request, object_name(), "")
  end

end
