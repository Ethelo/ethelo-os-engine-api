defmodule EtheloApi.Import.OptionDetailImportTest do
  @moduledoc """
  Test importing OptionDetails
  """
  use EtheloApi.ImportCase
  @moduletag ecto: true, decision: true, import: true

  alias EtheloApi.Import.Structure.OptionDetail, as: OptionDetailImport

  describe "OptionDetail import" do
    test "inserts with valid data", context do
      %{input: input, process: process} = context

      segment_input = Map.get(input, :option_details)

      result = OptionDetailImport.process_option_details(process, input)

      %{process: process, segment: segment} = evaluate_valid_step(result, :option_details)

      assert_processed_expected_number(segment, segment_input)
      assert_changeset_slugs_match(segment.processed_by_order, segment_input)

      result = OptionDetailImport.insert_option_details(process)

      %{segment: segment} = evaluate_valid_step(result, :option_details)

      assert_complete_segment(segment)
      assert_inserted_slugs_match(segment, segment_input)
    end

    test "returns errors with invalid field", context do
      %{input: input, process: process} = context

      invalid =
        input
        |> Map.get(:option_details)
        |> List.update_at(1, fn item -> Map.put(item, "title", " ") end)

      result = OptionDetailImport.process_option_details(process, %{option_details: invalid})

      %{segment: segment} = evaluate_invalid_step(result, :option_details)

      expected_error = %{
        segment: :option_details,
        index: 1,
        data: Enum.at(invalid, 1),
        messages: %{title: :required}
      }

      assert_one_import_error(segment, expected_error)
    end
  end
end
