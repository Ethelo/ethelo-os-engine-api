defmodule EtheloApi.Helpers.SlugHelper do
  @moduledoc """
  Helper Methods for records associated with Decisions
  """

  import Ecto.{Query, Changeset}, warn: false
  alias UniqueSlug
  alias UniqueSlug.QueryHelper

  @doc """
  Configures UniqueSlug for use with a changeset.

  - If a slug value has been submitted, configures to only check that slug value.
  - If a slug value is not present, configures to try to generate a slug 10 times.
  - Also updates error message to end user friendly "has already been taken"

  """
  def maybe_update_slug(%Ecto.Changeset{} = changeset, checker, slugger \\ nil) do
    tries = if get_field(changeset, :slug) in [nil, ""], do: 10, else: 0
    opts = [tries: tries, message: "has already been taken"]
    opts = if slugger == nil do
      opts
    else
      Keyword.put(opts, :slugger, slugger)
    end

    changeset |> UniqueSlug.maybe_update_slug(:slug, :title, checker, opts)
  end

  defp decision_id(_, %{id: _} = decision), do: decision.id
  defp decision_id(nil, nil), do: nil
  defp decision_id(decision_id, _), do: decision_id

  @doc """
  Creates a slug check method suitable for use with Unique Slug.

  Will error if supplied changeset does not contain either a :decision object or a :decision_id value.
  """
  def slug_not_found_in_decision(queryable, slug, %Ecto.Changeset{} = changeset) do
    decision_id = decision_id(get_field(changeset, :decision_id), get_field(changeset, :decision))

    queryable
    |> where([t], t.decision_id == ^decision_id)
    |> slug_not_found(slug, changeset)
  end

  @doc """
  Creates a slug check method suitable for use with Unique Slug.

  Will error if supplied changeset does not contain either a :decision object or a :decision_id value.
  """
  def slug_not_found(queryable, slug, %Ecto.Changeset{} = changeset) do
    QueryHelper.slug_not_found(queryable, EtheloApi.Repo, slug, get_field(changeset, :id))
  end
end
