defmodule EtheloApi.Graphql.Schemas.OptionTest do
  @moduledoc """
  Test graphql queries for Options
  """
  use EtheloApi.Graphql.SchemaCase
  @moduletag option: true, graphql: true

  alias EtheloApi.Structure
  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.OptionHelper

  describe "decision => options query" do
    test "without filter returns all records" do
      %{option: to_match1, decision: decision} = create_option()
      %{option: to_match2} = create_option(decision)

      %{option: _excluded} = create_option()
      assert_list_many_query("options", decision.id, %{}, [to_match1, to_match2], fields())
    end

    test "filters by id" do
      %{option: to_match, decision: decision} = create_option()
      %{option: _excluded} = create_option(decision)
      assert_list_one_query("options", to_match, [:id], fields([:id]))
    end

    test "filters by slug" do
      %{option: to_match, decision: decision} = create_option()
      %{option: _excluded} = create_option(decision)
      assert_list_one_query("options", to_match, [:slug], fields([:slug]))
    end

    test "filters by option_category_id" do
      %{option: to_match, decision: decision} = create_option()
      %{option: _excluded} = create_option(decision)

      assert_list_one_query(
        "options",
        to_match,
        [:option_category_id],
        fields([:option_category_id])
      )
    end

    test "filters by option_filter_id" do
      %{decision: decision, option: to_match, option_category: option_category} = create_option()

      %{option: _excluded} = create_option(decision)

      %{option_filter: option_filter} =
        create_option_category_filter_matching(decision, option_category, "in_category")

      to_match = to_match |> Map.from_struct() |> Map.put(:option_filter_id, option_filter.id)

      assert_list_one_query("options", to_match, [:option_filter_id], fields([:id]))
    end

    test "filters by enabled" do
      decision = create_decision()
      %{option: to_match, decision: decision} = create_option(decision, %{enabled: true})
      %{option: _excluded} = create_option(decision, %{enabled: false})

      assert_list_one_query("options", to_match, [:enabled], fields([:enabled]))
    end

    test "no matching records" do
      decision = create_decision()

      assert_list_none_query("options", %{decision_id: decision.id}, [:id])
    end

    test "inline OptionCategories" do
      %{option_category: inline1, option: option1, decision: decision} = create_option()
      %{option_category: inline2, option: option2} = create_option(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            options{
            id
              optionCategory{
                id
              }
            }
          }
        }
      """

      result_list = evaluate_query_graphql(query, "options")

      result_list = result_list |> Enum.sort_by(&Map.get(&1, "id"))
      assert [first_result, second_result] = result_list

      [expected1, expected2] = [
        %{"id" => "#{option1.id}", "optionCategory" => %{"id" => "#{inline1.id}"}},
        %{"id" => "#{option2.id}", "optionCategory" => %{"id" => "#{inline2.id}"}}
      ]

      assert expected1 == first_result
      assert expected2 == second_result
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
            options{
              id
              detailValues{
                value
              }
            }
          }
        }
      """

      result_list = evaluate_query_graphql(query, "options")

      result_list = result_list |> Enum.sort_by(&Map.get(&1, "id"))
      assert [first_result, second_result] = result_list

      [expected1, expected2] = [
        %{"id" => "#{inline1.option_id}", "detailValues" => [%{"value" => inline1.value}]},
        %{"id" => "#{inline2.option_id}", "detailValues" => [%{"value" => inline2.value}]}
      ]

      assert expected1 == first_result
      assert expected2 == second_result
    end
  end

  describe "createOption mutation" do
    test "creates with valid data" do
      %{decision: decision} = deps = option_deps()
      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names)
      requested_fields = Map.keys(attrs) ++ [:id]

      payload = run_mutate_one_query("createOption", decision.id, attrs, requested_fields)

      assert_mutation_success(attrs, payload, fields(field_names))
      refute nil == get_in(payload, ["result", "id"])
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = option_deps()

      invalid = Map.take(invalid_attrs(), [:title])
      field_names = [:option_category_id, :slug, :title]
      attrs = deps |> valid_attrs() |> Map.merge(invalid) |> Map.take(field_names)

      payload = run_mutate_one_query("createOption", decision.id, attrs)

      expected = [%ValidationMessage{code: :required, field: :title}]
      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid Decision returns error" do
      %{decision: decision} = deps = option_deps()
      delete_decision(decision)

      field_names = [:option_category_id, :title]
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("createOption", decision.id, attrs)

      expected = [%ValidationMessage{code: :not_found, field: "decisionId"}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "updateOption mutation" do
    test "updates with valid data" do
      %{decision: decision} = deps = create_option()
      field_names = input_field_names() ++ [:id]
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("updateOption", decision.id, attrs)

      assert_mutation_success(attrs, payload, fields(field_names))
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = create_option()
      invalid = Map.take(invalid_attrs(), [:title])

      field_names = [:title, :slug, :id]
      attrs = deps |> valid_attrs() |> Map.merge(invalid) |> Map.take(field_names)

      payload = run_mutate_one_query("updateOption", decision.id, attrs)

      expected = [%ValidationMessage{code: :required, field: :title}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid Option returns error" do
      %{option: to_delete, decision: decision} = deps = create_option()
      delete_option(to_delete)

      field_names = [:id, :title]
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("updateOption", decision.id, attrs)

      expected = [%ValidationMessage{code: "not_found", field: :id}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "deleteOption mutation" do
    test "deletes" do
      %{decision: decision, option: to_delete} = create_option()

      attrs = to_delete |> Map.take([:id])
      payload = run_mutate_one_query("deleteOption", decision.id, attrs)

      assert_mutation_success(%{}, payload, %{})

      assert nil == Structure.get_option(to_delete.id, decision)
    end
  end
end
