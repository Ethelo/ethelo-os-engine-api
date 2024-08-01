defmodule EtheloApi.Helpers.QueryHelper do
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

  def only_distinct(query, %{distinct: true}), do: only_distinct(query, true)

  def only_distinct(query, true) do
    query |> distinct(true)
  end

  def only_distinct(query, _), do: query

  def filter_query(query, submitted_filters, valid_filters) do
    values = submitted_filters |> Map.take(valid_filters) |> Map.to_list()

    # ensures no records returned if filter is invalid
    values = if values, do: values, else: %{id: 0}

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

  def handle_conflicts(options, target) do
    Enum.reduce(options, [], fn({key, value}, acc) ->
      case {key, value} do
        {:upsert, :true} ->
          acc ++ [on_conflict: :replace_all, conflict_target: target]

        _ -> acc
      end
    end)
  end
end
