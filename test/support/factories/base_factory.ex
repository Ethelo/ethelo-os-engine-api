defmodule EtheloApi.BaseFactory do
  @moduledoc """
  Base schema for fixtures
  """

  alias EtheloApi.Repo
  import Ecto.Query, warn: false

  defmacro __using__(module: module) do
    quote do
      import EtheloApi.BaseFactory
      @module unquote(module)

      defp insert(defaults, attrs \\ %{}) do
        do_insert(defaults, attrs)
      end

      defp update(queryable, id, updates \\ %{}) do
        do_update(queryable, id, updates)
      end

      defp build(defaults, attrs \\ %{}) do
        do_build(defaults, attrs)
      end
    end
  end

  @spec do_build(module | struct, Enumerable.t()) :: struct
  def do_build(defaults, attributes) do
    struct(defaults, attributes)
  end

  @spec do_insert(module | struct, Enumerable.t()) :: Ecto.Schema.t()
  def do_insert(defaults, attributes \\ %{}) do
    Repo.insert!(do_build(defaults, attributes))
  end

  def do_update(queryable, id, attributes \\ %{}) do
    updates = attributes |> Enum.into([], fn {k, v} -> {k, v} end)

    queryable |> where([q], q.id == ^id) |> Repo.update_all(set: updates)

    Repo.get(queryable, id)
  end

  @spec do_delete_all(queryable :: Ecto.Queryable.t(), map() | integer()) ::
          {non_neg_integer, nil | [term]}
  def do_delete_all(schema, %{id: id}), do: do_delete_all(schema, id)

  def do_delete_all(schema, id) do
    values = [id: id]
    schema |> where(^values) |> Repo.delete_all()
  end

  def short_sentence() do
    Faker.Lorem.sentence(%Range{first: 3, last: 7, step: 1})
  end

  def random_bool() do
    Enum.random([true, false])
  end

  def unique_int() do
    System.unique_integer() |> abs()
  end
end
