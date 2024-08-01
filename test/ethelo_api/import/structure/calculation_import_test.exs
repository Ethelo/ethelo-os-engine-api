defmodule EtheloApi.Import.CalculationImportTest do
  @moduledoc """
  Test importing Calculations
  """
  use EtheloApi.ImportCase
  @moduletag ecto: true, decision: true, import: true

  alias EtheloApi.Import.Structure.Calculation, as: CalculationImport

  def assert_variables_in_expression(segment) do
    for {order, calculation} <- Map.get(segment, :completed_by_order) do
      variable_slugs = Map.get(calculation, :variables) |> Enum.map(& &1.slug)

      extra_variables =
        for slug <- variable_slugs, reduce: [] do
          extra_variables ->
            if String.contains?(calculation.expression, slug) do
              extra_variables
            else
              extra_variables ++ [slug]
            end
        end

      assert {"Input #{order}", extra_variables} == {"Input #{order}", []}

      assert Enum.count(variable_slugs) > 0,
             "Input #{order} has no variables, expected at least one"
    end
  end

  describe "Calculation import" do
    test "inserts and updates with valid data", context do
      %{input: input, process: process} = context

      result = CalculationImport.process_calculations(process, input)

      %{process: process, segment: segment} = evaluate_valid_step(result, :calculations)

      segment_input = Map.get(input, :calculations)
      assert_processed_expected_number(segment, segment_input)
      assert_changeset_slugs_match(segment.processed_by_order, segment_input)

      result = CalculationImport.insert_calculations(process)

      %{segment: segment} = evaluate_valid_step(result, :calculations)

      assert_inserted_slugs_match(segment, segment_input)

      result = CalculationImport.update_calculations(process)

      %{segment: segment} = evaluate_valid_step(result, :calculations)

      assert_variables_in_expression(segment)
      assert_complete_segment(segment)
    end

    test "returns errors with invalid field", context do
      %{input: input, process: process} = context

      invalid =
        input
        |> Map.get(:calculations)
        |> List.update_at(1, fn item -> Map.put(item, "title", " ") end)

      result =
        CalculationImport.process_calculations(process, %{calculations: invalid})

      %{segment: segment} = evaluate_invalid_step(result, :calculations)

      expected_error = %{
        segment: :calculations,
        index: 1,
        data: Enum.at(invalid, 1),
        messages: %{title: :required}
      }

      assert_one_import_error(segment, expected_error)
    end

    test "returns errors with invalid association", context do
      %{process: process, input: input} =
        Map.put(context, :process, ImportFactory.setup_calculations(context))

      result = CalculationImport.update_calculations(process)

      %{segment: segment} = evaluate_invalid_step(result, :calculations)
      %{errors: errors} = segment

      assert [first_error | _] = errors

      segment_input = Map.get(input, :calculations)

      expected_error = %{
        segment: :calculations,
        index: 0,
        data: Enum.at(segment_input, 0),
        messages: %{expression: :foreign}
      }

      assert_equivalent_import_error(expected_error, first_error)

      assert Enum.count(errors) == Enum.count(segment_input)
    end
  end
end
