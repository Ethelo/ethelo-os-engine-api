defmodule EtheloApi.Graphql.QueryHelper do
  @moduledoc """
  Generates example graphql queries
  """

  import GraphqlBuilder, except: [mutation_params: 3, mutation_params: 2]
  import GraphqlBuilder.GraphqlPretty, only: [to_pretty_query: 1]

  defdelegate mutation_params(input_name \\ :input, request, input_fields),
    to: GraphqlBuilder

  defdelegate to_graphql_params(params),
    to: GraphqlBuilder.GraphqlFragmentBuilder

  defdelegate simple_fields(requested_fields),
    to: GraphqlBuilder.GraphqlFragmentBuilder

  @spec format_as_example(String.t(), String.t(), String.t()) :: String.t()
  def format_as_example(query, response, comment) do
    ~s[
  #{comment}

  Example:
  ```
  #{query}
  ```
  returns

  ```
  #{response}
  ```
  ] |> String.trim()
  end

  @spec query_example(String.t(), map(), list(), list(map()), String.t()) :: String.t()
  def query_example(query_field, params, requested_fields, responses, comment \\ "") do
    decision_id = Map.get(params, :decision_id)
    params = Map.delete(params, :decision_id)
    query = decision_child_query(query_field, decision_id, params, requested_fields)
    response = query_response(query_field, responses)
    format_as_example(query, response, comment)
  end

  @spec simple_query_example(String.t(), map(), list(), list(map()), String.t()) :: String.t()
  def simple_query_example(query_field, params, requested_fields, responses, comment \\ "") do
    query = simple_query(query_field, params, requested_fields)
    response = query_response(query_field, responses)
    format_as_example(query, response, comment)
  end

  @spec mutation_example(String.t(), map(), list(), map() | nil, String.t()) :: String.t()
  def mutation_example(query_field, params, requested_fields, response, comment \\ "") do
    decision_id = Map.get(params, :decision_id)
    params = Map.delete(params, :decision_id)
    query = decision_child_mutation(query_field, decision_id, params, requested_fields)
    response = query_response(query_field, response)
    format_as_example(query, response, comment)
  end

  @spec simple_mutation_example(String.t(), map(), list(), map(), String.t()) :: String.t()
  def simple_mutation_example(query_field, params, requested_fields, response, comment \\ "") do
    query = simple_mutation(query_field, params, requested_fields)
    response = query_response(query_field, response)
    format_as_example(query, response, comment)
  end

  @spec delete_mutation_example(String.t(), map(), list(), map(), String.t()) :: String.t()
  def delete_mutation_example(query_field, params, requested_fields, response, comment) do
    decision_id = Map.get(params, :decision_id)
    params = Map.delete(params, :decision_id)
    query = decision_child_mutation(query_field, decision_id, params, requested_fields)

    format_as_delete_mutation(query, query_field, response, comment)
  end

  @spec simple_delete_mutation_example(String.t(), map(), list(), map(), String.t()) :: String.t()
  def simple_delete_mutation_example(query_field, params, requested_fields, response, comment) do
    query = simple_mutation(query_field, params, requested_fields)
    format_as_delete_mutation(query, query_field, response, comment)
  end

  def format_as_delete_mutation(query, query_field, response, comment) do
    response_found = query_response(query_field, response)
    response_null = query_response(query_field, nil)
    ~s[
#{comment}

Example:
```
#{query}
```

returns
```
#{response_found}
```
or, when deleting a nonexistent record:

```
#{response_null}
```"
    ] |> String.trim()
  end

  def decision_child_query(query_field, decision_id, params, requested_fields)
      when params == %{} do
    fields = simple_fields(requested_fields)
    ~s[
        {
          decision(
            decisionId: #{decision_id}
          )
          {
            #{query_field}{
              #{fields}
            }
          }
        }
      ] |> to_pretty_query()
  end

  def decision_child_query(query_field, decision_id, params, requested_fields) do
    fields = simple_fields(requested_fields)
    params = to_graphql_params(params)
    ~s[
        {
          decision(
            decisionId: #{decision_id}
          )
          {
            #{query_field}(
              #{params}
            ){
              #{fields}
            }
          }
        }
      ] |> to_pretty_query()
  end

  def decision_child_mutation(query_field, decision_id, params, requested_fields) do
    fields = simple_fields(requested_fields)

    params = params |> Map.put(:decision_id, decision_id) |> to_graphql_params()

    ~s[
        mutation{
          #{query_field}(
            input: {
              #{params}
            }
          ){
            successful
            messages {
              field
              message
              code
            }
            result {
              #{fields}
            }
          }
        }
      ] |> to_pretty_query()
  end

  # def meta_segment(include \\ [:message, :field, :code]) do
  #   message_fields =
  #     if :options in include do
  #       include ++ [%{name: :options, fields: [:key, :value]}]
  #     else
  #       include
  #     end

  #   %{
  #     name: :meta,
  #     fields: [
  #       :successful,
  #       %{
  #         name: :messages,
  #         fields: message_fields
  #       }
  #     ]
  #   }
  # end
end

#     decision(
#         decisionId: $decision_id
#       )
#       {
#         meta{
#           ...EtheloApi::Fragments::META_FRAGMENT
#         }
#         scenarioSets(
#          participantId: $participant_id
#          cachedDecision: true
#          id: $scenario_set_id
#         ) {
#           id
#           error
#           status
#           insertedAt
#           published:cachedDecision
#           updatedAt
#           engineStart
#           engineEnd
#           solveDump @include(if: $full_dump){
#             ...EtheloApi::Fragments::SOLVE_DUMP_FRAGMENT
#            }
#            dumpId:solveDump{
#               id
#            }
#           scenarioConfigId
#           scenarioCount: count(status: "success", global: false)
#         }
#       }
#     }

# def temp do
#   request = %{
#     decision: %{
#       args: %{decision_id: 1},
#       fields: [
#         :slug,
#         %{field: :options, args: %{slug: "foo"}, fields: [:slug]}
#       ]
#     }
#   }

#   query = """
#     {
#       decision(
#         decisionId: 1
#       )
#       {
#         options(
#           slug: "foo"
#         ){
#           slug
#         }
#       }
#     }
#   """

#   request = [
#     %{
#       name: :decision,
#       args: %{decision_id: 1},
#       fields: [
#         meta_segment(),
#         %{
#           name: :scenario_sets,
#           args: %{participant_id: 1, cached_decision: true, scenario_set_id: 1},
#           fields: [
#             :id,
#             :error,
#             :status,
#             :scenario_config_id,
#             %{name: :solve_dump, fields: [:id, :scenario_set_id, :error]},
#             %{name: :count, args: %{status: "success", global: false}}
#           ]
#         }
#       ]
#     }
#   ]
# end
