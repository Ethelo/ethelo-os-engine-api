defmodule EtheloApi.Graphql.Docs.OptionDetail do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """

  # TODO add inline queries

  alias EtheloApi.Structure.Docs.OptionDetail, as: OptionDetailDocs
  alias EtheloApi.Graphql.QueryHelper

  def input_fields() do
    [
      :display_hint,
      :format,
      :input_hint,
      :public,
      :slug,
      :sort,
      :title
    ]
  end

  defp sample1() do
    Map.get(OptionDetailDocs.examples(), "Money")
  end

  defp sample2() do
    Map.get(OptionDetailDocs.examples(), "Boolean")
  end

  defp update1() do
    OptionDetailDocs.examples() |> Map.get("Percent") |> Map.put(:id, sample1().id)
  end

  @spec list() :: String.t()
  def list() do
    QueryHelper.query_example(
      "optionDetails",
      sample1() |> Map.take([:decision_id]),
      Map.keys(sample1()),
      [sample1(), sample2()],
      "List matching OptionDetails"
    )
  end

  @spec create() :: String.t()
  def create() do
    params = QueryHelper.mutation_params(sample1(), input_fields())

    QueryHelper.mutation_example(
      "createOptionDetail",
      params,
      Map.keys(sample1()),
      sample1(),
      "Add an OptionDetail"
    )
  end

  @spec update() :: String.t()
  def update() do
    params = QueryHelper.mutation_params(update1(), input_fields())

    QueryHelper.mutation_example(
      "updateOptionDetail",
      params,
      Map.keys(sample1()),
      update1(),
      "Update an OptionDetail"
    )
  end

  @spec delete() :: String.t()
  def delete() do
    params = QueryHelper.mutation_params(sample1(), [:decision_id, :id])
    comment = "Delete an OptionDetail.
    All associated OptionDetailValues will also be removed."

    QueryHelper.delete_mutation_example(
      "deleteOptionDetail",
      params,
      [:id],
      sample1() |> Map.take([:id]),
      comment
    )
  end
end
