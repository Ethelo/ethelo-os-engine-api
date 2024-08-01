defmodule GraphQL.EtheloApi.Docs.OptionCategory do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  alias EtheloApi.Structure.Docs.OptionCategory, as: OptionCategoryDocs
  alias GraphQL.DocBuilder

  defp sample1() do
    Map.get(OptionCategoryDocs.examples, "Default")
  end

  defp sample2() do
    Map.get(OptionCategoryDocs.examples, "Food")
  end

  defp update1() do
    Map.get(OptionCategoryDocs.examples(), "Drink")
  end

  def input_fields() do
    [:slug, :info, :keywords, :title, :weighting, :sort, :vote_on_percent,
     :budget_percent, :flat_fee, :quadratic, :results_title]
  end

  defp object_name() do
    "optionCategory"
  end

  def list() do
    request = sample1()
    responses = [sample1(), sample2()]
    DocBuilder.list("optionCategories", request, responses, [:decision_id])
  end

  def get() do
    request = sample1()
    response = sample1()
    param_fields = [:decision_id, :id]
    DocBuilder.get(object_name(), request, response, param_fields)
  end

  def create() do
    query_field = "createOptionCategory"
    request = sample1()
    response = sample1()

    DocBuilder.create(query_field, request, response, object_name(), input_fields())
  end

  def update() do
    query_field = "updateOptionCategory"
    request = update1()
    response = update1()
    DocBuilder.update(query_field, request, response, object_name(), input_fields())
  end

  def delete() do
    query_field = "deleteOptionCategory"
    request = sample1()
    comment = "Cannot be deleted if there are Options assigned."

    DocBuilder.delete(query_field, request, object_name(), comment)
  end

end
