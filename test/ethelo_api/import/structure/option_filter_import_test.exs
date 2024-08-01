defmodule EtheloApi.Import.OptionFilterImportTest do
  @moduledoc """
  Test importing OptionFilters
  """
  use EtheloApi.ImportCase
  @moduletag ecto: true, decision: true, import: true

  alias EtheloApi.Import.Structure.OptionFilter, as: OptionFilterImport

  describe "OptionFilter import" do
    test "inserts with valid data", context do
      context = Map.put(context, :process, ImportFactory.setup_option_categories(context))
      context = Map.put(context, :process, ImportFactory.setup_option_details(context))
      %{input: input, process: process} = context

      result = OptionFilterImport.process_option_filters(process, input)

      %{process: process, segment: segment} = evaluate_valid_step(result, :option_filters)

      segment_input = Map.get(input, :option_filters)
      assert_processed_expected_number(segment, segment_input)
      assert_changeset_slugs_match(segment.processed_by_order, segment_input)

      result = OptionFilterImport.insert_option_filters(process)

      %{segment: segment} = evaluate_valid_step(result, :option_filters)

      assert_complete_segment(segment)
      assert_inserted_slugs_match(segment, segment_input)
    end

    test "returns errors with invalid field", context do
      context = Map.put(context, :process, ImportFactory.setup_option_categories(context))
      context = Map.put(context, :process, ImportFactory.setup_option_details(context))
      %{input: input, process: process} = context

      invalid =
        input
        |> Map.get(:option_filters)
        |> List.update_at(1, fn item -> Map.put(item, "title", " ") end)

      result = OptionFilterImport.process_option_filters(process, %{option_filters: invalid})

      %{segment: segment} = evaluate_invalid_step(result, :option_filters)

      expected_error = %{
        segment: :option_filters,
        index: 1,
        data: Enum.at(invalid, 1),
        messages: %{title: :format}
      }

      assert_one_import_error(segment, expected_error)
    end
  end
end
