defmodule GraphQL.EtheloApi.Docs.Decision do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  alias EtheloApi.Structure.Docs.Decision, as: DecisionDocs
  alias GraphQL.DocBuilder

  defp sample1() do
    Map.get(DecisionDocs.examples, "Sample 1")
  end

  defp sample1_copy() do
    Map.get(DecisionDocs.examples, "Sample 1")
    |> Map.put(:id, 2)
  end

  defp sample2() do
    Map.get(DecisionDocs.examples, "Sample 2")
  end

  defp update1() do
    Map.get(DecisionDocs.examples(), "Update 1")
  end

  def input_fields() do
    [:info, :slug, :title, :copyable, :internal, :max_users, :language, :keywords]
  end

  def object_name() do
    "decision"
  end

  def list() do
    request = sample1()
    responses = [sample1(), sample2()]
    DocBuilder.list("decisions", request, responses, [])
  end

  def get() do
    request = sample1()
    response = sample1()
    param_fields = [:id]
    DocBuilder.get(object_name(), request, response, param_fields)
  end

  def create() do
    query_field = "createDecision"
    request = sample1()
    response = sample1()

    DocBuilder.create(query_field, request, response, object_name(), input_fields())
  end

  def import() do
    query_field = "importDecision"
    request = sample1()
    response = sample1()

    DocBuilder.copy(query_field, request, response, object_name(), input_fields() ++ [:export])
  end

  def update() do
    query_field = "updateDecision"
    request = update1()
    response = update1()
    DocBuilder.update(query_field, request, response, object_name(), input_fields())
  end

  def copy() do
    query_field = "copyDecision"
    request = sample1()
    response = sample1_copy()

    DocBuilder.copy(query_field, request, response, object_name(), input_fields() ++ [:id])
  end

  def delete() do
    query_field = "deleteDecision"
    request = sample1()
    comment = "All associated data will also be removed."

    DocBuilder.delete(query_field, request, object_name(), comment)
  end

end
