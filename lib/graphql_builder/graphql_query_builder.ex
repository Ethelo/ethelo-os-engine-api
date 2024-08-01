defmodule GraphqlBuilder do
  @moduledoc """
  Generates example graphql queries
  """

  import GraphqlBuilder.GraphqlFragmentBuilder
  import GraphqlBuilder.GraphqlPretty, only: [to_pretty_query: 1]

  @doc """
  Converts example query params and requested fields into a formatted Graphql Query.
  Does not support any nesting

  ## Examples

      iex> query("decisions", {decision_id: 1}, [:id])
      "{ decisions (  decisionId: 1 ){ id } }"

  """
  @spec simple_query(String.t(), map(), list(String.t() | atom())) :: String.t()
  def simple_query(query_field, params, requested_fields) do
    requested = simple_fields(requested_fields)
    params = to_graphql_params(params)

    query = ~s[
    {
      #{query_field} (
        #{params}
      )
      {
        #{requested}
      }
    }
    ]

    query |> to_pretty_query()
  end

  @doc """
  Converts example query inputs and requested fields into a formatted Graphql Mutation Query.
  Does not support any nesting

  ## Examples

      iex> query("updateDecision", {decision_id: 1, id: 12, title: "Foo"}, [:id, :successful])
      "{ decisions ( decisionId: 1, id: 12, title: "Foo" ){ id successful } }"
  """
  @spec simple_mutation(String.t(), map(), list(String.t() | atom())) :: String.t()
  def simple_mutation(query_field, params, requested_fields) do
    requested = simple_fields(requested_fields)
    params = to_graphql_params(params)

    query = ~s[
    mutation {
      #{query_field} (

          #{params}

      )
      {
        #{requested}
      }
    }
    ]

    query |> to_pretty_query()
  end

  @spec mutation_params(String.t() | atom(), map(), list()) :: map()
  def mutation_params(input_name \\ :input, request, input_fields) do
    mutation_values = Map.take(request, input_fields ++ [:decision_id])
    Map.put(%{}, input_name, mutation_values)
  end

  def build_query(field_definition, mode \\ :raw) when is_list(field_definition) do
    query = build_fields(field_definition)

    case mode do
      :pretty -> to_pretty_query(query)
      :condensed -> strip_starting_whitespace(query)
      _ -> query
    end
  end

  @spec query_response(String.t(), list(map()) | nil | map()) :: String.t()
  def query_response(query_field, nil) do
    ~s[
    {
      "data":
        "#{query_field}": null
    }
    ]
  end

  def query_response(query_field, content) when is_list(content) do
    responses =
      content
      |> Enum.map(&to_graphql_response/1)
      |> Enum.map_join(",", &add_braces/1)

    ~s|
    {
      "data": {
        "#{query_field}": [#{responses}]
      }
    }
    |
    |> to_pretty_query()
  end

  def query_response(query_field, content) when is_map(content) do
    response = to_graphql_response(content)

    ~s|
    {
      "data": {
        "#{query_field}": #{response}
      }
    }
    |
    |> to_pretty_query()
  end
end
