defmodule EtheloApi.Import.ImportProcessTest do
  @moduledoc """
  Test graphql queries for ScenarioConfigs
  """
  use EtheloApi.ImportCase
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure

  @moduletag ecto: true, import: true

  def decision_data() do
    %{
      info: "<p><b>Pizza</b> for lunch.</p>",
      keywords: ["example"],
      language: "en",
      slug: "pizza-project",
      title: "Pizza Project"
    }
  end

  describe "build_from_json" do
    test "creates with valid data" do
      json = load_support_file("pizza/decision.json")

      result = ImportProcess.build_from_json(json, decision_data())

      assert {:ok, %Decision{} = decision} = result
      refute nil == Structure.get_decision(decision.id)
    end

    @invalid_json ~s|
        %{
        options: [%{id: 4, title: "test", slug: "test", option_category_id: 7}]
        }
    |

    test "errors with invalid json" do
      result = ImportProcess.build_from_json(@invalid_json, decision_data())

      assert {status, %ImportProcess{} = process} = result

      assert ImportError.invalid_segments(process) == []

      assert %{valid?: false, complete?: false} = process
      assert status == :error

      expected_error = %{
        segment: :json_data,
        index: nil,
        data: nil,
        messages: %{json_data: :import_file}
      }

      assert_equivalent_import_error(expected_error, process.input_error)
    end
  end

  describe "build" do
    test "creates with valid data" do
      json = ImportFactory.get_input()

      result = ImportProcess.build(json, decision_data())

      assert {status, %ImportProcess{} = process} = result

      assert(ImportError.invalid_segments(process) == [])

      assert %{valid?: true, complete?: true} = process
      assert status == :ok
    end

    @invalid_data ~s|
      { "decision":
        {
          "options": [{"title": "test2", "slug": "test2",  "option_category_id": 492, "id": 802 }]
        }
      }
      |

    test "errors with invalid data" do
      parsed = ImportFactory.parse_import(@invalid_data)
      result = ImportProcess.build(parsed, decision_data())

      assert {status, %ImportProcess{} = process} = result

      assert status == :error
      assert ImportError.invalid_segments(process) == [:options]

      assert %{valid?: false, complete?: false} = process

      errors = ImportError.compile_errors(process)

      expected_error = %{
        segment: :options,
        index: 0,
        data: %{"id" => 802, "option_category_id" => 492, "slug" => "test2", "title" => "test2"},
        messages: %{option_category_id: :required}
      }

      assert_equivalent_import_error(expected_error, hd(errors))
    end
  end
end
