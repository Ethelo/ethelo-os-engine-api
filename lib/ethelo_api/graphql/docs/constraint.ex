defmodule EtheloApi.Graphql.Docs.Constraint do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  # TODO add inline queries
  alias EtheloApi.Structure.Docs.Constraint, as: ConstraintDocs
  alias EtheloApi.Graphql.QueryHelper

  def input_fields() do
    [
      :calculation_id,
      :enabled,
      :lhs,
      :operator,
      :option_filter_id,
      :relaxable,
      :rhs,
      :slug,
      :title,
      :variable_id
    ]
  end

  defp sample1() do
    Map.get(ConstraintDocs.examples(), "Equal To")
  end

  defp sample2() do
    Map.get(ConstraintDocs.examples(), "Between")
  end

  defp update1() do
    ConstraintDocs.examples()
    |> Map.get("Greater Than or Equal To")
    |> Map.put(:id, sample1().id)
  end

  @spec list() :: String.t()
  def list() do
    QueryHelper.query_example(
      "constraints",
      sample1() |> Map.take([:decision_id]),
      Map.keys(sample1()),
      [sample1(), sample2()],
      "List matching Constraints"
    )
  end

  @spec create() :: String.t()
  def create() do
    params = QueryHelper.mutation_params(sample1(), input_fields())

    QueryHelper.mutation_example(
      "createConstraint",
      params,
      Map.keys(sample1()),
      sample1(),
      "Create a Constraint"
    )
  end

  @spec update() :: String.t()
  def update() do
    params = QueryHelper.mutation_params(update1(), input_fields())

    QueryHelper.mutation_example(
      "updateConstraint",
      params,
      Map.keys(update1()),
      update1(),
      "Update a Constraint"
    )
  end

  @spec delete() :: String.t()
  def delete() do
    params = QueryHelper.mutation_params(sample1(), [:decision_id, :id])
    comment = "Delete a Constraint."

    QueryHelper.delete_mutation_example(
      "deleteConstraint",
      params,
      [:id],
      sample1() |> Map.take([:id]),
      comment
    )
  end
end
