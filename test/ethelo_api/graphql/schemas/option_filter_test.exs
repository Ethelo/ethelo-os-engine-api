defmodule EtheloApi.Graphql.Schemas.OptionFilterTest do
  @moduledoc """
  Test graphql queries for OptionFilters
  """
  use EtheloApi.Graphql.SchemaCase
  @moduletag option_filter: true, graphql: true

  alias EtheloApi.Structure
  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.OptionFilterHelper

  describe "decision => optionFilters query" do
    test "without filter returns all records" do
      %{option_filter: to_match1, decision: decision} = create_option_detail_filter()
      %{option_filter: to_match2} = create_option_category_filter(decision)
      %{option_filter: _excluded} = create_option_category_filter()

      to_match1 = upcase_enum(to_match1)
      to_match2 = upcase_enum(to_match2)

      assert_list_many_query("optionFilters", decision.id, %{}, [to_match1, to_match2], fields())
    end

    test "filters by id" do
      %{option_filter: to_match, decision: decision} = create_option_detail_filter()
      %{option_filter: _excluded} = create_option_category_filter(decision)

      assert_list_one_query("optionFilters", to_match, [:id], fields([:id]))
    end

    test "filters by slug" do
      %{option_filter: to_match, decision: decision} = create_option_detail_filter()

      %{option_filter: _excluded} = create_option_category_filter(decision)

      assert_list_one_query("optionFilters", to_match, [:slug], fields([:slug]))
    end

    test "filters by option_category_id" do
      %{option_filter: to_match, decision: decision} = create_option_category_filter()

      %{option_filter: _excluded} = create_option_category_filter(decision)

      assert_list_one_query(
        "optionFilters",
        to_match,
        [:option_category_id],
        fields([:option_category_id])
      )
    end

    test "filters by option_detail_id" do
      %{option_filter: to_match, decision: decision} = create_option_detail_filter()
      %{option_filter: _excluded} = create_option_detail_filter(decision)

      assert_list_one_query(
        "optionFilters",
        to_match,
        [:option_detail_id],
        fields([:option_detail_id])
      )
    end

    test "no matching records" do
      decision = create_decision()
      assert_list_none_query("optionFilters", %{decision_id: decision.id}, [:id])
    end

    test "inline Options" do
      %{decision: decision, option_filter: option_filter} = create_all_options_filter()
      %{option: inline1} = create_option(decision)
      %{option: inline2} = create_option(decision)

      query = ~s|
            {
              decision(
                decisionId: #{decision.id}
              )
              {
                optionFilters{
                id
                  options{
                    id
                  }
                  optionIds
                }
              }
            }
          |

      result_list = evaluate_query_graphql(query, "optionFilters")
      result_list = result_list |> Enum.sort_by(&Map.get(&1, "id"))

      expected = [
        %{
          "id" => "#{option_filter.id}",
          "options" => [
            %{"id" => "#{inline1.id}"},
            %{"id" => "#{inline2.id}"}
          ],
          "optionIds" => ["#{inline1.id}", "#{inline2.id}"]
        }
      ]

      assert expected == result_list
    end

    test "inline OptionDetail" do
      decision = create_decision()

      %{option_detail: option_detail, option_filter: option_filter1} =
        create_option_detail_filter(decision)

      %{option_filter: option_filter2} = create_option_category_filter(decision)

      query = ~s|
            {
              decision(
                decisionId: #{decision.id}
              )
              {
                optionFilters{
                id
                  optionDetail{
                    id
                  }
                }
              }
            }
          |

      result_list = evaluate_query_graphql(query, "optionFilters")
      result_list = result_list |> Enum.sort_by(&Map.get(&1, "id"))

      expected = [
        %{
          "id" => "#{option_filter1.id}",
          "optionDetail" => %{"id" => "#{option_detail.id}"}
        },
        %{
          "id" => "#{option_filter2.id}",
          "optionDetail" => nil
        }
      ]

      assert expected == result_list
    end
  end

  describe "createOptionDetailFilter mutation" do
    test "creates with valid data" do
      %{decision: decision} = deps = option_detail_filter_deps()

      field_names = input_field_names() |> List.delete(:option_category_id)
      attrs = deps |> valid_attrs() |> upcase_enum() |> Map.take(field_names)
      requested_fields = Map.keys(attrs) ++ [:id]

      payload =
        run_mutate_one_query("createOptionDetailFilter", decision.id, attrs, requested_fields)

      assert_mutation_success(attrs, payload, fields(field_names))
      refute nil == get_in(payload, ["result", "id"])
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = option_detail_filter_deps()

      invalid = Map.take(invalid_attrs(), [:title])

      field_names = input_field_names() |> List.delete(:option_category_id)

      attrs =
        deps |> valid_attrs() |> Map.merge(invalid) |> upcase_enum() |> Map.take(field_names)

      payload =
        run_mutate_one_query("createOptionDetailFilter", decision.id, attrs)

      expected = [%ValidationMessage{code: :format, field: :title}]
      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid Decision returns error" do
      %{decision: decision} = deps = option_detail_filter_deps()
      delete_decision(decision)

      field_names = input_field_names() |> List.delete(:option_category_id)
      attrs = deps |> valid_attrs() |> upcase_enum() |> Map.take(field_names)

      payload =
        run_mutate_one_query("createOptionDetailFilter", decision.id, attrs)

      expected = [%ValidationMessage{code: :not_found, field: "decisionId"}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "updateOptionDetailFilter mutation" do
    test "updates with valid data" do
      %{decision: decision} = deps = create_option_detail_filter()

      field_names =
        input_field_names() |> List.delete(:option_category_id) |> List.insert_at(0, :id)

      attrs = deps |> valid_attrs() |> upcase_enum() |> Map.take(field_names)

      payload =
        run_mutate_one_query("updateOptionDetailFilter", decision.id, attrs)

      assert_mutation_success(attrs, payload, fields(field_names))
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = create_option_detail_filter()

      invalid = Map.take(invalid_attrs(), [:title])
      field_names = [:title, :slug, :id]

      attrs =
        deps |> valid_attrs() |> Map.merge(invalid) |> upcase_enum() |> Map.take(field_names)

      payload =
        run_mutate_one_query("updateOptionDetailFilter", decision.id, attrs)

      expected = [%ValidationMessage{code: :format, field: :title}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid OptionFilter returns error" do
      %{option_filter: to_delete, decision: decision} = deps = create_option_detail_filter()
      delete_option_filter(to_delete)

      field_names = [:title, :slug, :id]
      attrs = deps |> valid_attrs() |> upcase_enum() |> Map.take(field_names)

      payload =
        run_mutate_one_query("updateOptionDetailFilter", decision.id, attrs)

      expected = [%ValidationMessage{code: "not_found", field: :id}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "createOptionCategoryFilter mutation" do
    test "creates with valid data" do
      %{decision: decision} = deps = option_category_filter_deps()

      field_names = input_field_names() |> List.delete(:option_detail_id)
      attrs = deps |> valid_attrs() |> upcase_enum() |> Map.take(field_names)
      requested_fields = Map.keys(attrs) ++ [:id]

      payload =
        run_mutate_one_query("createOptionCategoryFilter", decision.id, attrs, requested_fields)

      assert_mutation_success(attrs, payload, fields(field_names))
      refute nil == get_in(payload, ["result", "id"])
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = option_category_filter_deps()

      invalid = Map.take(invalid_attrs(), [:title])
      field_names = input_field_names() |> List.delete(:option_detail_id)

      attrs =
        deps |> valid_attrs() |> Map.merge(invalid) |> upcase_enum() |> Map.take(field_names)

      payload =
        run_mutate_one_query("createOptionCategoryFilter", decision.id, attrs)

      expected = [%ValidationMessage{code: :format, field: :title}]
      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid Decision returns error" do
      %{decision: decision} = deps = option_category_filter_deps()
      delete_decision(decision)

      field_names = input_field_names() |> List.delete(:option_detail_id)
      attrs = deps |> valid_attrs() |> upcase_enum() |> Map.take(field_names)

      payload =
        run_mutate_one_query("createOptionCategoryFilter", decision.id, attrs)

      expected = [%ValidationMessage{code: :not_found, field: "decisionId"}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "updateOptionCategoryFilter mutation" do
    test "updates with valid data" do
      %{decision: decision} = deps = create_option_category_filter()

      field_names =
        input_field_names() |> List.delete(:option_detail_id) |> List.insert_at(0, :id)

      attrs = deps |> valid_attrs() |> upcase_enum() |> Map.take(field_names)

      payload =
        run_mutate_one_query("updateOptionCategoryFilter", decision.id, attrs)

      assert_mutation_success(attrs, payload, fields(field_names))
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = create_option_category_filter()
      invalid = Map.take(invalid_attrs(), [:title])

      field_names = [:title, :slug, :id]

      attrs =
        deps |> valid_attrs() |> Map.merge(invalid) |> upcase_enum() |> Map.take(field_names)

      payload =
        run_mutate_one_query("updateOptionCategoryFilter", decision.id, attrs)

      expected = [%ValidationMessage{code: :format, field: :title}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid OptionFilter returns error" do
      %{option_filter: to_delete, decision: decision} = deps = create_option_category_filter()
      delete_option_filter(to_delete)

      field_names = [:id, :title]
      attrs = deps |> valid_attrs() |> upcase_enum() |> Map.take(field_names)

      payload =
        run_mutate_one_query("updateOptionCategoryFilter", decision.id, attrs)

      expected = [%ValidationMessage{code: "not_found", field: :id}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "deleteOptionFilter mutation" do
    test "deletes" do
      %{decision: decision, option_filter: to_delete} = create_option_detail_filter()
      attrs = to_delete |> Map.take([:id])
      payload = run_mutate_one_query("deleteOptionFilter", decision.id, attrs)
      assert_mutation_success(%{}, payload, %{})
      assert nil == Structure.get_option_filter(to_delete.id, decision)
    end
  end
end
