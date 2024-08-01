defmodule EtheloApi.Graphql.QueryHelperTest do
  @moduledoc """
    Test methods used to generate graphql queries for testing and documentation
  """

  use ExUnit.Case
  alias EtheloApi.Graphql.QueryHelper

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

  describe "builds queries" do
    test "decision_child_query" do
      query_field = "options"

      requested_fields = [:title, :enabled, :id]

      generated =
        QueryHelper.decision_child_query(query_field, 1, %{id: 6}, requested_fields)

      #  |> inspect_string("generated")

      expected =
        ~s[
        {
          decision (
            decisionId: 1
          ) {
            options (
              id: 6
            ) {
              enabled
              id
              title
            }
          }
        }
      ]

      #   |> inspect_string("expected")

      assert_similar_query(generated, expected)
    end

    test "decision_child_mutation" do
      request = %{id: 6, title: "Foo", enabled: false}

      generated =
        QueryHelper.decision_child_mutation("updateOption", 1, request, [:title, :enabled, :id])

      #  |> inspect_string("generated")

      expected =
        ~s[
        mutation {
          updateOption (
            input: {
              decisionId: 1
              enabled: false
              id: 6
              title: "Foo"
            }
          ) {
            successful
            messages {
              field
              message
              code
            }
            result {
              enabled
              id
              title
            }
          }
        }
      ]

      #  |> inspect_string("expected")

      assert_similar_query(generated, expected)
    end
  end
end
