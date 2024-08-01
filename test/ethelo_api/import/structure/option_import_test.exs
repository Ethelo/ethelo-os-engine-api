defmodule EtheloApi.Import.OptionImportTest do
  @moduledoc """
  Test importing Options
  """
  use EtheloApi.ImportCase
  @moduletag ecto: true, decision: true, import: true

  alias EtheloApi.Import.Structure.Option, as: OptionImport

  describe "Option import" do
    test "inserts with valid data", context do
      %{input: input} = context
      process = ImportFactory.setup_option_categories(context)

      segment_input = Map.get(input, :options)

      result = OptionImport.process_options(process, input)

      %{process: process, segment: segment} = evaluate_valid_step(result, :options)

      assert_processed_expected_number(segment, segment_input)
      assert_changeset_slugs_match(segment.processed_by_order, segment_input)

      result = OptionImport.insert_options(process)

      %{segment: segment} = evaluate_valid_step(result, :options)

      assert_valid_segment(segment)
      assert_inserted_slugs_match(segment, segment_input)
    end

    test "returns errors with invalid association", context do
      %{input: input, process: process} = context

      result = OptionImport.process_options(process, input)
      %{process: process} = evaluate_valid_step(result, :options)

      result = OptionImport.insert_options(process)

      %{segment: segment} = evaluate_invalid_step(result, :options)

      segment_input = Map.get(input, :options)

      expected_errors =
        for {item, order} <- Enum.with_index(segment_input) do
          %{
            segment: :options,
            index: order,
            data: item,
            messages: %{option_category_id: :required}
          }
        end

      assert_many_import_errors(segment, expected_errors)
    end
  end
end
