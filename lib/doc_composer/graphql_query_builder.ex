defmodule DocsComposer.GraphQLQueryBuilder do
  @moduledoc """
  Generates example graphql queries
  """

  import DocsComposer.GraphQLFragmentBuilder
  import DocsComposer.GraphQLPretty

  def simple_query(query_field, params, requested_fields) do
    requested = keys_as_graphql(requested_fields)
    params = to_graphql_params_fragment(params)

    string = """
    {\n#{query_field}(\n#{params}\n)\n{ #{requested}\n}\n}
    """
    string |> to_pretty_string()
  end

  def simple_mutation(query_field, params, requested_fields) do
    "mutation" <> simple_query(query_field, params, requested_fields)
  end

  def query_response(query_field, response) do
    response
    |> wrap_query_response(query_field)
    |> wrap_data()
    |> to_pretty_string()
  end

end
