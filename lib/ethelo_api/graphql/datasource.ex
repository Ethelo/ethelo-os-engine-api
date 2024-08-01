defmodule EtheloApi.Graphql.DataSource do
  @moduledoc """
  Direct database access for batch loading records
  This breaks functional boundaries such as EtheloApi.Structure vs EtheloApi.Scenarios,
  and may not be the best use case for complex filtering or sorting
  """
  alias EtheloApi.Repo

  def repo_datasource() do
    Dataloader.Ecto.new(Repo, query: &repo_query/2)
  end

  defp repo_query(module, _args) do
    module
  end
end
