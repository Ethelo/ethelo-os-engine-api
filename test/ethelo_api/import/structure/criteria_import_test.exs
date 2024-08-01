defmodule EtheloApi.Import.CriteriaImportTest do
  @moduledoc """
  Test importing Criterias
  """
  use EtheloApi.ImportCase
  @moduletag ecto: true, decision: true, import: true

  alias EtheloApi.Import.Structure.Criteria, as: CriteriaImport

  describe "Criteria import" do
    test "inserts with valid data", context do
      %{input: input, process: process} = context

      result = CriteriaImport.process_criterias(process, input)

      %{process: process, segment: segment} = evaluate_valid_step(result, :criterias)

      segment_input = Map.get(input, :criterias)
      assert_processed_expected_number(segment, segment_input)
      assert_changeset_slugs_match(segment.processed_by_order, segment_input)

      result = CriteriaImport.insert_criterias(process)

      %{segment: segment} = evaluate_valid_step(result, :criterias)

      assert_complete_segment(segment)
      assert_inserted_slugs_match(segment, segment_input)
    end

    test "returns errors with invalid field", context do
      %{input: input, process: process} = context

      invalid =
        input
        |> Map.get(:criterias)
        |> List.update_at(1, fn item -> Map.put(item, "title", " ") end)

      result = CriteriaImport.process_criterias(process, %{criterias: invalid})

      %{segment: segment} = evaluate_invalid_step(result, :criterias)

      expected_error = %{
        segment: :criterias,
        index: 1,
        data: Enum.at(invalid, 1),
        messages: %{title: :required}
      }

      assert_one_import_error(segment, expected_error)
    end
  end
end
