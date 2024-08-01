defmodule EtheloApi.Graphql.Docs.OptionDetailValue do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """

  # TODO add inline queries

  alias EtheloApi.Structure.Docs.OptionDetailValue, as: OptionDetailValueDocs
  alias EtheloApi.Graphql.QueryHelper

  def input_fields() do
    [
      :option_id,
      :option_detail_id,
      :value
    ]
  end

  defp sample1() do
    Map.get(OptionDetailValueDocs.examples(), "Sample 1")
  end

  @spec upsert() :: String.t()
  def upsert() do
    params = QueryHelper.mutation_params(sample1(), input_fields())

    QueryHelper.mutation_example(
      "upsertOptionDetailValue",
      params,
      Map.keys(sample1()),
      sample1(),
      "Update or Add an OptionDetailValue"
    )
  end

  @spec delete() :: String.t()
  def delete() do
    delete_fields = [:option_id, :option_detail_id]

    params =
      GraphqlBuilder.mutation_params(sample1(), [:decision_id, :option_id, :option_detail_id])

    QueryHelper.delete_mutation_example(
      "deleteOptionDetailValue",
      params,
      delete_fields,
      sample1() |> Map.take(delete_fields),
      "Delete an OptionDetailValue"
    )
  end
end
