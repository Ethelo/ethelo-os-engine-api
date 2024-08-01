defmodule GraphQL.EtheloApi.Docs.OptionDetail do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  alias EtheloApi.Structure.Docs.OptionDetail, as: OptionDetailDocs
  alias GraphQL.DocBuilder

  defp sample1() do
    Map.get(OptionDetailDocs.examples(), "Money")
  end

  defp sample2() do
    Map.get(OptionDetailDocs.examples(), "Boolean")
  end

  defp update1() do
    OptionDetailDocs.examples() |> Map.get("Percent") |> Map.put(:id, sample1().id)
  end

  def input_fields() do
    [:slug, :input_hint, :display_hint, :public, :format, :title, :sort]
  end

  defp object_name() do
    "optionDetail"
  end

  def list() do
    request = sample1()
    responses = [sample1(), sample2()]
    DocBuilder.list("optionDetails", request, responses, [:decision_id])
  end

  def get() do
    request = sample1()
    response = sample1()
    param_fields = [:decision_id, :id]
    DocBuilder.get(object_name(), request, response, param_fields)
  end

  def create() do
    query_field = "createOptionDetail"
    request = sample1()
    response = sample1()

    DocBuilder.create(query_field, request, response, object_name(), input_fields())
  end

  def update() do
    query_field = "updateOptionDetail"
    request = update1()
    response = update1()
    DocBuilder.update(query_field, request, response, object_name(), input_fields())
  end

  def delete() do
    query_field = "deleteOptionDetail"
    request = sample1()
    comment = "All associated OptionDetailValues will also be removed."

    DocBuilder.delete(query_field, request, object_name(), comment)
  end

end
