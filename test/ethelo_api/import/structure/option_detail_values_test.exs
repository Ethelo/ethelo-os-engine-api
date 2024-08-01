defmodule EtheloApi.Import.OptionDetailValueImportTest do
  @moduledoc """
  Test importing OptionDetailValues
  """
  use EtheloApi.ImportCase
  @moduletag ecto: true, decision: true, import: true

  alias EtheloApi.Import.Structure.OptionDetailValue, as: OptionDetailValueImport

  describe "OptionDetailValue import" do
    test "inserts with valid data", context do
      context = Map.put(context, :process, ImportFactory.setup_options(context))

      context = Map.put(context, :process, ImportFactory.setup_option_details(context))
      %{input: input, process: process} = context

      result = OptionDetailValueImport.insert_option_detail_values(process, input)

      %{segment: segment} = evaluate_valid_step(result, :option_detail_values)

      segment_input = Map.get(input, :option_detail_values)

      assert Enum.count(segment_input) == Enum.count(segment.inserted_records)

      assert_valid_segment(segment)
      assert_complete_segment(segment)
    end

    test "returns errors with invalid association", context do
      context = Map.put(context, :process, ImportFactory.setup_option_details(context))
      %{input: input, process: process} = context

      result = OptionDetailValueImport.insert_option_detail_values(process, input)

      %{segment: segment} = evaluate_invalid_step(result, :option_detail_values)

      segment_input = Map.get(input, :option_detail_values)

      expected_errors =
        for {item, order} <- Enum.with_index(segment_input) do
          %{
            segment: :option_detail_values,
            index: order,
            data: item,
            messages: %{option_id: :required}
          }
        end

      assert_many_import_errors(segment, expected_errors)
    end
  end
end
