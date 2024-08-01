defmodule UniqueSlug.QueryHelper do
  @moduledoc """
  Assorted methods to perform common query operations
  """
  import Ecto.{Query, Changeset}, warn: false

  @spec count_matching(any, atom) :: any
  def count_matching(queryable, repo) do
    queryable
    |> exclude(:select)
    |> select([t], count(1))
    |> repo.one
  end

  @spec maybe_match_id(any, nil | integer) :: any
  def maybe_match_id(queryable, id) when is_integer(id) do
    from(q in queryable, where: q.id != ^id)
  end

  def maybe_match_id(queryable, nil), do: queryable

  @doc """
  Wraps a query that checks for the existence of a suggested slug.
  """
  def slug_not_found(queryable, repo, slug, id) do
    queryable
    |> where([t], t.slug == ^slug)
    |> maybe_match_id(id)
    |> count_matching(repo)
    |> Kernel.==(0)
    |> (&{:ok, &1}).()
  end
end
