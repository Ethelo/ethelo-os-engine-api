defmodule GraphQL.EtheloApi.Docs.Variable do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  alias EtheloApi.Structure.Docs.Variable, as: VariableDocs
  alias GraphQL.DocBuilder

  defp sample1() do
    Map.get(VariableDocs.examples(), "Total Cost")
  end

  defp sample2() do
    Map.get(VariableDocs.examples(), "Average Cost")
  end

  defp sample3() do
    Map.get(VariableDocs.examples(), "Count Vegetarian")
  end

  defp update1() do
    VariableDocs.examples() |> Map.get("Grand Total Cost") |> Map.put(:id, sample1().id)
  end

  defp update2() do
    VariableDocs.examples() |> Map.get("Count All Vegetarian") |> Map.put(:id, sample3().id)
  end

  defp input_fields() do
    [:slug, :method, :option_detail_id, :option_filter_id, :title]
  end

  defp object_name() do
    "variable"
  end

  def list() do
    request = sample1()
    responses = [sample1(), sample2()]
    DocBuilder.list("variables", request, responses, [:decision_id])
  end

  def get() do
    request = sample1()
    response = sample1()
    param_fields = [:decision_id, :id]
    DocBuilder.get(object_name(), request, response, param_fields)
  end

  def create_detail_variable() do
    query_field = "createDetailVariable"
    input_fields = input_fields() |> List.delete([:option_filter_id])
    request = sample1()
    response = sample1()

    DocBuilder.create(query_field, request, response, object_name(), input_fields)
  end

  def update_detail_variable() do
    query_field = "updateDetailVariable"
    input_fields = input_fields() |> List.delete([:option_filter_id])
    request = update1()
    response = update1()
    DocBuilder.update(query_field, request, response, object_name(), input_fields)
  end

  def create_filter_variable() do
    query_field = "createFilterVariable"
    input_fields = input_fields() |> List.delete([:option_detail_id])
    request = sample3()
    response = sample3()

    DocBuilder.create(query_field, request, response, object_name(), input_fields)
  end

  def update_filter_variable() do
    query_field = "updateFilterVariable"
    input_fields = input_fields() |> List.delete([:option_detail_id])
    request = update2()
    response = update2()
    DocBuilder.update(query_field, request, response, object_name(), input_fields)
  end

  def delete() do
    query_field = "deleteVariable"
    request = sample1()
    comment = "You cannot detail a Variable that is used by a Calculation."

    DocBuilder.delete(query_field, request, object_name(), comment)
  end

end
