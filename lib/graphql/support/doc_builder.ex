defmodule GraphQL.DocBuilder do
  @moduledoc """
  Generates example graphql queries
  """

  import DocsComposer.GraphQLQueryBuilder

  def list(query_field, request, responses, param_fields, comment \\ "") do
    params = Map.take(request, param_fields)
    comment = if comment == "", do: "List matching #{query_field}.", else: comment

    comment <> query_example(query_field, params, request, responses)
  end

  def get(query_field, request, response, param_fields) do
    params = Map.take(request, param_fields)
    "Get #{query_field} matching params."
    <>  query_example(query_field, params, request, response)
  end

  def create(query_field, request, response, object_name, input_fields) do
    create_fields = Map.take(request, input_fields)
    params = request
      |> Map.take([:decision_id])
      |> Map.put(object_name, create_fields)

    "Add an #{object_name}.\n\n"
    <> mutation_example(query_field, params, request, response)
  end

  def upsert(query_field, request, response, object_name, input_fields) do
    upsert_fields = Map.take(request, input_fields)
    params = request
      |> Map.take([:decision_id])
      |> Map.put(object_name, upsert_fields)

    "Upsert an #{object_name}.\n\n"
    <> mutation_example(query_field, params, request, response)
  end


  def copy(query_field, request, response, object_name, input_fields) do
    create_fields = Map.take(request, input_fields)
    params = request
      |> Map.take([:decision_id])
      |> Map.put(object_name, create_fields)

    "Add an #{object_name}.\n\n"
    <> mutation_example(query_field, params, request, response)
  end

  def create_params(query_field, request, response, object_name, param_fields) do
    params = request |> Map.take(param_fields)

    "Add an #{object_name}.\n\n"
    <> mutation_example(query_field, params, request, response)
  end

  def update(query_field, request, response, object_name, input_fields) do
    update_fields = Map.take(request, input_fields)

    params = request
      |> Map.take([:decision_id, :id])
      |> Map.put(object_name, update_fields)

    "Update an existing #{object_name}. updatedAt will be automatically updated when you make changes.\n\n"
    <> mutation_example(query_field, params, request, response)
  end

  def update_params(query_field, request, response, object_name, param_fields) do
    params = request |> Map.take(param_fields)

    "Update an existing #{object_name}. updatedAt will be automatically updated when you make changes.\n\n"
    <> mutation_example(query_field, params, request, response)
  end

  def delete(query_field, request, object_name, comment) do
    params = request |> Map.take([:decision_id, :id])
    response = request |> Map.take([:id])

    """
    Delete an existing #{object_name}. #{comment}

    THIS CANNOT BE UNDONE!
    """
    <> delete_mutation_example(query_field, params, response, response)
  end

  def delete_params(query_field, request, object_name, param_fields, comment) do
    params = request |> Map.take(param_fields)

    """
    Delete an existing #{object_name}. #{comment}

    THIS CANNOT BE UNDONE!
    """
    <> delete_mutation_example(query_field, params, params, params)
  end

  def format_example(query, response) do
    "Example:\n```\n#{query}\n```\n\nreturns\n```\n#{response}\n```"
  end

  def format_delete_example(query, response_found, response_null) do
    "Example:\n```\n#{query}\n```\n\nreturns\n```\n#{response_found}\n```
    or, when deleting a nonexistent record:\n```\n#{response_null}\n```"
  end

  def query_example(query_field, params, requested_fields, responses) do
    query = simple_query(query_field, params, requested_fields)
    response = query_response(query_field, responses)
    format_example(query, response)
  end

  def mutation_example(query_field, params, requested_fields, response) do
    query = simple_mutation(query_field, params, requested_fields)
    response = query_response(query_field, response)
    format_example(query, response)
  end

  def delete_mutation_example(query_field, params, requested_fields, response) do
    query = simple_mutation(query_field, params, requested_fields)
    response_found = query_response(query_field, response)
    response_null = query_response(query_field, "null")
    format_delete_example(query, response_found, response_null)
  end



end
