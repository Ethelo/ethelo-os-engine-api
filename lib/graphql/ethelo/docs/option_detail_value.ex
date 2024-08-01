defmodule GraphQL.EtheloApi.Docs.OptionDetailValue do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  alias EtheloApi.Structure.Docs.OptionDetailValue, as: OptionDetailValueDocs

  alias GraphQL.DocBuilder

  defp sample1() do
    Map.get(OptionDetailValueDocs.examples, "Sample 1")
  end

  defp update() do
    Map.get(OptionDetailValueDocs.examples, "Update 1")
  end

  defp object_name() do
    "optionDetailValue"
  end

  def create_option_detail_value() do
    query_field = "createOptionDetailValue"
    request = sample1()
    response = sample1()
    param_fields = [:decision_id, :option_id, :option_detail_id, :value]

    DocBuilder.create_params(query_field, request, response, object_name(), param_fields)
  end

  def update_option_detail_value() do
    query_field = "updateOptionDetailValue"
    request = update()
    response = update()
    param_fields = [:decision_id, :option_id, :option_detail_id, :value]

    DocBuilder.update_params(query_field, request, response, object_name(), param_fields)
  end

  def delete_option_detail_value() do
    query_field = "deleteOptionDetailValue"
    request = sample1()
    param_fields = [:decision_id, :option_id, :option_detail_id, :value]

    DocBuilder.delete_params(query_field, request, object_name(), param_fields, "")
  end
end
