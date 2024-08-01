defmodule EtheloApi.TestHelper.ImportHelper do
  @moduledoc """
  Generic helpers used in import tests
  """

  import ExUnit.Assertions
  alias EtheloApi.Import.ImportProcess
  alias EtheloApi.Import.ImportSegment
  alias EtheloApi.Import.ImportError

  def valid_import() do
    ~s|
        {
          "decision": {
            "criterias": [{"title": "test2", "slug": "test2"}]
          }
        }
    |
  end

  def invalid_import() do
    ~s|
        {"decision":
          {"options":
            [{"id":50517,"info":null,"title":"0 Seeds","slug":"fifth_seed0","option_category_id":66877}]
          }
        }
    |
  end

  def evaluate_valid_step(result, key) do
    {status, %ImportProcess{} = updated_process} = result

    segment = Map.get(updated_process, key)
    assert %ImportSegment{} = segment
    assert_valid_segment(segment)

    assert status == :ok, "Expected valid step but step is invalid"

    %{process: updated_process, segment: segment}
  end

  def evaluate_invalid_step(result, key) do
    assert {process_status, %ImportProcess{} = updated_process} = result

    segment = Map.get(updated_process, key)
    assert %ImportSegment{} = segment
    assert_invalid_segment(segment)

    assert process_status == :error, "Expected invalid process but process is valid"

    %{process: updated_process, segment: segment}
  end

  def assert_processed_expected_number(segment, segment_input) do
    expected_count = Enum.count(segment_input)

    assert segment.segment_input == segment_input
    assert expected_count == Enum.count(segment.input_by_order)
    assert expected_count == Enum.count(segment.processed_by_order)
  end

  def assert_inserted_expected_number(segment, segment_input) do
    expected_count = Enum.count(segment_input)

    assert expected_count == Enum.count(segment.inserted_by_id)
  end

  def assert_changeset_slugs_match(input_items, segment_input) when is_map(input_items) do
    changeset_slugs =
      for {order, changeset} <- input_items, into: %{} do
        slug = changeset |> Map.get(:changes) |> Map.get(:slug)
        {"Item #{order}", slug}
      end

    input_slugs =
      for {input_item, order} <- Enum.with_index(segment_input), into: %{} do
        {"Item #{order}", Map.get(input_item, "slug")}
      end

    assert input_slugs == changeset_slugs
  end

  def assert_inserted_slugs_match(segment, segment_input) do
    inserted_slugs =
      for {id, item} <- Map.get(segment, :inserted_by_id), into: %{} do
        {id, Map.get(item, :slug)}
      end

    input_slugs =
      for input_item <- segment_input, into: %{} do
        input_id = Map.get(input_item, "id")
        new_item_id = get_in(segment, [:input_id_to_db_id, input_id])

        {new_item_id, Map.get(input_item, "slug")}
      end

    assert input_slugs == inserted_slugs
  end

  def assert_completed_assoc_present(segment, segment_input, field_list) do
    atom_keys = field_list |> Enum.map(&String.to_existing_atom/1)

    non_nil_records =
      for {order, item} <- Map.get(segment, :completed_by_order), into: %{} do
        {"Input #{order}", Map.take(item, atom_keys) |> non_nil_fields}
      end

    non_nil_inputs =
      for {input_item, order} <- Enum.with_index(segment_input), into: %{} do
        values = input_item |> Map.take(field_list) |> atomize_keys() |> non_nil_fields()

        {"Input #{order}", values}
      end

    assert non_nil_inputs == non_nil_records
  end

  def assert_completed_fields_match(segment, segment_input, field_list) do
    atom_keys = field_list |> Enum.map(&String.to_existing_atom/1)

    inserted_values =
      for {order, item} <- Map.get(segment, :completed_by_order), into: %{} do
        {"Input #{order}", Map.take(item, atom_keys)}
      end

    input_values =
      for {input_item, order} <- Enum.with_index(segment_input), into: %{} do
        values = input_item |> Map.take(field_list) |> atomize_keys()

        {"Input #{order}", values}
      end

    assert input_values == inserted_values
  end

  def assert_valid_segment(%{valid?: valid} = segment) do
    errors_summary = extract_errors(segment)

    assert errors_summary == []
    assert valid == true, "Expected valid segment but segment is invalid"
  end

  def assert_invalid_segment(%{errors: errors, valid?: valid}) do
    refute [] == errors

    assert valid == false, "Expected invalid segment but segment is valid"
  end

  def assert_complete_segment(%{
        complete?: complete,
        valid?: valid,
        completed_by_id: completed_by_id
      }) do
    refute is_nil(completed_by_id)
    assert complete == true
    assert valid == true
  end

  def assert_one_import_error(segment, expected_error) do
    %{errors: errors} = segment
    assert [%ImportError{} = error] = errors
    assert_equivalent_import_error(expected_error, error)
  end

  def assert_many_import_errors(segment, expected_errors) do
    %{errors: errors} = segment

    for {expected, error} <- Enum.zip(expected_errors, errors) do
      assert_equivalent_import_error(expected, error)
    end
  end

  def assert_equivalent_import_error(expected_error, %ImportError{} = error) do
    assert expected_error.segment == error.segment
    assert expected_error.index == error.index
    assert expected_error.data == error.data

    assert_import_error_messages(expected_error.messages, error)
  end

  def assert_import_error_messages(expected, %{messages: messages}) do
    compare =
      for validation_message <- messages, into: %{} do
        {validation_message.field, validation_message.code}
      end

    assert expected == compare
  end

  def extract_errors(%{errors: nil}), do: []

  def extract_errors(%{errors: errors}) do
    for %{index: index, messages: messages, data: data} <- errors do
      error_list =
        for %{field: field, code: code} <- messages, into: %{} do
          {field, code}
        end

      subset_keys = (Map.keys(error_list) ++ [:slug]) |> Enum.map(&to_string/1)
      {"Input #{index}", error_list, Map.take(data, subset_keys)}
    end
  end

  def extract_errors(_), do: []

  def atomize_keys(map) do
    for {k, v} <- map, into: %{} do
      if is_atom(k), do: {k, v}, else: {String.to_atom(k), v}
    end
  end

  def stringify_keys(map) do
    for {k, v} <- map, into: %{} do
      if is_atom(k), do: {to_string(k), v}, else: {k, v}
    end
  end

  def non_nil_fields(item) do
    item
    |> Enum.filter(fn {_k, v} -> !is_nil(v) end)
    |> Enum.into(%{})
    |> Map.keys()
  end
end
