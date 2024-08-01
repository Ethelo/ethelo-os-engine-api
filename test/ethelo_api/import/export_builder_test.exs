defmodule EtheloApi.Import.ExportBuilderTest do
  @moduledoc """
  Test Decision Structure export builder
  """
  use EtheloApi.DataCase

  @moduletag ecto: true, export: true

  alias EtheloApi.Import.ExportBuilder
  import EtheloApi.TestHelper.ImportHelper

  describe "exports Decision" do
    test "pizza example" do
      %{decision: decision} = EtheloApi.Blueprints.PizzaProject.build(false)

      {:ok, json_export} = ExportBuilder.export_decision(decision)
      assert "" != json_export
      # write_file("pizza.json", json_export)

      assert {:ok, decoded_result} = Jason.decode(json_export)

      expected_json = load_support_file("pizza/export.json")
      {:ok, expected_result} = Jason.decode(expected_json)

      assert_equivalent_decoded(expected_result, decoded_result)
    end

    test "quadratic" do
      %{decision: decision} = EtheloApi.Blueprints.QuadVotingProject.build(false)

      {:ok, json_export} = ExportBuilder.export_decision(decision)
      assert "" != json_export

      assert {:ok, decoded_result} = Jason.decode(json_export)

      expected_json = load_support_file("quadratic/export.json")
      {:ok, expected_result} = Jason.decode(expected_json)
      # write_file("quadratic.json", json_export)

      assert_equivalent_decoded(expected_result, decoded_result)
    end
  end

  describe "copies Decision" do
    test "copies pizza" do
      %{decision: decision} = EtheloApi.Blueprints.PizzaProject.build(false)

      decision_data = %{
        slug: "new-project",
        title: "New Project",
        info: "this is a copied decision",
        language: "es",
        keywords: ["copied"]
      }

      assert {:ok, new_decision} = ExportBuilder.copy_decision(decision, decision_data)

      refute nil == EtheloApi.Structure.get_decision(new_decision.id)

      {:ok, new_export} = ExportBuilder.export_decision(new_decision)

      assert {:ok, new_result} = Jason.decode(new_export)

      new_decision_data =
        Map.take(new_result["decision"], ["slug", "title", "info", "language", "keywords"])

      new_result = drop_decision_data(new_result)

      assert stringify_keys(decision_data) == new_decision_data

      {:ok, base_export} = ExportBuilder.export_decision(decision)
      assert {:ok, expected_result} = Jason.decode(base_export)
      expected_result = drop_decision_data(expected_result)

      assert_equivalent_decoded(expected_result, new_result)
    end

    test "copies quadratic" do
      %{decision: decision} = EtheloApi.Blueprints.QuadVotingProject.build(false)

      decision_data = %{
        slug: "new-project",
        title: "New Project",
        info: "this is a copied decision",
        language: "es",
        keywords: ["copied"]
      }

      assert {:ok, new_decision} = ExportBuilder.copy_decision(decision, decision_data)

      refute nil == EtheloApi.Structure.get_decision(new_decision.id)

      {:ok, new_export} = ExportBuilder.export_decision(new_decision)

      assert {:ok, new_result} = Jason.decode(new_export)

      new_decision_data =
        Map.take(new_result["decision"], ["slug", "title", "info", "language", "keywords"])

      new_result = drop_decision_data(new_result)

      assert stringify_keys(decision_data) == new_decision_data

      {:ok, base_export} = ExportBuilder.export_decision(decision)
      assert {:ok, expected_result} = Jason.decode(base_export)
      expected_result = drop_decision_data(expected_result)

      assert_equivalent_decoded(expected_result, new_result)
    end
  end

  defp drop_decision_data(%{"decision" => data} = export) do
    dropped = Map.drop(data, ["slug", "title", "info", "language", "keywords"])

    Map.put(export, "decision", dropped)
  end

  defp sort_map_lists([%{} | _] = expected, [%{} | _] = result) do
    expected = expected |> Enum.sort_by(&Map.get(&1, "slug"))
    result = result |> Enum.sort_by(&Map.get(&1, "slug"))

    {expected, result}
  end

  defp sort_map_lists(expected, result), do: {expected, result}

  def assert_equivalent_decoded(expected, result, breadcrumb \\ "")

  def assert_equivalent_decoded(expected, result, breadcrumb) when is_list(expected) do
    message = [message: "Mismatch at #{breadcrumb}"]

    assert_with_function(expected, result, &is_list/1, message)

    assert_with_function(expected, result, &Enum.count/1,
      message: "Mismatched count at #{breadcrumb}"
    )

    {expected, result} = sort_map_lists(expected, result)
    zipped = Enum.zip(expected, result)

    for {{expected_value, result_value}, order} <- Enum.with_index(zipped) do
      order_breadcrumb = "#{breadcrumb} [#{order}]"

      if is_map(expected_value) || is_list(expected_value) do
        assert_equivalent_decoded(expected_value, result_value, order_breadcrumb)
      else
        assert_with_message(expected_value, result_value, "Mistmach at #{order_breadcrumb}")
      end
    end
  end

  def assert_equivalent_decoded(expected, result, breadcrumb) when is_map(expected) do
    assert_with_message(Map.keys(expected), Map.keys(result), "Mismatched keys at#{breadcrumb}")

    for {key, value} <- expected do
      key_breadcrumb = "#{breadcrumb} -> #{key}"
      message = "Mismatch at #{key_breadcrumb}"

      result_value = Map.get(result, key)

      cond do
        key == "exported_at" ->
          # will never match, don't check
          nil

        is_map(value) || is_list(value) ->
          assert_equivalent_decoded(value, result_value, key_breadcrumb)

        String.ends_with?(key, "id") ->
          assert_with_function(value, result_value, &is_nil/1, message: message)

        true ->
          assert_with_message(value, result_value, message)
      end
    end
  end
end
