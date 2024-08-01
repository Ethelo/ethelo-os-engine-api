defmodule EtheloApi.Graphql.Docs.Calculation do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  alias EtheloApi.Structure.Docs.Calculation, as: CalculationDocs
  alias EtheloApi.Graphql.QueryHelper

  defp input_fields() do
    [
      :slug,
      :display_hint,
      :public,
      :expression,
      :personal_results_title,
      :title,
      :sort
    ]
  end

  defp sample1() do
    Map.get(CalculationDocs.examples(), "Variable Display")
  end

  defp sample2() do
    Map.get(CalculationDocs.examples(), "Simple Math")
  end

  defp update1() do
    CalculationDocs.examples() |> Map.get("Negative Number") |> Map.put(:id, sample1().id)
  end

  def list() do
    QueryHelper.query_example(
      "calculations",
      sample1() |> Map.take([:decision_id]),
      Map.keys(sample1()),
      [sample1(), sample2()],
      "List matching Calculations"
    )
  end

  @spec create() :: String.t()
  def create() do
    params = QueryHelper.mutation_params(sample1(), input_fields())

    QueryHelper.mutation_example(
      "createCalculation",
      params,
      Map.keys(sample1()),
      sample1(),
      "Add an Calculation"
    )
  end

  @spec update() :: String.t()
  def update() do
    params = QueryHelper.mutation_params(update1(), input_fields())

    QueryHelper.mutation_example(
      "updateCalculation",
      params,
      Map.keys(sample1()),
      update1(),
      "Update an Calculation"
    )
  end

  @spec delete() :: String.t()
  def delete() do
    params = QueryHelper.mutation_params(sample1(), [:decision_id, :id])
    comment = "Delete a Calculation."

    QueryHelper.delete_mutation_example(
      "deleteCalculation",
      params,
      [:id],
      sample1() |> Map.take([:id]),
      comment
    )
  end
end
