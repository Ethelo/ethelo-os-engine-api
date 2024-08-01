defmodule EtheloApi.Graphql.Schemas.OptionCategoryTest do
  @moduledoc """
  Test graphql queries for OptionCategories
  """
  use EtheloApi.Graphql.SchemaCase
  @moduletag option_category: true, graphql: true

  alias EtheloApi.Structure
  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.OptionCategoryHelper

  describe "decision => optionCategories query" do
    test "without filter returns all records" do
      %{option_category: to_match1, decision: decision} = create_option_category()
      %{option_category: to_match2} = create_option_category(decision)
      %{option_category: _excluded} = create_option_category()

      assert_list_many_query(
        "optionCategories",
        decision.id,
        %{},
        [to_match1, to_match2],
        fields()
      )
    end

    test "filters by id" do
      %{option_category: to_match, decision: decision} = create_option_category()
      %{option_category: _excluded} = create_option_category(decision)

      assert_list_one_query("optionCategories", to_match, [:id], fields([:id]))
    end

    test "filters by slug" do
      %{option_category: to_match, decision: decision} = create_option_category()
      %{option_category: _excluded} = create_option_category(decision)

      assert_list_one_query("optionCategories", to_match, [:slug], fields([:slug]))
    end

    test "no matching records" do
      decision = create_decision()
      assert_list_none_query("optionCategories", %{decision_id: decision.id}, [:id])
    end

    test "inline records" do
      %{option: option, decision: decision, option_category: option_category} = create_option()
      %{option_detail: option_detail} = create_option_detail(decision, :float)

      update_option_category(option_category, %{
        default_high_option_id: option.id,
        default_low_option_id: option.id,
        primary_detail_id: option_detail.id
      })

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            optionCategories{
              id
              options{
                id
              }
              defaultHighOption{
                id
              }
              defaultLowOption{
                id
              }
              primaryDetail{
                id
              }
            }
          }
        }
      """

      result_list = evaluate_query_graphql(query, "optionCategories")

      expected = [
        %{
          "id" => "#{option_category.id}",
          "options" => [
            %{"id" => "#{option.id}"}
          ],
          "defaultHighOption" => %{"id" => "#{option.id}"},
          "defaultLowOption" => %{"id" => "#{option.id}"},
          "primaryDetail" => %{"id" => "#{option_detail.id}"}
        }
      ]

      assert expected == result_list
    end
  end

  describe "createOptionCategory mutation" do
    test "creates with valid data" do
      %{decision: decision} = deps = option_category_with_detail_deps()

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names)
      requested_fields = Map.keys(attrs) ++ [:id]

      payload = run_mutate_one_query("createOptionCategory", decision.id, attrs, requested_fields)

      assert_mutation_success(attrs, payload, fields(field_names))
      refute nil == get_in(payload, ["result", "id"])
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = option_category_deps()
      invalid = Map.take(invalid_attrs(), [:title])

      field_names = [:slug, :title]

      attrs = deps |> valid_attrs() |> Map.merge(invalid) |> Map.take(field_names)

      payload = run_mutate_one_query("createOptionCategory", decision.id, attrs)

      expected = [%ValidationMessage{code: :required, field: :title}]
      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid Decision returns error" do
      %{decision: decision} = deps = option_category_deps()
      delete_decision(decision)

      field_names = [:title]
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("createOptionCategory", decision.id, attrs)

      expected = [%ValidationMessage{code: :not_found, field: "decisionId"}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "updateOptionCategory mutation" do
    test "updates with valid data" do
      %{decision: decision} = deps = create_option_category_with_detail()

      field_names = input_field_names() ++ [:id]
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("updateOptionCategory", decision.id, attrs)

      assert_mutation_success(attrs, payload, fields(field_names))
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = create_option_category()
      invalid = Map.take(invalid_attrs(), [:title])

      field_names = [:title, :slug, :id]

      attrs = deps |> valid_attrs() |> Map.merge(invalid) |> Map.take(field_names)

      payload = run_mutate_one_query("updateOptionCategory", decision.id, attrs)

      expected = [%ValidationMessage{code: :required, field: :title}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid OptionCategory returns error" do
      %{option_category: to_delete, decision: decision} = deps = create_option_category()
      delete_option_category(to_delete)

      field_names = [:id, :title]
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("updateOptionCategory", decision.id, attrs)

      expected = [%ValidationMessage{code: "not_found", field: :id}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "deleteOptionCategory mutation" do
    test "deletes when is not default" do
      %{decision: decision, option_category: to_delete} = create_option_category()

      attrs = to_delete |> Map.take([:id])
      payload = run_mutate_one_query("deleteOptionCategory", decision.id, attrs)

      assert_mutation_success(%{}, payload, %{})
      assert nil == Structure.get_option_category(to_delete.id, decision)
    end

    test "cannot delete default OptionCategory" do
      decision = create_decision()

      default_category =
        EtheloApi.Structure.Queries.OptionCategory.ensure_default_option_category(decision)

      attrs = default_category |> Map.take([:id])
      payload = run_mutate_one_query("deleteOptionCategory", decision.id, attrs)

      expected = [%ValidationMessage{code: :protected_record, field: :id}]

      assert_mutation_failure(expected, payload, [:field, :code])
      refute nil == Structure.get_option_category(default_category.id, decision)
    end
  end
end
