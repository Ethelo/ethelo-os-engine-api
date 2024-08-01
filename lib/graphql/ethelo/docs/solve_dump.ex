defmodule GraphQL.EtheloApi.Docs.SolveDump do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """

  alias GraphQL.DocBuilder

  defp object_name() do
    "SolveDump"
  end

  def sample2() do
    %{decision_id: 1}
  end

  def sample1() do
    %{decision_id: 2}
  end

  def list() do
    request = sample1()
    responses = [sample1(), sample2()]
    DocBuilder.list("solve_dumps", request, responses, [:decision_id])
  end

end
