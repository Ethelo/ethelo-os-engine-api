defmodule EtheloApi.Import.VariableImportTest do
  @moduledoc """
  Test importing Variables
  """
  use EtheloApi.ImportCase
  @moduletag ecto: true, decision: true, import: true

  alias EtheloApi.Import.Structure.Variable, as: VariableImport

  describe "Variable import" do
    test "inserts with valid data", context do
      context = Map.put(context, :process, ImportFactory.setup_option_filters(context))
      context = Map.put(context, :process, ImportFactory.setup_option_details(context))
      %{input: input, process: process} = context

      result = VariableImport.process_variables(process, input)

      %{process: process, segment: segment} = evaluate_valid_step(result, :variables)

      segment_input = Map.get(input, :variables)
      assert_processed_expected_number(segment, segment_input)
      assert_changeset_slugs_match(segment.processed_by_order, segment_input)

      result = VariableImport.insert_variables(process)

      %{segment: segment} = evaluate_valid_step(result, :variables)

      assert_complete_segment(segment)
      assert_inserted_slugs_match(segment, segment_input)
    end

    test "returns errors with invalid field", context do
      context = Map.put(context, :process, ImportFactory.setup_option_filters(context))
      context = Map.put(context, :process, ImportFactory.setup_option_details(context))
      %{input: input, process: process} = context

      invalid =
        input
        |> Map.get(:variables)
        |> List.update_at(1, fn item -> Map.put(item, "title", " ") end)

      result = VariableImport.process_variables(process, %{variables: invalid})

      %{segment: segment} = evaluate_invalid_step(result, :variables)

      expected_error = %{
        segment: :variables,
        index: 1,
        data: Enum.at(invalid, 1),
        messages: %{title: :required}
      }

      assert_one_import_error(segment, expected_error)
    end
  end
end
