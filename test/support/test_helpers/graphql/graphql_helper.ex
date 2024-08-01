defmodule EtheloApi.TestHelper.GraphqlHelper do
  @moduledoc """
  Generic helpers used in model tests
  """

  import ExUnit.Assertions

  import AbsintheErrorPayload.TestHelper
  import EtheloApi.Graphql.QueryHelper

  def evaluate_graphql(query, options \\ []) do
    Absinthe.run(query, EtheloApi.Graphql.Schema, options)
  end

  def evaluate_query_graphql(query, query_field, options \\ []) do
    response = evaluate_graphql(query, options)

    {:ok, %{data: data}} = response
    get_in(data, ["decision", query_field])
  end

  def evaluate_mutation_query(query, query_field, options \\ []) do
    response = evaluate_graphql(query, options)

    case response do
      {:ok, %{errors: errors}} -> errors
      {:ok, %{data: data}} -> Map.get(data, query_field)
    end
  end

  def assert_list_one_query(query_field, to_match, param_fields \\ [:id], compare_fields) do
    params = to_match |> Map.take(param_fields)

    query =
      decision_child_query(
        query_field,
        to_match.decision_id,
        params,
        Map.keys(compare_fields)
      )

    # |> inspect_string()

    result_list = evaluate_query_graphql(query, query_field)
    assert [result] = result_list

    assert_equivalent_graphql(to_match, result, compare_fields)
  end

  def assert_list_none_query(query_field, to_match, param_fields \\ [:id]) do
    params = to_match |> Map.take(param_fields)

    query =
      decision_child_query(
        query_field,
        to_match.decision_id,
        params,
        param_fields
      )

    result_list = evaluate_query_graphql(query, query_field)
    assert [] == result_list
  end

  def assert_list_many_query(
        query_field,
        decision_id,
        request_params,
        match_list,
        compare_fields
      ) do
    query =
      decision_child_query(query_field, decision_id, request_params, Map.keys(compare_fields))

    result_list = evaluate_query_graphql(query, query_field)

    result_list = result_list |> Enum.sort_by(&Map.get(&1, "id"))

    assert_equivalent_graphql(match_list, result_list, compare_fields)
  end

  def assert_delete_success(expected, payload, %{} = fields) do
    assert %{"successful" => true} = payload
    refute nil == payload["result"]

    assert_equivalent_graphql(expected, payload["result"], fields)
  end

  def run_creation_query(query_field, decision_id, attrs, requested_fields) do
    requested_fields = requested_fields ++ [:id]
    params = attrs |> Map.take(requested_fields)

    query =
      decision_child_mutation(query_field, decision_id, params, requested_fields)

    # inspect_string(query)

    evaluate_mutation_query(query, query_field)
  end

  def run_mutate_one_query(query_field, decision_id, attrs, requested_fields \\ nil)

  def run_mutate_one_query(query_field, decision_id, attrs, nil) do
    requested_fields = Map.keys(attrs)
    run_mutate_one_query(query_field, decision_id, attrs, requested_fields)
  end

  def run_mutate_one_query(query_field, decision_id, attrs, requested_fields)
      when is_list(requested_fields) do
    query =
      decision_child_mutation(query_field, decision_id, attrs, requested_fields)

    #  inspect_string(query)

    evaluate_mutation_query(query, query_field)
  end

  @spec clean_map(struct() | map()) :: map()
  @doc """
  Convert a single struct / ecto schema to a simple map
  with no meta data for easier comparision
  (simplifies test output)
  """
  def clean_map(%_{} = struct) do
    struct |> Map.from_struct() |> clean_map
  end

  def clean_map(%{} = map) do
    invalid_fields =
      map
      |> Enum.map(fn
        {k, %Ecto.Association.NotLoaded{}} -> k
        {k, v} when is_struct(v) -> k
        {k, _} -> if String.starts_with?("#{k}", "__"), do: k, else: nil
      end)
      |> Enum.reject(&is_nil(&1))

    Map.drop(map, invalid_fields)
  end

  def inspect_string(string, label \\ "") do
    IO.puts(label)
    IO.puts(string)
    string
  end
end
