defmodule GraphQL.EtheloApi.Docs.Constraint do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  alias EtheloApi.Structure.Docs.Constraint, as: ConstraintDocs
  alias GraphQL.DocBuilder

  def alias_fields(example) do
    example
    |> Map.get(:operator)
    |> case do
        :between -> example
          |> Map.put(:between_low, example.lhs)
          |> Map.put(:between_high, example.rhs)
        _ ->
          Map.put(example, :value, example.rhs)
      end
    |> Map.drop([:lhs, :rhs])
  end

  defp sample1() do
    ConstraintDocs.examples() |> Map.get("Equal To") |> alias_fields()
  end

  defp sample2() do
    ConstraintDocs.examples() |> Map.get("Between") |> alias_fields()
  end

  defp update1() do
    ConstraintDocs.examples() |> Map.get("Greater Than or Equal To") |> Map.put(:id, sample1().id) |> alias_fields()
  end

  defp update2() do
    ConstraintDocs.examples() |> Map.get("Between") |> Map.put(:id, sample2().id) |> alias_fields()
  end

  defp input_fields() do
    [:enabled, :relaxable, :title, :slug, :variable_id, :calculation_id, :option_filter_id]
  end

  defp single_boundary_input_fields() do
    [:value, :operator] ++ input_fields()
  end

  defp between_input_fields() do
    [:between_high, :between_low] ++ input_fields()
  end

  defp object_name() do
    "constraint"
  end

  def list() do
    request = sample1()
    responses = [sample1(), sample2()]
    DocBuilder.list("constraints", request, responses, [:decision_id])
  end

  def get() do
    request = sample1()
    response = sample1()
    param_fields = [:decision_id, :id]
    DocBuilder.get(object_name(), request, response, param_fields)
  end

  def create_single_boundary_constraint() do
    query_field = "createSingleBoundaryConstraint"
    input_fields = single_boundary_input_fields()
    request = sample1()
    response = sample1()

    DocBuilder.create(query_field, request, response, object_name(), input_fields)
  end

  def update_single_boundary_constraint() do
    query_field = "updateSingleBoundaryConstraint"
    input_fields = single_boundary_input_fields()
    request = update1()
    response = update1()
    DocBuilder.update(query_field, request, response, object_name(), input_fields)
  end

  def create_between_constraint() do
    query_field = "createBetweenConstraint"
    input_fields = between_input_fields()
    request = sample2()
    response = sample2()

    DocBuilder.create(query_field, request, response, object_name(), input_fields)
  end

  def update_between_constraint() do
    query_field = "updateBetweenConstraint"
    input_fields = between_input_fields()
    request = update2()
    response = update2()
    DocBuilder.update(query_field, request, response, object_name(), input_fields)
  end

  def delete() do
    query_field = "deleteConstraint"
    request = sample1()
    comment = "You cannot single_boundary a Constraint that is used by a Calculation."

    DocBuilder.delete(query_field, request, object_name(), comment)
  end

end
