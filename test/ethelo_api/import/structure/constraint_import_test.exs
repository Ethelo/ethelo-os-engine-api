defmodule EtheloApi.Import.ConstraintImportTest do
  @moduledoc """
  Test importing Constraints
  """
  use EtheloApi.ImportCase
  @moduletag ecto: true, decision: true, import: true

  alias EtheloApi.Import.Structure.Constraint, as: ConstraintImport

  describe "Constraint import" do
    test "inserts with valid data", context do
      context = Map.put(context, :process, ImportFactory.setup_option_filters(context))
      context = Map.put(context, :process, ImportFactory.setup_variables(context))
      context = Map.put(context, :process, ImportFactory.setup_calculations(context))
      %{input: input, process: process} = context

      result = ConstraintImport.process_constraints(process, input)

      %{process: process, segment: segment} = evaluate_valid_step(result, :constraints)

      segment_input = Map.get(input, :constraints)
      assert_processed_expected_number(segment, segment_input)
      assert_changeset_slugs_match(segment.processed_by_order, segment_input)

      result = ConstraintImport.insert_constraints(process)

      %{segment: segment} = evaluate_valid_step(result, :constraints)

      assert_complete_segment(segment)
      assert_inserted_slugs_match(segment, segment_input)
    end

    test "returns errors with invalid field", context do
      context = Map.put(context, :process, ImportFactory.setup_option_filters(context))
      context = Map.put(context, :process, ImportFactory.setup_variables(context))
      context = Map.put(context, :process, ImportFactory.setup_calculations(context))
      %{input: input, process: process} = context

      invalid =
        input
        |> Map.get(:constraints)
        |> List.update_at(0, fn item -> Map.put(item, "title", " ") end)

      result = ConstraintImport.process_constraints(process, %{constraints: invalid})

      %{segment: segment} = evaluate_invalid_step(result, :constraints)

      expected_error = %{
        segment: :constraints,
        index: 0,
        data: Enum.at(invalid, 0),
        messages: %{title: :required}
      }

      assert_one_import_error(segment, expected_error)
    end
  end
end
