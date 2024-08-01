defmodule EtheloApi.Graphql.Schemas.OptionDetailTest do
  @moduledoc """
  Test graphql queries for OptionDetails
  """
  use EtheloApi.Graphql.SchemaCase
  @moduletag option_detail: true, graphql: true

  alias EtheloApi.Structure
  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.OptionDetailHelper

  describe "decision => optionDetails query" do
    test "without filter returns all records" do
      %{option_detail: to_match1, decision: decision} = create_option_detail()
      %{option_detail: to_match2} = create_option_detail(decision)
      %{option_detail: _excluded} = create_option_detail()
      assert_list_many_query("optionDetails", decision.id, %{}, [to_match1, to_match2], fields())
    end

    test "filters by id" do
      %{option_detail: to_match, decision: decision} = create_option_detail()
      %{option_detail: _excluded} = create_option_detail(decision)
      assert_list_one_query("optionDetails", to_match, [:id], fields([:id]))
    end

    test "filters by slug" do
      %{option_detail: to_match, decision: decision} = create_option_detail()
      %{option_detail: _excluded} = create_option_detail(decision)

      assert_list_one_query("optionDetails", to_match, [:slug], fields([:slug]))
    end

    test "no matching records" do
      decision = create_decision()
      assert_list_none_query("optionDetails", %{decision_id: decision.id}, [:id])
    end

    test "inline OptionDetailValues" do
      decision = create_decision()
      %{option_detail_value: inline1} = create_option_detail_value(decision)
      %{option_detail_value: inline2} = create_option_detail_value(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionDetails{
              id
              optionValues{
                value
              }
            }
          }
        }
      """

      result_list = evaluate_query_graphql(query, "optionDetails")

      result_list = result_list |> Enum.sort_by(&Map.get(&1, "id"))
      assert [first_result, second_result] = result_list

      [expected1, expected2] = [
        %{"id" => "#{inline1.option_detail_id}", "optionValues" => [%{"value" => inline1.value}]},
        %{"id" => "#{inline2.option_detail_id}", "optionValues" => [%{"value" => inline2.value}]}
      ]

      assert expected1 == first_result
      assert expected2 == second_result
    end
  end

  describe "createOptionDetail mutation" do
    test "creates with valid data" do
      %{decision: decision} = deps = option_detail_deps()

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names)
      requested_fields = Map.keys(attrs) ++ [:id]

      payload = run_mutate_one_query("createOptionDetail", decision.id, attrs, requested_fields)

      assert_mutation_success(attrs, payload, fields(field_names))
      refute nil == get_in(payload, ["result", "id"])
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = option_detail_deps()
      invalid = Map.take(invalid_attrs(), [:title])

      field_names = [:format, :slug, :title]
      attrs = deps |> valid_attrs() |> Map.merge(invalid) |> Map.take(field_names)

      payload = run_mutate_one_query("createOptionDetail", decision.id, attrs)

      expected = [%ValidationMessage{code: :required, field: :title}]
      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid Decision returns error" do
      %{decision: decision} = deps = option_detail_deps()
      delete_decision(decision)

      field_names = [:format, :title]
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("createOptionDetail", decision.id, attrs)

      expected = [%ValidationMessage{code: :not_found, field: "decisionId"}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "updateOptionDetail mutation" do
    test "updates with valid data" do
      %{decision: decision} = deps = create_option_detail()

      field_names = input_field_names() ++ [:id]
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("updateOptionDetail", decision.id, attrs)

      assert_mutation_success(attrs, payload, fields(field_names))
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = create_option_detail()
      invalid = Map.take(invalid_attrs(), [:title])

      field_names = [:title, :slug, :id]
      attrs = deps |> valid_attrs() |> Map.merge(invalid) |> Map.take(field_names)

      payload = run_mutate_one_query("updateOptionDetail", decision.id, attrs)

      expected = [%ValidationMessage{code: :required, field: :title}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid OptionDetail returns error" do
      %{option_detail: to_delete, decision: decision} = deps = create_option_detail()
      delete_option_detail(to_delete)

      field_names = [:id, :title]
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("updateOptionDetail", decision.id, attrs)

      expected = [%ValidationMessage{code: "not_found", field: :id}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "deleteOptionDetail mutation" do
    test "deletes" do
      %{decision: decision, option_detail: to_delete} = create_option_detail()

      attrs = to_delete |> Map.take([:id])
      payload = run_mutate_one_query("deleteOptionDetail", decision.id, attrs)

      assert_mutation_success(%{}, payload, %{})

      assert nil == Structure.get_option_detail(to_delete.id, decision)
    end
  end
end
