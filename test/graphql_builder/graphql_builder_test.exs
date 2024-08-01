defmodule GraphqlBuilder.GraphqlBuilderTest do
  @moduledoc """
  Test methods used to generate graphql queries for testing and documentation
  """

  use ExUnit.Case
  alias GraphqlBuilder.GraphqlFragmentBuilder, as: FragmentBuilder

  def inspect_string(string, label \\ "") do
    IO.puts(label)
    IO.puts(string)
    string
  end

  def strip_extra_whitespace(str) do
    str
    |> String.split("\n", trim: true)
    |> Enum.map_join("\n", &String.trim/1)
    |> String.trim()
  end

  def assert_similar_query(expected, result) do
    assert strip_extra_whitespace(expected) == strip_extra_whitespace(result)
  end

  describe "builds parts" do
    test "builds example response" do
      example = %{two_words: "two words", number: 12, atom: :an_atom}

      generated = FragmentBuilder.to_graphql_response(example)
      expected = ~s[
        {
        "atom": AN_ATOM,
        "number": 12,
        "twoWords": "two words"
        }
      ]
      assert_similar_query(generated, expected)
    end

    test "builds simple field list" do
      requested_fields = [:two_words, :one, "stringval"]

      generated = FragmentBuilder.simple_fields(requested_fields)

      expected = ~s[
          one
          stringval
          twoWords
      ]
      assert_similar_query(generated, expected)
    end

    test "builds mutation parms" do
      example = %{two_words: "two words", number: 12, atom: :an_atom, boolean: false, null: nil}

      generated = FragmentBuilder.to_graphql_params(example)
      expected = ~s[
        atom: AN_ATOM
        boolean: false
        null: null
        number: 12
        twoWords: "two words"
      ]
      assert_similar_query(generated, expected)
    end
  end

  describe "builds queries" do
    test "simple query" do
      query_field = "simpleQuery"
      params = %{title: "Foo", id: 6, enabled: true}
      requested_fields = [:title, :enabled, :id]

      generated = GraphqlBuilder.simple_query(query_field, params, requested_fields)

      expected = ~s[
        {
          simpleQuery (
            enabled: true
            id: 6
            title: "Foo"
            ) {
              enabled
              id
              title
            }
        }
      ]
      assert_similar_query(generated, expected)
    end

    test "simple mutation" do
      request = %{id: 6, title: "Foo", enabled: false}

      params = GraphqlBuilder.mutation_params("simpleInput", request, [:title, :id])

      generated =
        GraphqlBuilder.simple_mutation("simpleMutation", params, [:title, :enabled, :id])

      expected = ~s[
        mutation {
          simpleMutation (
            simpleInput: {
              id: 6
              title: "Foo"
            }
          ) {
            enabled
            id
            title
          }
        }
      ]
      assert_similar_query(generated, expected)
    end
  end
end
