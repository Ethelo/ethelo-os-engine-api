defmodule EtheloApi.Import.DecisionImportTest do
  @moduledoc """
  Test importing Decision record
  """
  use EtheloApi.ImportCase
  @moduletag ecto: true, decision: true, import: true

  alias EtheloApi.Import.Structure.Decision, as: DecisionImport
  alias EtheloApi.Structure.TestHelper.DecisionHelper

  alias EtheloApi.Structure.Decision

  def decision_data() do
    %{
      info: "<p><b>Pizza</b> for lunch.</p>",
      keywords: [
        "_guest",
        "_qa"
      ],
      language: "en",
      slug: "pizza-project",
      title: "Pizza Project"
    }
  end

  def decision_defaults do
    %{copyable: false, internal: false, max_users: 20}
  end

  describe "imports Decision" do
    test "creates with valid data" do
      process = %ImportProcess{input: %{}}

      input = decision_data()

      result = DecisionImport.import_decision(input, process)

      %{segment: segment} = evaluate_valid_step(result, :decision)

      assert_complete_segment(segment)

      decision = Map.values(segment.completed_by_id) |> hd()
      assert %Decision{} = decision
      refute nil == decision.id

      language = input |> Map.get(:language) |> String.to_existing_atom()
      expected = input |> Map.merge(decision_defaults()) |> Map.put(:language, language)

      DecisionHelper.assert_equivalent(expected, decision)
    end

    test "returns errors with invalid decision data" do
      process = %ImportProcess{input: %{}}

      input = %{title: "  "}

      result = DecisionImport.import_decision(input, process)

      %{segment: segment} = evaluate_invalid_step(result, :decision)

      expected_errors = [
        %{segment: :title, index: nil, data: "  ", messages: %{title: :required}},
        %{segment: :slug, index: nil, data: nil, messages: %{slug: :required}}
      ]

      assert_many_import_errors(segment, expected_errors)
    end

    test "ignores protected fields" do
      process = %ImportProcess{input: %{}}

      input = decision_data() |> Map.merge(%{copyable: true, max_users: 40, internal: true})

      result = DecisionImport.import_decision(input, process)

      assert {:ok, %ImportProcess{} = updated_process} = result

      assert %{decision: %ImportSegment{completed_by_id: completed_by_id}} = updated_process

      decision = Map.values(completed_by_id) |> hd()

      assert decision.copyable == false
      assert decision.internal == false
      assert decision.max_users == 20
    end
  end
end
