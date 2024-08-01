defmodule EtheloApi.Graphql.Docs.SolveDump do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  alias EtheloApi.Scenarios.Docs.SolveDump, as: SolveDumpDocs
  alias EtheloApi.Graphql.QueryHelper

  def sample1() do
    Map.get(SolveDumpDocs.examples(), "Sample 1")
  end

  def sample2() do
    Map.get(SolveDumpDocs.examples(), "Sample 2")
  end

  @spec list() :: String.t()
  def list() do
    QueryHelper.query_example(
      "solveDumps",
      sample1() |> Map.take([:decision_id]),
      Map.keys(sample1()),
      [sample1(), sample2()],
      "List matching SolveDumps"
    )
  end
end
