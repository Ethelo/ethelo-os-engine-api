defmodule EtheloApi.Graphql.Docs.Variable do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """

  # TODO add inline queries

  alias EtheloApi.Structure.Docs.Variable, as: VariableDocs
  alias EtheloApi.Graphql.QueryHelper

  def input_fields() do
    [
      :slug,
      :method,
      :option_detail_id,
      :option_filter_id,
      :title
    ]
  end

  defp sample1() do
    Map.get(VariableDocs.examples(), "Total Cost")
  end

  defp sample2() do
    Map.get(VariableDocs.examples(), "Average Cost")
  end

  defp sample3() do
    Map.get(VariableDocs.examples(), "Count Vegetarian")
  end

  defp update1() do
    VariableDocs.examples() |> Map.get("Grand Total Cost") |> Map.put(:id, sample1().id)
  end

  defp update2() do
    VariableDocs.examples() |> Map.get("Count All Vegetarian") |> Map.put(:id, sample3().id)
  end

  @spec list() :: String.t()
  def list() do
    QueryHelper.query_example(
      "variables",
      sample1() |> Map.take([:decision_id]),
      Map.keys(sample1()),
      [sample1(), sample2()],
      "List matching Variables"
    )
  end

  @spec create_detail_variable() :: String.t()
  def create_detail_variable() do
    input_fields = input_fields() |> List.delete([:option_filter_id])

    params = QueryHelper.mutation_params(sample1(), input_fields)

    QueryHelper.mutation_example(
      "createDetailVariable",
      params,
      Map.keys(sample1()),
      sample1(),
      "Add Variable using an OptionDetail"
    )
  end

  @spec update_detail_variable() :: String.t()
  def update_detail_variable() do
    input_fields = input_fields() |> List.delete([:option_filter_id])

    params = QueryHelper.mutation_params(update1(), input_fields)

    QueryHelper.mutation_example(
      "updateDetailVariable",
      params,
      Map.keys(update1()),
      update1(),
      "Update a Variable using an OptionDetail"
    )
  end

  @spec create_filter_variable() :: String.t()
  def create_filter_variable() do
    input_fields = input_fields() |> List.delete([:option_detail_id])

    params = QueryHelper.mutation_params(sample3(), input_fields)

    QueryHelper.mutation_example(
      "createFilterVariable",
      params,
      Map.keys(sample3()),
      sample3(),
      "Add Variable using an OptionFilter"
    )
  end

  @spec update_filter_variable() :: String.t()
  def update_filter_variable() do
    input_fields = input_fields() |> List.delete([:option_detail_id])

    params = QueryHelper.mutation_params(update2(), input_fields)

    QueryHelper.mutation_example(
      "updateFilterVariable",
      params,
      Map.keys(update2()),
      update2(),
      "Update a Variable using an OptionFilter"
    )
  end

  @spec delete() :: String.t()

  def delete() do
    params = QueryHelper.mutation_params(sample1(), [:decision_id, :id])
    comment = "Delete a Variable.
    You cannot detail a Variable that is used by a Calculation.
    Default Variables will be automatically recreated."

    QueryHelper.delete_mutation_example(
      "deleteVariable",
      params,
      [:id],
      sample1() |> Map.take([:id]),
      comment
    )
  end
end
