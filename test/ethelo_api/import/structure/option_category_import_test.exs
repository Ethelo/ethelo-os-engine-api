defmodule EtheloApi.Import.OptionCategoryImportTest do
  @moduledoc """
  Test importing OptionCategories
  """
  use EtheloApi.ImportCase
  @moduletag ecto: true, decision: true, import: true

  alias EtheloApi.Import.Structure.OptionCategory, as: OptionCategoryImport

  describe "OptionCategory import" do
    test "inserts with valid data", context do
      %{input: input, process: process} = context

      result = OptionCategoryImport.process_option_categories(process, input)

      %{process: process, segment: segment} = evaluate_valid_step(result, :option_categories)

      segment_input = Map.get(input, :option_categories)
      assert_processed_expected_number(segment, segment_input)
      assert_changeset_slugs_match(segment.processed_by_order, segment_input)

      result = OptionCategoryImport.insert_option_categories(process)

      %{segment: segment} = evaluate_valid_step(result, :option_categories)

      assert_inserted_slugs_match(segment, segment_input)
    end

    test "returns errors with invalid field", context do
      %{input: input, process: process} = context

      invalid =
        input
        |> Map.get(:option_categories)
        |> List.update_at(1, fn item -> Map.put(item, "title", " ") end)

      result =
        OptionCategoryImport.process_option_categories(process, %{option_categories: invalid})

      %{segment: segment} = evaluate_invalid_step(result, :option_categories)

      expected_error = %{
        segment: :option_categories,
        index: 1,
        data: Enum.at(invalid, 1),
        messages: %{title: :required}
      }

      assert_one_import_error(segment, expected_error)
    end

    test "updates with valid assoc data", context do
      context = Map.put(context, :process, ImportFactory.setup_options(context))
      context = Map.put(context, :process, ImportFactory.setup_option_details(context))

      %{process: process, input: input} =
        Map.put(context, :process, ImportFactory.setup_option_categories(context))

      result = OptionCategoryImport.update_option_categories(process)

      %{segment: segment} = evaluate_valid_step(result, :option_categories)

      segment_input = Map.get(input, :option_categories)

      assert_completed_assoc_present(
        segment,
        segment_input,
        ~w[ primary_detail_id default_high_option_id default_low_option_id ]
      )

      assert_complete_segment(segment)
    end
  end
end
