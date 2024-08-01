defmodule GraphQL.EtheloApi.Docs.OptionFilter do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  alias EtheloApi.Structure.Docs.OptionFilter, as: OptionFilterDocs
  alias GraphQL.DocBuilder

  defp sample1() do
    Map.get(OptionFilterDocs.examples(), "Sample 1")
  end

  defp sample2() do
    Map.get(OptionFilterDocs.examples(), "Sample 3")
  end

  defp sample3() do
    Map.get(OptionFilterDocs.examples(), "Sample 2")
  end

  defp update1() do
    Map.get(OptionFilterDocs.examples(), "Sample 1")
  end

  defp update2() do
    Map.get(OptionFilterDocs.examples(), "Sample 2")
  end

  def input_fields() do
    [:slug, :match_value, :match_mode, :option_detail_id, :option_category_id, :title, :weighting]
  end

  defp object_name() do
    "optionFilter"
  end

  def list() do
    request = sample1()
    responses = [sample1(), sample2()]
    DocBuilder.list("optionFilters", request, responses, [:decision_id])
  end

  def get() do
    request = sample1()
    response = sample1()
    param_fields = [:decision_id, :id]
    DocBuilder.get(object_name(), request, response, param_fields)
  end

  def create_option_detail_filter() do
    query_field = "createOptionDetailFilter"
    input_fields = input_fields() |> List.delete([:option_detail_id])
    request = sample1()
    response = sample1()

    DocBuilder.create(query_field, request, response, object_name(), input_fields)
  end

  def update_option_detail_filter() do
    query_field = "updateOptionDetailFilter"
    input_fields = input_fields() |> List.delete([:option_detail_id])
    request = update1()
    response = update1()
    DocBuilder.update(query_field, request, response, object_name(), input_fields)
  end

  def create_option_category_filter() do
    query_field = "createOptionCategoryFilter"
    input_fields = input_fields() |> List.delete([:option_category_id])
    request = sample3()
    response = sample3()

    DocBuilder.create(query_field, request, response, object_name(), input_fields)
  end

  def update_option_category_filter() do
    query_field = "updateOptionCategoryFilter"
    input_fields = input_fields() |> List.delete([:option_category_id])
    request = update2()
    response = update2()
    DocBuilder.update(query_field, request, response, object_name(), input_fields)
  end

  def delete() do
    query_field = "deleteOptionFilter"
    request = sample1()
    comment = "All associated OptionFilterValues will also be removed."

    DocBuilder.delete(query_field, request, object_name(), comment)
  end

end
