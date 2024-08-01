defmodule EtheloApi.Import.ScenarioConfigImportTest do
  @moduledoc """
  Test importing ScenarioConfigs
  """
  use EtheloApi.ImportCase
  @moduletag ecto: true, decision: true, import: true

  alias EtheloApi.Import.Structure.ScenarioConfig, as: ScenarioConfigImport

  describe "ScenarioConfig import" do
    test "inserts with valid data", context do
      %{input: input, process: process} = context

      segment_input = Map.get(input, :scenario_configs)

      result =
        ScenarioConfigImport.process_scenario_configs(process, input)

      %{process: process, segment: segment} = evaluate_valid_step(result, :scenario_configs)

      assert_processed_expected_number(segment, segment_input)
      assert_changeset_slugs_match(segment.processed_by_order, segment_input)

      result = ScenarioConfigImport.insert_scenario_configs(process)

      %{segment: segment} = evaluate_valid_step(result, :scenario_configs)

      assert_complete_segment(segment)
      assert_inserted_slugs_match(segment, segment_input)
    end

    test "returns errors with invalid field", context do
      %{input: input, process: process} = context

      invalid =
        input
        |> Map.get(:scenario_configs)
        |> List.update_at(1, fn item -> Map.put(item, "title", " ") end)

      result =
        ScenarioConfigImport.process_scenario_configs(process, %{scenario_configs: invalid})

      %{segment: segment} = evaluate_invalid_step(result, :scenario_configs)

      expected_error = %{
        segment: :scenario_configs,
        index: 1,
        data: Enum.at(invalid, 1),
        messages: %{title: :required}
      }

      assert_one_import_error(segment, expected_error)
    end
  end
end
