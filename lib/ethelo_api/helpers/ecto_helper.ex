defmodule EtheloApi.Helpers.EctoHelper do
  @moduledoc """
  Helper methods for modifying queries for things like filtering
  """
  import Ecto.Query, warn: false

  def only_fields(query, nil), do: query
  def only_fields(query, []), do: query

  def only_fields(query, fields) when is_list(fields) do
    query |> select([t], map(t, ^fields))
  end

  def only_fields(_, _), do: raise(ArgumentError, message: "you must supply a list of fields")

  def value_list(query, nil), do: query
  def value_list(query, []), do: query

  def value_list(query, fields) when is_list(fields) do
    query |> select([t], ^fields)
  end

  def value_list(_, _), do: raise(ArgumentError, message: "you must supply a list of fields")

  def only_distinct(query, %{distinct: true}), do: only_distinct(query, true)

  def only_distinct(query, true) do
    query |> distinct(true)
  end

  def only_distinct(query, _), do: query

  @spec filter_query(Ecto.Queryable.t(), map(), list()) :: Ecto.Queryable.t()
  def filter_query(query, map, _) when map == %{}, do: query

  def filter_query(query, submitted_filters, valid_filters) do
    values = submitted_filters |> Map.take(valid_filters) |> Map.to_list()

    # ensures no records returned if filter is invalid
    values = if values == [], do: %{id: 0}, else: values

    Enum.reduce(values, query, fn {fieldname, value}, query ->
      add_where_clause(query, fieldname, value)
    end)
  end

  def add_where_clause(query, fieldname, nil) do
    query |> where([q], is_nil(field(q, ^fieldname)))
  end

  def add_where_clause(query, fieldname, value) when is_list(value) do
    query |> where([q], field(q, ^fieldname) in ^value)
  end

  def add_where_clause(query, fieldname, value) do
    query |> where([q], field(q, ^fieldname) == ^value)
  end

  def count_by_date(subquery, interval) when interval in ["year", "month", "week", "day"] do
    subquery
    |> select([v], %{
      datetime:
        fragment("date_trunc(?, ? AT TIME ZONE 'UTC') as truncated_date", ^interval, v.datetime),
      count: count("*")
    })
    |> group_by([v], [fragment("truncated_date")])
    |> EtheloApi.Repo.all()
    |> Enum.map(fn x = %{datetime: {{year, month, day}, {hh, mm, ss, _}}} ->
      %{
        x
        | datetime:
            NaiveDateTime.from_erl!({{year, month, day}, {hh, mm, ss}})
            |> DateTime.from_naive!("Etc/UTC")
      }
    end)
  end

  def exists?(query, submitted_filters, valid_filters) do
    query
    |> filter_query(submitted_filters, valid_filters)
    |> EtheloApi.Repo.exists?()
  end
end
