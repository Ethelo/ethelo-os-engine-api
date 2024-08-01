defmodule GraphQL.EtheloApi.BatchHelper do
  @moduledoc """
  Batch tools, modified from Absinthe-Ecto to batch load associations
  """

  import Absinthe.Resolution.Helpers, only: [batch: 3]

  @doc """
  Checks if association is already loaded, loads through batch resolver if necessary

  Assumes relation is on the parent object's "id" field. This can be overridden by passing a third argument.

  The resolve function is a "batch_fn" type, constiting of a tuple with
  module name and function to call.
  See https://hexdocs.pm/absinthe/Absinthe.Middleware.Batch.html#t:batch_fun/0 for more info.

  ```elixir
  batch_assoc(:child, context, function_name)
  ```
  """
  def batch_assoc(association, context, function_name) do
    fn parent, _, _ ->
      case apply(context, :preloaded_assoc, [parent, association]) do
        {:error, _} ->
          resolver = {context, function_name, association}
          load_from_batch(resolver, context.associated_id(parent, association))
        {:ok, val} ->
          {:ok, val}
      end
    end
  end

  def match_has_one_func(loaded_id_field, match_id_field) do
    fn
      nil -> {:ok, nil}
      results -> results
        |> Enum.group_by(&(Map.get(&1, loaded_id_field)))
        |> Map.get(match_id_field)
        |> case do
          nil -> {:ok, nil}
          match -> match |> hd() |> (&{:ok, &1}).()
        end
    end
  end

  def match_one_func(loaded_id_field, match_id_field) do
    fn
      nil -> {:ok, nil}
      results -> results
        |> Enum.group_by(&(Map.get(&1, loaded_id_field)))
        |> Map.get(match_id_field)
        |> case do
          %Ecto.Association.NotLoaded{} -> {:ok, nil}
          nil -> {:ok, nil}
          match -> match |> hd() |> (&{:ok, &1}).()
        end
    end
  end

  def match_has_many_func(loaded_id_field, match_id_field) do
    fn
      nil -> {:ok, []}
      results -> results
        |> Enum.group_by(&(Map.get(&1, loaded_id_field)))
        |> Map.get(match_id_field)
        |> (&{:ok, &1}).()
    end
  end

  def extract_ids(list) do
    list |> Enum.map(&Map.get(&1, :id)) |> Enum.sort()
  end

  def match_many_to_many_func(match_field, match_id_field) do
    fn
      nil -> {:ok, []}
      results -> results
        |> Enum.filter(fn(records) ->
            ids = records |> Map.get(match_field, []) |> extract_ids()
            match_id_field in ids
          end)
        |> (&{:ok, &1}).()
    end
  end

  def match_keyed_map(match_id_field) do
    fn
      nil -> {:ok, []}
      results -> results
        |> Map.get(match_id_field)
        |> (&{:ok, &1}).()
    end
  end

  def batch_keyed_map(record, resolver) do
    matcher = match_keyed_map(Map.get(record, :id))
    batch(resolver, record.decision_id, matcher)
  end

  @doc """
  Returns preloaded value or invokes batch as necessary
  """
  def batch_belongs_to(record, expected_schema, preloaded_name, resolver, _info) do
    with {:error, _} <- preloaded_record(record, expected_schema, preloaded_name) do
      associated_id = associated_id(preloaded_name)
      matcher = match_one_func(:id, Map.get(record, associated_id))
      batch(resolver, record.decision_id, matcher)
    end
  end


  @doc """
  Returns preloaded value or invokes batch as necessary
  """
  def batch_has_one(record, expected_schema, preloaded_name, resolver) do
    with {:error, _} <- preloaded_record(record, expected_schema, preloaded_name) do
      matcher = match_has_one_func(:scenario_set_id, record.id)
      batch(resolver, record.decision_id, matcher)
    end
  end

  @doc """
  Returns preloaded value or invokes batch as necessary
  """
  def batch_has_many(record, preloaded_name, match_field, resolver) do
    case preloaded_list(record, preloaded_name) do
      {:ok, value} -> {:ok, value}
      _ ->
        matcher = match_has_many_func(match_field, Map.get(record, :id))
        batch(resolver, record.decision_id, matcher)
    end
  end

  @doc """
  Returns preloaded value or invokes batch as necessary
  """
  def batch_many_to_many(record, preloaded_name, match_field, resolver) do
    case preloaded_list(record, preloaded_name) do
      {:ok, value} -> {:ok, value}
      _ ->
        matcher = match_many_to_many_func(match_field, Map.get(record, :id))
        batch(resolver, record.decision_id, matcher)
    end
  end

  def preloaded_record(record, expected_schema, field) do
    associated = Map.get(record, field)
    cond do
      is_nil(associated) -> {:ok, associated}
      is_list(associated) -> {:ok, associated}
      assocation_not_loaded(associated) -> {:error, "data not preloaded"}
      %expected_schema{} = associated -> {:ok, associated}  # may not be functioning correctly
      true -> {:error, "data not preloaded"}
    end
  end
  def preloaded_record(nil), do: {:ok, nil}

  def assocation_not_loaded(%Ecto.Association.NotLoaded{}), do: true
  def assocation_not_loaded(_), do: false

  def preloaded_list(record, field) do
    associated = Map.get(record, field)
    cond do
      is_nil(associated) -> {:ok, associated}
      is_list(associated) -> {:ok, associated}
      true -> {:error, "data not preloaded"}
    end
  end

  def associated_id(field) do
    field |> to_string() |> Kernel.<>("_id") |> String.to_atom()
  end

  @doc """
  calls the batch method with an appropriate extraction function

  The extraction function is an anonymous function as it needs to be customized
  for each id. Given the results of the resolve "function", it extracts
  the results for the id and wraps them in a success tuple
  """
  def load_from_batch(resolve_tuple, id) do
    batch(resolve_tuple, id, fn results ->
      results |> Map.get(id) |> (&{:ok, &1}).()
    end)
  end

end
