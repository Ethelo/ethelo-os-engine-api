defmodule GraphQL.EtheloApi.Docs.Calculation do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  alias EtheloApi.Structure.Docs.Calculation, as: CalculationDocs
  alias GraphQL.DocBuilder

  defp sample1() do
    Map.get(CalculationDocs.examples(), "Variable Display")
  end

  defp sample2() do
    Map.get(CalculationDocs.examples(), "Simple Math")
  end

  defp update1() do
    CalculationDocs.examples() |> Map.get("Negative Number") |> Map.put(:id, sample1().id)
  end

  defp input_fields() do
    [:slug, :display_hint, :public, :expression, :personal_results_title, :title, :sort]
  end

  def object_name() do
    "calculation"
  end

  def list() do
    request = sample1()
    responses = [sample1(), sample2()]
    DocBuilder.list("calculations", request, responses, [:decision_id])
  end

  def get() do
    request = sample1()
    response = sample1()
    param_fields = [:decision_id, :id]
    DocBuilder.get(object_name(), request, response, param_fields)
  end

  def create() do
    query_field = "createCalculation"
    request = sample1()
    response = sample1()

    DocBuilder.create(query_field, request, response, object_name(), input_fields())
  end

  def update() do
    query_field = "updateCalculation"
    request = update1()
    response = update1()
    DocBuilder.update(query_field, request, response, object_name(), input_fields())
  end

  def delete() do
    query_field = "deleteCalculation"
    request = sample1()
    comment = "All associated CalculationValues will also be removed."

    DocBuilder.delete(query_field, request, object_name(), comment)
  end

end
