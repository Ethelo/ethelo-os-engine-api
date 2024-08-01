defmodule EtheloApi.Import.ImportSegment do
  @moduledoc """
  Collected info for a single model
  """
  use StructAccess

  alias EtheloApi.Import.ImportSegment
  alias EtheloApi.Import.ImportError
  alias Ecto.Changeset

  defstruct key: nil,
            complete?: false,

            # validation
            errors: [],
            valid?: true,

            # indexes
            input_by_order: %{},
            input_id_to_db_id: %{},

            # stage caches
            segment_input: [],
            processed_by_order: %{},
            inserted_by_id: %{},
            # only used when there is no id
            inserted_records: [],
            updated_records_by_order: [],
            completed_by_id: nil,
            completed_by_order: nil

  def create_segment(key, full_input) do
    segment_input = full_input |> Map.get(key)

    %ImportSegment{key: key} |> ImportSegment.add_input(segment_input)
  end

  def add_input(%ImportSegment{} = segment, nil),
    do: %{segment | segment_input: []} |> mark_complete(%{})

  def add_input(%ImportSegment{} = segment, []),
    do: %{segment | segment_input: []} |> mark_complete(%{})

  def add_input(%ImportSegment{} = segment, segment_input) when is_list(segment_input) do
    index = index_by_order(segment_input)
    segment |> Map.put(:input_by_order, index) |> Map.put(:segment_input, segment_input)
  end

  defp validate_changeset_list(changesets_by_order, segment) do
    for {order, changeset} <- changesets_by_order do
      case Changeset.apply_action(changeset, :_) do
        {:ok, _struct} ->
          {:ok, {order, changeset}}

        {:error, changeset} ->
          input_data = get_in(segment, [:input_by_order, order])
          error = ImportError.changeset_to_error(changeset, segment, input_data, order)

          {:error, {order, error}}
      end
    end
    |> extract_by_status()
  end

  defp extract_by_status(changeset_list) do
    lists =
      changeset_list
      |> Enum.group_by(fn {status, _} -> status end, fn {_, value} -> value end)
      |> Enum.map(fn {group, list} -> {group, Enum.into(list, %{})} end)
      |> Enum.into(%{})

    valid = Map.get(lists, :ok, %{})
    errors = Map.get(lists, :error, %{})

    %{valid: valid, errors: errors}
  end

  def process_changesets(segment, changeset_list) when is_list(changeset_list) do
    changesets_by_order = index_by_order(changeset_list)

    %{valid: valid, errors: errors} =
      validate_changeset_list(changesets_by_order, segment)

    segment
    |> Map.put(:processed_by_order, valid)
    |> add_errors(errors)
  end

  def process_insert_all(segment, insert_all_result, match_key \\ :slug)

  def process_insert_all(segment, {:ok, {_count, inserted_records}}, false) do
    segment |> Map.put(:inserted_records, inserted_records)
  end

  def process_insert_all(segment, {:ok, {_count, inserted_records}}, match_key) do
    index =
      Map.get(segment, :segment_input) |> index_input_to_db(inserted_records, match_key)

    segment
    |> Map.put(:input_id_to_db_id, index)
    |> Map.put(:inserted_by_id, inserted_records |> index_by_id())
  end

  def process_insert_all(segment, {:error, error}, _) do
    message = ImportError.handle_postgrex_error(error, segment.key)
    add_errors(segment, [message])
  end

  def process_update_multi(segment, {:ok, updated_records_by_order}) do
    segment |> Map.put(:updated_records_by_order, updated_records_by_order)
  end

  def process_update_multi(segment, {:error, order, failed_changeset}) do
    input_data = get_in(segment, [:input_by_order, order])
    error = ImportError.changeset_to_error(failed_changeset, segment, input_data, order)
    add_errors(segment, [error])
  end

  def add_errors(segment, []), do: segment

  def add_errors(segment, keyed_errors) when is_map(keyed_errors) do
    add_errors(segment, Map.values(keyed_errors))
  end

  def add_errors(segment, error_list) when is_list(error_list) do
    segment
    |> Map.put(:errors, error_list)
    |> Map.put(:valid?, false)
  end

  def complete_if_valid_insert(%{valid?: false} = segment), do: segment

  def complete_if_valid_insert(segment) do
    mark_complete(segment, segment.inserted_by_id)
  end

  def complete_if_valid_update(%{valid?: false} = segment), do: segment

  def complete_if_valid_update(segment) do
    by_id = segment.updated_records_by_order |> Map.values() |> index_by_id()

    mark_complete(segment, by_id, segment.updated_records_by_order)
  end

  def mark_complete(segment, completed_by_id) when completed_by_id == %{},
    do: mark_complete(segment, %{}, %{})

  def mark_complete(segment, completed_by_id) when is_map(completed_by_id) do
    by_order = index_id_to_order(segment, completed_by_id)

    ImportSegment.mark_complete(segment, completed_by_id, by_order)
  end

  def mark_complete(segment, completed_by_id, completed_by_order) do
    segment
    |> Map.put(:completed_by_id, completed_by_id)
    |> Map.put(:completed_by_order, completed_by_order)
    |> Map.put(:valid?, true)
    |> Map.put(:complete?, true)
  end

  def index_id_to_order(segment, by_id) when is_map(by_id) do
    for {order, input_item} <- segment.input_by_order, into: %{} do
      item_id = Map.get(segment.input_id_to_db_id, input_item["id"])
      {order, Map.get(by_id, item_id)}
    end
  end

  def index_input_to_db(segment_input, inserted_records, match_key \\ :slug) do
    data_by_match_key =
      for input_item <- segment_input, into: %{} do
        {Map.get(input_item, to_string(match_key)), Map.get(input_item, "id")}
      end

    for row <- inserted_records, into: %{} do
      new_id = Map.get(row, :id)
      new_key = Map.get(row, match_key)

      old_id = Map.get(data_by_match_key, new_key)
      {old_id, new_id}
    end
  end

  def index_by_id(records) do
    for item <- records, into: %{}, do: {Map.get(item, :id), item}
  end

  def index_by_order(list) do
    for {item, order} <- Enum.with_index(list), into: %{}, do: {order, item}
  end

  @spec list_duplicate_slugs(list(map())) :: list()
  def list_duplicate_slugs(input_list) do
    input_list
    |> Enum.group_by(fn
      %{"slug" => slug} -> slug
      _ -> nil
    end)
    |> Enum.filter(fn
      {nil, _} -> false
      {_, v} -> length(v) > 1
    end)
    |> Enum.into(%{})
    |> Map.keys()
  end
end
