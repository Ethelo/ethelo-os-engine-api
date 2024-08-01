defmodule DocsComposer.GraphQLFragmentBuilder do
  @moduledoc """
  Tools to generate GraphQL query fragments
  """

  import DocsComposer.Utility

  @doc """
  convert a map of fields to a string keyed json fragment
  """
  def to_graphql_response_fragment(%{} = example) do
    example
    |> camelize_keys
    |> fields_to_text(fn({k, v}) -> "\"#{k}\": \"#{v}\"," end)
    |> String.trim(",")
    |> wrap_with_newlines
  end

  @doc """
  convert a map of fields to a new line separated list of field names
  """
  def keys_as_graphql(example) do
    example |> camelize_keys |> fields_to_text(fn({k, _v}) -> "#{k}" end) |> wrap_with_newlines
  end

  @doc """
  convert a map of fields to a graphql mutation format

  In a mutation, field names are camelCased and fields are separated with newlines.
  Graphql does not require commas between arguments
  """
  def to_graphql_mutation_fragment(%{} = example) do
    example
    |> camelize_keys
    |> fields_to_text(fn({k, v}) -> "#{k}: \"#{v}\"" end)
    |> wrap_with_newlines
  end

  @doc """
  convert a map of fields to a graphql params format

  keys are camelize, and non-numeric values are surround by quotes
  """
  def to_graphql_params_fragment(%{} = params) do
    params
    |> camelize_keys
    |> fields_to_text(fn
      ({k, v}) when is_map(v) -> "#{k}: { #{to_graphql_params_fragment(v)} }"
      ({k, v}) when is_integer(v) or is_float(v) -> "#{k}: #{v} "
      ({k, v}) -> "#{k}: \"#{v}\" "
    end)
    |> wrap_with_newlines
  end

  @doc """
  wrap a string of content in a named mutation block
  """
  def wrap_mutation_response("null", mutation) do
    "\"#{mutation}\": null" |> wrap_data
  end

  def wrap_mutation_response(content, mutation) do
    "\"#{mutation}\": { #{content} }" |> wrap_data
  end

  @doc """
  wrap a string of content in a named query block
  """
  def wrap_query_response("null", query) do
    "\"#{query}\": null"
  end

  def wrap_query_response(content, query) when is_map(content) do
    content = to_graphql_response_fragment(content)
    wrap_query_response(content, query)
  end

  def wrap_query_response(content, query) when is_list(content) do
    items = content
      |> Enum.map(&to_graphql_response_fragment/1)
      |> Enum.map(&add_braces/1)
      |> Enum.join(",")

    "\"#{query}\": [\n#{items}\n]"
  end

  def wrap_query_response(content, query) do
    "\"#{query}\": { #{content} }"
  end

  @doc """
  wrap supplied content string in a json object with a "data" key

  Absinthe Graphql responses are always wrapped in a data object
  """
  def wrap_data("null") do
    "{\"data\": null}"
  end

  def wrap_data(content) do
    "{\"data\": { #{content} } }"
  end

  defp wrap_with_newlines(content), do: "\n#{content}\n"

  defp add_braces(content) do
    "{ #{content} }"
  end

  @doc """
  wrap a string of content in a named input object block
  """
  def wrap_input_object(content, input_object) do
    "\"#{input_object}\": { #{content} }"
  end

end
